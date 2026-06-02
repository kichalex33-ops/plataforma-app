import 'package:flutter_test/flutter_test.dart';
import 'package:logisaude_driver/core/logistica/logistica_enums.dart';
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
    for (final table in [
      'logistica_sync_items',
      'logistica_ocorrencias',
      'logistica_abastecimentos',
      'logistica_comprovantes',
      'logistica_passageiros_viagem',
      'logistica_pacientes',
      'logistica_viagens',
      'logistica_veiculos',
      'logistica_motoristas',
    ]) {
      await db.delete(table);
    }

    final now = DateTime(2026, 6, 2).toIso8601String();
    await db.insert('logistica_veiculos', _base('vei-test', now, {
      'placa': 'TST1A23',
      'modelo': 'Van Teste',
      'tipo': 'van',
      'capacidade': 4,
    }));
    await db.insert('logistica_motoristas', _base('mot-test', now, {
      'nome': 'Motorista Teste',
    }));
    await db.insert('logistica_pacientes', _base('pac-test', now, {
      'nome': 'Paciente Teste',
      'endereco_embarque': 'Rua Teste',
      'acessibilidade': TipoAcessibilidade.nenhuma.dbValue,
    }));
    await db.insert('logistica_viagens', _base('via-test', now, {
      'origem': 'Origem',
      'destino_principal': 'Destino',
      'data_consulta': now,
      'motorista_id_local': 'mot-test',
      'veiculo_id_local': 'vei-test',
      'status': StatusViagem.aguardando.dbValue,
      'prioridade': 'normal',
      'km_inicial': 100.0,
    }));
    await db.insert('logistica_passageiros_viagem', _base('pas-test', now, {
      'viagem_id_local': 'via-test',
      'paciente_id_local': 'pac-test',
      'status_ida': StatusPacienteIda.aguardando.dbValue,
      'status_volta': StatusPacienteVolta.aguardando.dbValue,
    }));
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
      fila.map((item) => item['tipo_evento']).contains(TipoEventoSync.pacienteAusente.dbValue),
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
      fila.map((item) => item['tipo_evento']).contains(TipoEventoSync.panicoAcionado.dbValue),
      isTrue,
    );
  });
}

Map<String, Object?> _base(
  String id,
  String now,
  Map<String, Object?> values,
) {
  return {
    'id_local': id,
    'id_servidor': null,
    'created_at': now,
    'updated_at': now,
    'status_sync': StatusSync.local.dbValue,
    ...values,
  };
}
