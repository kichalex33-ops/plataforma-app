import 'package:flutter_test/flutter_test.dart';
import 'package:logisaude_driver/core/logistica/logistica_demo_config.dart';
import 'package:logisaude_driver/core/logistica/logistica_enums.dart';
import 'package:logisaude_driver/core/logistica/logistica_mock_seed.dart';
import 'package:logisaude_driver/core/logistica/logistica_validators.dart';
import 'package:logisaude_driver/database/database_helper.dart';
import 'package:logisaude_driver/motorista/operacional/logistica_operacional_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late LogisticaOperacionalRepository repository;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    repository = LogisticaOperacionalRepository();
    final db = await DatabaseHelper.instance.database;
    await _limparLogistica(db);

    final now = DateTime(2026, 6, 2).toIso8601String();
    await db.insert(
      'logistica_veiculos',
      _base('vei-test', now, {
        'placa': 'TST1A23',
        'modelo': 'Van Teste',
        'tipo': 'van',
        'capacidade': 4,
      }),
    );
    await db.insert(
      'logistica_motoristas',
      _base('mot-test', now, {'nome': 'Motorista Teste'}),
    );
    await db.insert(
      'logistica_pacientes',
      _base('pac-test', now, {
        'nome': 'Paciente Teste',
        'endereco_embarque': 'Rua Teste',
        'acessibilidade': TipoAcessibilidade.nenhuma.dbValue,
      }),
    );
    await db.insert(
      'logistica_viagens',
      _base('via-test', now, {
        'origem': 'Origem',
        'destino_principal': 'Destino',
        'data_consulta': now,
        'motorista_id_local': 'mot-test',
        'veiculo_id_local': 'vei-test',
        'status': StatusViagem.aguardando.dbValue,
        'prioridade': 'normal',
        'km_inicial': 100.0,
      }),
    );
    await db.insert(
      'logistica_passageiros_viagem',
      _base('pas-test', now, {
        'viagem_id_local': 'via-test',
        'paciente_id_local': 'pac-test',
        'status_ida': StatusPacienteIda.aguardando.dbValue,
        'status_volta': StatusPacienteVolta.aguardando.dbValue,
      }),
    );
  });

  test('iniciar viagem sem KM deve falhar', () {
    expect(
      () => repository.confirmarSaida(
        viagemId: 'via-test',
        kmSaida: null,
        checklistConcluido: true,
      ),
      throwsA(isA<LogisticaValidationException>()),
    );
  });

  test('iniciar viagem sem checklist deve falhar', () {
    expect(
      () => repository.confirmarSaida(
        viagemId: 'via-test',
        kmSaida: 100,
        checklistConcluido: false,
      ),
      throwsA(isA<LogisticaValidationException>()),
    );
  });

  test('concluir com KM final menor deve falhar', () {
    expect(
      () => repository.concluirViagem(viagemId: 'via-test', kmFinal: 90),
      throwsA(isA<LogisticaValidationException>()),
    );
  });

  test('concluir sem checklist pos-uso deve falhar', () {
    expect(
      () => repository.concluirViagem(viagemId: 'via-test', kmFinal: 130),
      throwsA(isA<LogisticaValidationException>()),
    );
  });

  test('iniciar retorno sem pacientes marcados deve falhar', () {
    expect(
      () => repository.iniciarRetorno('via-test'),
      throwsA(isA<LogisticaValidationException>()),
    );
  });

  test('paciente ausente gera ocorrencia e fila', () async {
    await repository.marcarPaciente(
      viagemId: 'via-test',
      passageiroId: 'pas-test',
      status: StatusPacienteIda.ausente,
    );

    final db = await DatabaseHelper.instance.database;
    final ocorrencias = await db.query('logistica_ocorrencias');
    final fila = await db.query('logistica_sync_items');

    expect(ocorrencias, hasLength(1));
    expect(
      fila
          .map((item) => item['tipo_evento'])
          .contains(TipoEventoSync.pacienteAusente.dbValue),
      isTrue,
    );
  });

  test('panico gera ocorrencia e fila', () async {
    await repository.acionarPanico('via-test');

    final db = await DatabaseHelper.instance.database;
    final ocorrencias = await db.query('logistica_ocorrencias');
    final fila = await db.query('logistica_sync_items');

    expect(ocorrencias.first['tipo'], TipoOcorrencia.panico.dbValue);
    expect(
      fila
          .map((item) => item['tipo_evento'])
          .contains(TipoEventoSync.panicoAcionado.dbValue),
      isTrue,
    );
  });

  test('checklist pos-uso permite encerrar viagem valida', () async {
    await repository.registrarChecklist(
      viagemId: 'via-test',
      tipo: 'pos_uso',
      itens: {'limpeza': true, 'danos_observados': false},
      observacao: 'Sem avarias.',
    );

    await repository.concluirViagem(viagemId: 'via-test', kmFinal: 130);

    final db = await DatabaseHelper.instance.database;
    final viagem = await db.query(
      'logistica_viagens',
      where: 'id_local = ?',
      whereArgs: ['via-test'],
      limit: 1,
    );
    expect(viagem.first['status'], StatusViagem.concluida.dbValue);
  });

  test('abastecimento calcula valor por litro e gera fila', () async {
    final result = await repository.registrarAbastecimento(
      viagemId: 'via-test',
      posto: 'Posto Central',
      litros: 40,
      valorTotal: 240,
      fotoCupomPath: 'cupom.jpg',
      observacao: 'Tanque completo.',
    );

    final db = await DatabaseHelper.instance.database;
    final abastecimentos = await db.query('logistica_abastecimentos');
    final fila = await db.query('logistica_sync_items');

    expect(result.valorPorLitro, 6);
    expect(abastecimentos, hasLength(1));
    expect(abastecimentos.first['tipo'], 'abastecimento');
    expect(
      fila
          .map((item) => item['tipo_evento'])
          .contains(TipoEventoSync.abastecimentoRegistrado.dbValue),
      isTrue,
    );
  });

  test(
    'despesa geral fica vinculada a viagem e entra no custo por paciente',
    () async {
      await repository.registrarDespesaGeral(
        viagemId: 'via-test',
        tipo: 'pedágio',
        valor: 30,
        descricao: 'Pedágio autorizado.',
        comprovantePath: 'pedagio.jpg',
      );

      final snapshot = await repository.carregarSnapshot('via-test');
      expect(snapshot.totalDespesas, 30);
      expect(snapshot.custoPorPaciente, 30);
    },
  );

  test('comprovante SUS permite multiplas fotos por paciente', () async {
    await repository.capturarComprovante(
      'via-test',
      'pas-test',
      fotoPath: 'sus-1.jpg',
    );
    await repository.capturarComprovante(
      'via-test',
      'pas-test',
      fotoPath: 'sus-2.jpg',
    );

    final db = await DatabaseHelper.instance.database;
    final comprovantes = await db.query('logistica_comprovantes');
    expect(comprovantes, hasLength(2));
  });

  test(
    'seed de homologacao fica desligado e nao cria viagens falsas',
    () async {
      final db = await DatabaseHelper.instance.database;
      await _limparLogistica(db);

      expect(LogisticaDemoConfig.demoSeedEnabled, isFalse);
      expect(await db.query('logistica_viagens'), isEmpty);
      expect(await repository.listarViagensDoDia(), isEmpty);
    },
  );

  test('seed de homologacao cria viagens e permite confirmar saida', () async {
    final db = await DatabaseHelper.instance.database;
    await _limparLogistica(db);
    await LogisticaMockSeed(db).seedIfEmpty();

    final viagens = await db.query('logistica_viagens');
    expect(viagens, hasLength(3));

    for (final viagem in viagens) {
      final passageiros = await db.query(
        'logistica_passageiros_viagem',
        where: 'viagem_id_local = ?',
        whereArgs: [viagem['id_local']],
      );
      expect(passageiros, isNotEmpty);
    }

    final pacientesComAcessibilidade = await db.query(
      'logistica_pacientes',
      where: 'acessibilidade != ?',
      whereArgs: [TipoAcessibilidade.nenhuma.dbValue],
    );
    expect(pacientesComAcessibilidade, isNotEmpty);

    final snapshots = await repository.listarViagensDoDia();
    expect(snapshots, hasLength(3));
    expect(snapshots.every((item) => item.totalPacientes > 0), isTrue);
    expect(snapshots.any((item) => item.totalAcessibilidade > 0), isTrue);

    await repository.iniciarPreparacao('via-001');
    await repository.confirmarSaida(
      viagemId: 'via-001',
      kmSaida: 48211,
      checklistConcluido: true,
    );

    final viagemAtualizada = await db.query(
      'logistica_viagens',
      where: 'id_local = ?',
      whereArgs: ['via-001'],
      limit: 1,
    );
    expect(
      viagemAtualizada.first['status'],
      StatusViagem.emTransitoIda.dbValue,
    );
    expect(viagemAtualizada.first['km_inicial'], 48211);
  });
}

Future<void> _limparLogistica(Database db) async {
  for (final table in [
    'logistica_sync_items',
    'logistica_ocorrencias',
    'logistica_abastecimentos',
    'logistica_avisos_central',
    'logistica_checklists',
    'logistica_comprovantes',
    'logistica_passageiros_viagem',
    'logistica_pacientes',
    'logistica_viagens',
    'logistica_veiculos',
    'logistica_motoristas',
  ]) {
    await db.delete(table);
  }
}

Map<String, Object?> _base(String id, String now, Map<String, Object?> values) {
  return {
    'id_local': id,
    'id_servidor': null,
    'created_at': now,
    'updated_at': now,
    'status_sync': StatusSync.local.dbValue,
    ...values,
  };
}
