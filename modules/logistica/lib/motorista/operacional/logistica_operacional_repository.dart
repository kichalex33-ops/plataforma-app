import '../../core/logistica/logistica_enums.dart';
import '../../core/logistica/logistica_offline_queue.dart';
import '../../core/logistica/logistica_validators.dart';
import '../../database/database_helper.dart';

class LogisticaTripSnapshot {
  final Map<String, Object?> viagem;
  final List<Map<String, Object?>> passageiros;
  final List<Map<String, Object?>> pacientes;
  final List<Map<String, Object?>> despesas;
  final List<Map<String, Object?>> ocorrencias;

  const LogisticaTripSnapshot({
    required this.viagem,
    required this.passageiros,
    required this.pacientes,
    required this.despesas,
    required this.ocorrencias,
  });

  String get viagemId => viagem['id_local']?.toString() ?? '';
  double? get kmInicial => (viagem['km_inicial'] as num?)?.toDouble();
  String get status => viagem['status']?.toString() ?? StatusViagem.aguardando.dbValue;
  int get totalPacientes => passageiros.length;
  int get totalAcessibilidade => pacientes
      .where((item) => (item['acessibilidade']?.toString() ?? 'nenhuma') != 'nenhuma')
      .length;
  int get transportados => passageiros
      .where((item) => item['status_ida']?.toString() == StatusPacienteIda.embarcado.dbValue)
      .length;
  int get ausentesDesistentes => passageiros
      .where((item) =>
          item['status_ida']?.toString() == StatusPacienteIda.ausente.dbValue ||
          item['status_ida']?.toString() == StatusPacienteIda.desistiu.dbValue)
      .length;
  double get totalDespesas => despesas.fold(
        0,
        (total, item) => total + ((item['valor'] as num?)?.toDouble() ?? 0),
      );
}

class LogisticaOperacionalRepository {
  final DatabaseHelper databaseHelper;
  final LogisticaOfflineQueue queue;

  LogisticaOperacionalRepository({
    DatabaseHelper? databaseHelper,
    LogisticaOfflineQueue? queue,
  })  : databaseHelper = databaseHelper ?? DatabaseHelper.instance,
        queue = queue ?? const LogisticaOfflineQueue();

  Future<List<LogisticaTripSnapshot>> listarViagensDoDia() async {
    final db = await databaseHelper.database;
    final viagens = await db.query('logistica_viagens', orderBy: 'data_consulta ASC');
    final snapshots = <LogisticaTripSnapshot>[];
    for (final viagem in viagens) {
      snapshots.add(await carregarSnapshot(viagem['id_local']!.toString()));
    }
    return snapshots;
  }

  Future<LogisticaTripSnapshot> carregarSnapshot(String viagemId) async {
    final db = await databaseHelper.database;
    final viagens = await db.query(
      'logistica_viagens',
      where: 'id_local = ?',
      whereArgs: [viagemId],
      limit: 1,
    );
    if (viagens.isEmpty) {
      throw StateError('Viagem nao encontrada.');
    }
    final passageiros = await db.query(
      'logistica_passageiros_viagem',
      where: 'viagem_id_local = ?',
      whereArgs: [viagemId],
      orderBy: 'id_local ASC',
    );
    final pacientes = <Map<String, Object?>>[];
    for (final passageiro in passageiros) {
      final result = await db.query(
        'logistica_pacientes',
        where: 'id_local = ?',
        whereArgs: [passageiro['paciente_id_local']],
        limit: 1,
      );
      if (result.isNotEmpty) pacientes.add(result.first);
    }
    final despesas = await db.query(
      'logistica_abastecimentos',
      where: 'viagem_id_local = ?',
      whereArgs: [viagemId],
    );
    final ocorrencias = await db.query(
      'logistica_ocorrencias',
      where: 'viagem_id_local = ?',
      whereArgs: [viagemId],
    );
    return LogisticaTripSnapshot(
      viagem: viagens.first,
      passageiros: passageiros,
      pacientes: pacientes,
      despesas: despesas,
      ocorrencias: ocorrencias,
    );
  }

  Future<void> iniciarPreparacao(String viagemId) async {
    await _updateViagem(viagemId, {'status': StatusViagem.preparacao.dbValue});
  }

  Future<void> confirmarSaida({
    required String viagemId,
    required double? kmSaida,
    required bool checklistConcluido,
  }) async {
    LogisticaValidators.validarInicioViagem(
      kmSaida: kmSaida,
      checklistPreUsoConcluido: checklistConcluido,
    );
    final now = DateTime.now().toIso8601String();
    await _updateViagem(viagemId, {
      'status': StatusViagem.emTransitoIda.dbValue,
      'km_inicial': kmSaida,
      'saida_em': now,
    });
    await _enqueue(
      TipoEventoSync.viagemIniciada,
      {'viagem_id': viagemId, 'km_saida': kmSaida, 'saida_em': now},
    );
  }

  Future<void> marcarPaciente({
    required String viagemId,
    required String passageiroId,
    required StatusPacienteIda status,
  }) async {
    final db = await databaseHelper.database;
    await db.update(
      'logistica_passageiros_viagem',
      {
        'status_ida': status.dbValue,
        'updated_at': DateTime.now().toIso8601String(),
        'status_sync': StatusSync.pendente.dbValue,
      },
      where: 'id_local = ?',
      whereArgs: [passageiroId],
    );
    final tipo = switch (status) {
      StatusPacienteIda.desembarcado => TipoEventoSync.pacienteDesembarcado,
      StatusPacienteIda.ausente => TipoEventoSync.pacienteAusente,
      StatusPacienteIda.desistiu => TipoEventoSync.pacienteDesistiu,
      _ => TipoEventoSync.pacienteDesembarcado,
    };
    await _enqueue(tipo, {
      'viagem_id': viagemId,
      'passageiro_id': passageiroId,
      'status': status.dbValue,
    });
    if (status == StatusPacienteIda.ausente || status == StatusPacienteIda.desistiu) {
      await registrarOcorrencia(
        viagemId: viagemId,
        tipo: status == StatusPacienteIda.ausente
            ? TipoOcorrencia.pacienteAusente
            : TipoOcorrencia.desistencia,
        descricao: status == StatusPacienteIda.ausente
            ? 'Paciente ausente no embarque/desembarque.'
            : 'Paciente desistiu da viagem.',
        pacienteId: passageiroId,
      );
    }
  }

  Future<void> iniciarEspera(String viagemId) async {
    await _updateViagem(viagemId, {
      'status': StatusViagem.emEspera.dbValue,
      'inicio_espera': DateTime.now().toIso8601String(),
    });
  }

  Future<void> registrarDespesaMock(String viagemId) async {
    final db = await databaseHelper.database;
    final now = DateTime.now().toIso8601String();
    await db.insert('logistica_abastecimentos', {
      'id_local': 'desp-${DateTime.now().millisecondsSinceEpoch}',
      'id_servidor': null,
      'viagem_id_local': viagemId,
      'veiculo_id_local': 'vei-001',
      'motorista_id_local': 'mot-001',
      'local': 'Despesa local',
      'tipo': 'despesa',
      'litros': 1.0,
      'valor': 25.0,
      'created_at': now,
      'updated_at': now,
      'status_sync': StatusSync.pendente.dbValue,
    });
    await _enqueue(TipoEventoSync.abastecimentoRegistrado, {
      'viagem_id': viagemId,
      'valor': 25.0,
    });
  }

  Future<void> marcarRetorno({
    required String passageiroId,
    required StatusPacienteVolta status,
  }) async {
    final db = await databaseHelper.database;
    await db.update(
      'logistica_passageiros_viagem',
      {
        'status_volta': status.dbValue,
        'justificativa_retorno': status == StatusPacienteVolta.justificado ||
                status == StatusPacienteVolta.naoRetornou
            ? 'Justificado no app'
            : null,
        'updated_at': DateTime.now().toIso8601String(),
        'status_sync': StatusSync.pendente.dbValue,
      },
      where: 'id_local = ?',
      whereArgs: [passageiroId],
    );
  }

  Future<void> iniciarRetorno(String viagemId) async {
    final snapshot = await carregarSnapshot(viagemId);
    final pendentes = snapshot.passageiros.where((item) {
      final status = item['status_volta']?.toString();
      return status != StatusPacienteVolta.embarcado.dbValue &&
          status != StatusPacienteVolta.justificado.dbValue &&
          status != StatusPacienteVolta.naoRetornou.dbValue;
    }).toList();
    if (pendentes.isNotEmpty) {
      throw const LogisticaValidationException(
        'Todos os pacientes devem estar embarcados ou justificados.',
      );
    }
    await _updateViagem(viagemId, {
      'status': StatusViagem.emTransitoVolta.dbValue,
      'fim_espera': DateTime.now().toIso8601String(),
    });
    await _enqueue(TipoEventoSync.retornoIniciado, {'viagem_id': viagemId});
  }

  Future<void> concluirDesembarqueVolta({
    required String passageiroId,
  }) async {
    await marcarRetorno(
      passageiroId: passageiroId,
      status: StatusPacienteVolta.desembarcado,
    );
  }

  Future<void> concluirViagem({
    required String viagemId,
    required double? kmFinal,
    double? kmEsperado,
  }) async {
    LogisticaValidators.validarConclusaoViagem(kmFinal: kmFinal);
    final snapshot = await carregarSnapshot(viagemId);
    final kmInicial = snapshot.kmInicial ?? 0;
    final result = LogisticaValidators.validarKmFinal(
      kmInicial: kmInicial,
      kmFinal: kmFinal!,
      kmEsperado: kmEsperado,
    );
    final status = result.pendenteRevisao
        ? StatusViagem.pendenteRevisao
        : StatusViagem.concluida;
    await _updateViagem(viagemId, {
      'status': status.dbValue,
      'km_final': kmFinal,
      'finalizada_em': DateTime.now().toIso8601String(),
    });
    await _enqueue(TipoEventoSync.viagemConcluida, {
      'viagem_id': viagemId,
      'km_final': kmFinal,
      'pendente_revisao': result.pendenteRevisao,
    });
  }

  Future<void> acionarPanico(String viagemId) async {
    await registrarOcorrencia(
      viagemId: viagemId,
      tipo: TipoOcorrencia.panico,
      descricao: 'PANICO acionado pelo motorista.',
    );
    await _enqueue(TipoEventoSync.panicoAcionado, {
      'viagem_id': viagemId,
      'mensagem': 'Central sera notificada quando houver conexao',
    });
  }

  Future<void> capturarComprovante(String viagemId, String passageiroId) async {
    final db = await databaseHelper.database;
    final now = DateTime.now().toIso8601String();
    await db.insert('logistica_comprovantes', {
      'id_local': 'cmp-${DateTime.now().millisecondsSinceEpoch}',
      'id_servidor': null,
      'viagem_id_local': viagemId,
      'passageiro_id_local': passageiroId,
      'paciente_id_local': passageiroId,
      'tipo': 'presenca',
      'foto_path': 'mock/comprovante.jpg',
      'created_at': now,
      'updated_at': now,
      'status_sync': StatusSync.pendente.dbValue,
    });
    await _enqueue(TipoEventoSync.comprovanteCapturado, {
      'viagem_id': viagemId,
      'passageiro_id': passageiroId,
    });
  }

  Future<void> registrarOcorrencia({
    required String viagemId,
    required TipoOcorrencia tipo,
    required String descricao,
    String? pacienteId,
  }) async {
    LogisticaValidators.validarOcorrencia(tipo: tipo, dataHora: DateTime.now());
    final db = await databaseHelper.database;
    final now = DateTime.now().toIso8601String();
    await db.insert('logistica_ocorrencias', {
      'id_local': 'oco-${DateTime.now().microsecondsSinceEpoch}',
      'id_servidor': null,
      'viagem_id_local': viagemId,
      'motorista_id_local': 'mot-001',
      'paciente_id_local': pacienteId,
      'tipo': tipo.dbValue,
      'descricao': descricao,
      'data_hora': now,
      'created_at': now,
      'updated_at': now,
      'status_sync': StatusSync.pendente.dbValue,
    });
    await _enqueue(TipoEventoSync.ocorrenciaRegistrada, {
      'viagem_id': viagemId,
      'tipo': tipo.dbValue,
      'descricao': descricao,
    });
  }

  Future<void> _updateViagem(String viagemId, Map<String, Object?> data) async {
    final db = await databaseHelper.database;
    await db.update(
      'logistica_viagens',
      {
        ...data,
        'updated_at': DateTime.now().toIso8601String(),
        'status_sync': StatusSync.pendente.dbValue,
      },
      where: 'id_local = ?',
      whereArgs: [viagemId],
    );
  }

  Future<void> _enqueue(TipoEventoSync tipo, Map<String, dynamic> payload) async {
    final db = await databaseHelper.database;
    final item = queue.criarItem(tipoEvento: tipo, payload: payload);
    await db.insert('logistica_sync_items', item.toMap());
  }
}

String pacienteNome(
  LogisticaTripSnapshot snapshot,
  Map<String, Object?> passageiro,
) {
  final pacienteId = passageiro['paciente_id_local']?.toString();
  final paciente = snapshot.pacientes.firstWhere(
    (item) => item['id_local']?.toString() == pacienteId,
    orElse: () => const {},
  );
  return paciente['nome']?.toString() ?? 'Paciente';
}

String pacienteAcessibilidade(
  LogisticaTripSnapshot snapshot,
  Map<String, Object?> passageiro,
) {
  final pacienteId = passageiro['paciente_id_local']?.toString();
  final paciente = snapshot.pacientes.firstWhere(
    (item) => item['id_local']?.toString() == pacienteId,
    orElse: () => const {},
  );
  return paciente['acessibilidade']?.toString() ?? 'nenhuma';
}
