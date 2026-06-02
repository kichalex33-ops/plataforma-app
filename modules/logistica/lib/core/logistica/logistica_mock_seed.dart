import 'package:sqflite/sqflite.dart';

import 'logistica_enums.dart';

class LogisticaMockSeed {
  final Database db;

  const LogisticaMockSeed(this.db);

  Future<void> seedIfEmpty() async {
    final count = await db.rawQuery(
      'SELECT COUNT(*) AS total FROM logistica_viagens',
    );
    final total = count.first['total'] as int? ?? 0;
    if (total > 0) return;

    final now = DateTime.now();
    final createdAt = now.toIso8601String();
    final updatedAt = createdAt;

    final veiculos = [
      {
        'id_local': 'vei-001',
        'placa': 'ABC1D23',
        'modelo': 'Fiat Ducato',
        'tipo': 'van sanitária',
        'capacidade': 12,
        'km_atual': 48210.0,
      },
      {
        'id_local': 'vei-002',
        'placa': 'SAU2D45',
        'modelo': 'Renault Master',
        'tipo': 'ambulância simples',
        'capacidade': 6,
        'km_atual': 73150.0,
      },
    ];

    final motoristas = [
      {
        'id_local': 'mot-001',
        'nome': 'Alex Kich',
        'cpf': '00000000000',
        'telefone': '(00) 99999-0001',
        'cnh': 'AB',
      },
      {
        'id_local': 'mot-002',
        'nome': 'João Silva',
        'cpf': '11111111111',
        'telefone': '(00) 99999-0002',
        'cnh': 'D',
      },
    ];

    final pacientes = [
      ['pac-001', 'Maria Oliveira', 'Rua A, 100', TipoAcessibilidade.cadeirante],
      ['pac-002', 'José Santos', 'Rua B, 45', TipoAcessibilidade.nenhuma],
      ['pac-003', 'Ana Costa', 'Rua C, 78', TipoAcessibilidade.muletas],
      ['pac-004', 'Paulo Lima', 'Rua D, 12', TipoAcessibilidade.nenhuma],
      ['pac-005', 'Clara Souza', 'Rua E, 88', TipoAcessibilidade.mobilidadeReduzida],
      ['pac-006', 'Pedro Alves', 'Rua F, 34', TipoAcessibilidade.acompanhanteObrigatorio],
      ['pac-007', 'Helena Rocha', 'Rua G, 56', TipoAcessibilidade.nenhuma],
      ['pac-008', 'Rafael Dias', 'Rua H, 91', TipoAcessibilidade.maca],
    ];

    final viagens = [
      {
        'id_local': 'via-001',
        'origem': 'Garagem municipal',
        'destino_principal': 'Hospital Regional',
        'unidade_destino': 'Hospital Regional',
        'data_consulta': now.add(const Duration(hours: 2)).toIso8601String(),
        'horario_consulta': '10:30',
        'motorista_id_local': 'mot-001',
        'veiculo_id_local': 'vei-001',
        'status': StatusViagem.aguardando.dbValue,
        'prioridade': 'alta',
        'observacoes_central': 'Paciente cadeirante na primeira parada.',
        'km_inicial': 48210.0,
      },
      {
        'id_local': 'via-002',
        'origem': 'UBS Centro',
        'destino_principal': 'Clínica de Imagem',
        'unidade_destino': 'Clínica de Imagem',
        'data_consulta': now.add(const Duration(hours: 5)).toIso8601String(),
        'horario_consulta': '14:00',
        'motorista_id_local': 'mot-002',
        'veiculo_id_local': 'vei-002',
        'status': StatusViagem.emEspera.dbValue,
        'prioridade': 'normal',
        'observacoes_central': 'Retorno previsto após exames.',
        'km_inicial': 73150.0,
      },
      {
        'id_local': 'via-003',
        'origem': 'Distrito Norte',
        'destino_principal': 'Hospital Estadual',
        'unidade_destino': 'Hospital Estadual',
        'data_consulta': now.add(const Duration(days: 1)).toIso8601String(),
        'horario_consulta': '08:00',
        'motorista_id_local': 'mot-001',
        'veiculo_id_local': 'vei-001',
        'status': StatusViagem.aguardando.dbValue,
        'prioridade': 'transferencia',
        'observacoes_central': 'Transferência com maca.',
      },
    ];

    await db.transaction((txn) async {
      for (final item in veiculos) {
        await _insert(txn, 'logistica_veiculos', item, createdAt, updatedAt);
      }
      for (final item in motoristas) {
        await _insert(txn, 'logistica_motoristas', item, createdAt, updatedAt);
      }
      for (final paciente in pacientes) {
        await _insert(
          txn,
          'logistica_pacientes',
          {
            'id_local': paciente[0],
            'nome': paciente[1],
            'telefone': '(00) 98888-0000',
            'endereco_embarque': paciente[2],
            'acessibilidade': (paciente[3] as TipoAcessibilidade).dbValue,
            'observacoes': 'Mock local para demonstração.',
          },
          createdAt,
          updatedAt,
        );
      }
      for (final item in viagens) {
        await _insert(txn, 'logistica_viagens', item, createdAt, updatedAt);
      }

      final passageiros = [
        ['pas-001', 'via-001', 'pac-001', 0, StatusPacienteIda.aguardando],
        ['pas-002', 'via-001', 'pac-002', 1, StatusPacienteIda.aguardando],
        ['pas-003', 'via-001', 'pac-003', 0, StatusPacienteIda.ausente],
        ['pas-004', 'via-002', 'pac-004', 0, StatusPacienteIda.embarcado],
        ['pas-005', 'via-002', 'pac-005', 1, StatusPacienteIda.embarcado],
        ['pas-006', 'via-002', 'pac-006', 1, StatusPacienteIda.embarcado],
        ['pas-007', 'via-003', 'pac-007', 0, StatusPacienteIda.aguardando],
        ['pas-008', 'via-003', 'pac-008', 0, StatusPacienteIda.aguardando],
      ];
      for (final item in passageiros) {
        await _insert(
          txn,
          'logistica_passageiros_viagem',
          {
            'id_local': item[0],
            'viagem_id_local': item[1],
            'paciente_id_local': item[2],
            'acompanhante': item[3],
            'status_ida': (item[4] as StatusPacienteIda).dbValue,
            'status_volta': StatusPacienteVolta.aguardando.dbValue,
          },
          createdAt,
          updatedAt,
        );
      }

      await _insert(
        txn,
        'logistica_abastecimentos',
        {
          'id_local': 'aba-001',
          'viagem_id_local': 'via-002',
          'veiculo_id_local': 'vei-002',
          'motorista_id_local': 'mot-002',
          'local': 'Posto Central',
          'tipo': 'abastecimento',
          'litros': 42.5,
          'valor': 246.50,
          'observacao': 'Abastecimento em espera.',
        },
        createdAt,
        updatedAt,
      );

      await _insert(
        txn,
        'logistica_ocorrencias',
        {
          'id_local': 'oco-001',
          'viagem_id_local': 'via-001',
          'motorista_id_local': 'mot-001',
          'paciente_id_local': 'pac-003',
          'tipo': TipoOcorrencia.pacienteAusente.dbValue,
          'descricao': 'Paciente não localizado no endereço de embarque.',
          'data_hora': createdAt,
        },
        createdAt,
        updatedAt,
      );

      await _insert(
        txn,
        'logistica_avisos_central',
        {
          'id_local': 'avi-001',
          'titulo': 'Rota prioritária',
          'mensagem': 'Confirmar embarque da paciente cadeirante primeiro.',
          'prioridade': 'alta',
          'data_hora': createdAt,
          'lido': 0,
        },
        createdAt,
        updatedAt,
      );
    });
  }

  Future<void> _insert(
    Transaction txn,
    String table,
    Map<String, Object?> values,
    String createdAt,
    String updatedAt,
  ) async {
    await txn.insert(table, {
      'id_servidor': null,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'status_sync': StatusSync.local.dbValue,
      ...values,
    });
  }
}
