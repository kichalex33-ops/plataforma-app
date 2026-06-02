import 'dart:convert';

import '../../core/logistica/logistica_calculator.dart';
import '../../core/logistica/logistica_enums.dart';
import '../../core/logistica/logistica_offline_queue.dart';
import '../../core/logistica/logistica_validators.dart';
import '../../database/database_helper.dart';

class LogisticaAbastecimentoResult {
  final double valorPorLitro;
  final double custoPorKm;

  const LogisticaAbastecimentoResult({
    required this.valorPorLitro,
    required this.custoPorKm,
  });
}

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
  String get status =>
      viagem['status']?.toString() ?? StatusViagem.aguardando.dbValue;
  int get totalPacientes => passageiros.length;
  int get totalAcessibilidade => pacientes
      .where(
        (item) =>
            (item['acessibilidade']?.toString() ?? 'nenhuma') != 'nenhuma',
      )
      .length;
  int get transportados => passageiros
      .where(
        (item) =>
            item['status_ida']?.toString() ==
            StatusPacienteIda.embarcado.dbValue,
      )
      .length;
  int get ausentesDesistentes => passageiros
      .where(
        (item) =>
            item['status_ida']?.toString() ==
                StatusPacienteIda.ausente.dbValue ||
            item['status_ida']?.toString() ==
                StatusPacienteIda.desistiu.dbValue,
      )
      .length;
  double get totalDespesas => despesas.fold(
    0,
    (total, item) => total + ((item['valor'] as num?)?.toDouble() ?? 0),
  );
  double get kmRodado {
    final kmFinal = (viagem['km_final'] as num?)?.toDouble();
    final inicial = kmInicial;
    if (inicial == null || kmFinal == null) return 0;
    return LogisticaCalculator.kmRodado(kmInicial: inicial, kmFinal: kmFinal);
  }

  double get custoPorKm => LogisticaCalculator.custoPorKm(
    totalDespesas: totalDespesas,
    kmRodado: kmRodado,
  );

  double get custoPorPaciente => LogisticaCalculator.custoPorPaciente(
    totalDespesas: totalDespesas,
    pacientesTransportados: totalPacientes,
  );
}

class LogisticaOperacionalRepository {
  final DatabaseHelper databaseHelper;
  final LogisticaOfflineQueue queue;

  LogisticaOperacionalRepository({
    DatabaseHelper? databaseHelper,
    LogisticaOfflineQueue? queue,
  }) : databaseHelper = databaseHelper ?? DatabaseHelper.instance,
       queue = queue ?? const LogisticaOfflineQueue();

  Future<List<LogisticaTripSnapshot>> listarViagensDoDia() async {
    final db = await databaseHelper.database;
    final viagens = await db.query(
      'logistica_viagens',
      orderBy: 'data_consulta ASC',
    );
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
    final possuiChecklistPreUso =
        checklistConcluido || await _checklistConcluido(viagemId, 'pre_uso');
    LogisticaValidators.validarInicioViagem(
      kmSaida: kmSaida,
      checklistPreUsoConcluido: possuiChecklistPreUso,
    );
    final now = DateTime.now().toIso8601String();
    await _updateViagem(viagemId, {
      'status': StatusViagem.emTransitoIda.dbValue,
      'km_inicial': kmSaida,
      'saida_em': now,
    });
    await _enqueue(TipoEventoSync.viagemIniciada, {
      'viagem_id': viagemId,
      'km_saida': kmSaida,
      'saida_em': now,
    });
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
        if (status == StatusPacienteIda.ausente ||
            status == StatusPacienteIda.desistiu)
          'status_volta': StatusPacienteVolta.naoRetornou.dbValue,
        if (status == StatusPacienteIda.ausente ||
            status == StatusPacienteIda.desistiu)
          'justificativa_retorno': status == StatusPacienteIda.ausente
              ? 'Paciente ausente na ida'
              : 'Paciente desistiu na ida',
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
    if (status == StatusPacienteIda.ausente ||
        status == StatusPacienteIda.desistiu) {
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
    await registrarDespesaGeral(
      viagemId: viagemId,
      tipo: 'despesa',
      valor: 25,
      descricao: 'Despesa local',
    );
  }

  Future<void> registrarChecklist({
    required String viagemId,
    required String tipo,
    required Map<String, Object?> itens,
    String? observacao,
    String? fotoPath,
  }) async {
    if (itens.isEmpty) {
      throw const LogisticaValidationException(
        'Checklist deve possuir ao menos um item.',
      );
    }
    final snapshot = await carregarSnapshot(viagemId);
    final now = DateTime.now().toIso8601String();
    final db = await databaseHelper.database;
    await db.insert('logistica_checklists', {
      'id_local': 'chk-${DateTime.now().microsecondsSinceEpoch}',
      'id_servidor': null,
      'viagem_id_local': viagemId,
      'motorista_id_local':
          snapshot.viagem['motorista_id_local']?.toString() ??
          'motorista-local',
      'tipo': tipo,
      'payload_json': jsonEncode(itens),
      'concluido': 1,
      'observacao': observacao,
      'foto_path': fotoPath,
      'created_by': 'motorista-local',
      'created_at': now,
      'updated_at': now,
      'status_sync': StatusSync.pendente.dbValue,
    });
    await _auditar(
      entidade: 'logistica_checklists',
      entidadeId: viagemId,
      descricao: 'Checklist $tipo registrado.',
    );
  }

  Future<LogisticaAbastecimentoResult> registrarAbastecimento({
    required String viagemId,
    required String posto,
    required double litros,
    required double valorTotal,
    String? fotoCupomPath,
    String? observacao,
  }) async {
    LogisticaValidators.validarAbastecimento(litros: litros, valor: valorTotal);
    final snapshot = await carregarSnapshot(viagemId);
    final now = DateTime.now().toIso8601String();
    final db = await databaseHelper.database;
    await db.insert('logistica_abastecimentos', {
      'id_local': 'aba-${DateTime.now().microsecondsSinceEpoch}',
      'id_servidor': null,
      'viagem_id_local': viagemId,
      'veiculo_id_local': snapshot.viagem['veiculo_id_local']?.toString() ?? '',
      'motorista_id_local':
          snapshot.viagem['motorista_id_local']?.toString() ??
          'motorista-local',
      'local': posto,
      'tipo': 'abastecimento',
      'litros': litros,
      'valor': valorTotal,
      'foto_cupom_path': fotoCupomPath,
      'observacao': observacao,
      'created_by': 'motorista-local',
      'created_at': now,
      'updated_at': now,
      'status_sync': StatusSync.pendente.dbValue,
    });
    await _enqueue(TipoEventoSync.abastecimentoRegistrado, {
      'viagem_id': viagemId,
      'litros': litros,
      'valor': valorTotal,
      'valor_por_litro': LogisticaCalculator.valorPorLitro(
        valor: valorTotal,
        litros: litros,
      ),
    });
    await _auditar(
      entidade: 'logistica_abastecimentos',
      entidadeId: viagemId,
      descricao: 'Abastecimento registrado.',
    );
    return LogisticaAbastecimentoResult(
      valorPorLitro: LogisticaCalculator.valorPorLitro(
        valor: valorTotal,
        litros: litros,
      ),
      custoPorKm: LogisticaCalculator.custoPorKm(
        totalDespesas: valorTotal,
        kmRodado: snapshot.kmRodado,
      ),
    );
  }

  Future<void> registrarDespesaGeral({
    required String viagemId,
    required String tipo,
    required double valor,
    required String descricao,
    String? comprovantePath,
  }) async {
    if (valor < 0) {
      throw const LogisticaValidationException(
        'Despesa nao pode ter valor negativo.',
      );
    }
    if (descricao.trim().isEmpty) {
      throw const LogisticaValidationException(
        'Informe a descricao da despesa.',
      );
    }
    final snapshot = await carregarSnapshot(viagemId);
    final now = DateTime.now().toIso8601String();
    final db = await databaseHelper.database;
    await db.insert('logistica_abastecimentos', {
      'id_local': 'desp-${DateTime.now().microsecondsSinceEpoch}',
      'id_servidor': null,
      'viagem_id_local': viagemId,
      'veiculo_id_local': snapshot.viagem['veiculo_id_local']?.toString() ?? '',
      'motorista_id_local':
          snapshot.viagem['motorista_id_local']?.toString() ??
          'motorista-local',
      'local': descricao,
      'tipo': tipo,
      'litros': 0.0,
      'valor': valor,
      'foto_cupom_path': comprovantePath,
      'observacao': descricao,
      'created_by': 'motorista-local',
      'created_at': now,
      'updated_at': now,
      'status_sync': StatusSync.pendente.dbValue,
    });
    await _enqueue(TipoEventoSync.abastecimentoRegistrado, {
      'viagem_id': viagemId,
      'tipo': tipo,
      'valor': valor,
    });
    await _auditar(
      entidade: 'logistica_abastecimentos',
      entidadeId: viagemId,
      descricao: 'Despesa $tipo registrada.',
    );
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
        'justificativa_retorno':
            status == StatusPacienteVolta.justificado ||
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

  Future<void> concluirDesembarqueVolta({required String passageiroId}) async {
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
    if (!await _checklistConcluido(viagemId, 'pos_uso')) {
      throw const LogisticaValidationException(
        'Conclua o checklist pos-uso para encerrar a viagem.',
      );
    }
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

  Future<void> acionarPanico(
    String viagemId, {
    double? latitude,
    double? longitude,
  }) async {
    await registrarOcorrencia(
      viagemId: viagemId,
      tipo: TipoOcorrencia.panico,
      descricao: 'Pânico acionado pelo motorista.',
      latitude: latitude,
      longitude: longitude,
    );
    final payload = <String, Object?>{
      'viagem_id': viagemId,
      'mensagem': 'Central será notificada quando houver conexão',
    };
    if (latitude != null) payload['latitude'] = latitude;
    if (longitude != null) payload['longitude'] = longitude;
    await _enqueue(TipoEventoSync.panicoAcionado, payload);
  }

  Future<void> capturarComprovante(
    String viagemId,
    String passageiroId, {
    String? fotoPath,
    String? assinaturaPayloadJson,
  }) async {
    final db = await databaseHelper.database;
    final now = DateTime.now().toIso8601String();
    final passageiro = await db.query(
      'logistica_passageiros_viagem',
      where: 'id_local = ?',
      whereArgs: [passageiroId],
      limit: 1,
    );
    final pacienteId = passageiro.isNotEmpty
        ? passageiro.first['paciente_id_local']?.toString() ?? passageiroId
        : passageiroId;
    await db.insert('logistica_comprovantes', {
      'id_local': 'cmp-${DateTime.now().millisecondsSinceEpoch}',
      'id_servidor': null,
      'viagem_id_local': viagemId,
      'passageiro_id_local': passageiroId,
      'paciente_id_local': pacienteId,
      'tipo': 'presença',
      'foto_path': fotoPath ?? 'mock/comprovante.jpg',
      'assinatura_payload_json': assinaturaPayloadJson,
      'created_by': 'motorista-local',
      'created_at': now,
      'updated_at': now,
      'status_sync': StatusSync.pendente.dbValue,
    });
    await _enqueue(TipoEventoSync.comprovanteCapturado, {
      'viagem_id': viagemId,
      'passageiro_id': passageiroId,
      'paciente_id': pacienteId,
    });
    await _auditar(
      entidade: 'logistica_comprovantes',
      entidadeId: viagemId,
      descricao: 'Comprovante SUS capturado.',
    );
  }

  Future<void> registrarOcorrencia({
    required String viagemId,
    required TipoOcorrencia tipo,
    required String descricao,
    String? pacienteId,
    double? latitude,
    double? longitude,
    String? fotoPath,
  }) async {
    LogisticaValidators.validarOcorrencia(tipo: tipo, dataHora: DateTime.now());
    final db = await databaseHelper.database;
    final now = DateTime.now().toIso8601String();
    await db.insert('logistica_ocorrencias', {
      'id_local': 'oco-${DateTime.now().microsecondsSinceEpoch}',
      'id_servidor': null,
      'viagem_id_local': viagemId,
      'motorista_id_local': 'motorista-local',
      'paciente_id_local': pacienteId,
      'tipo': tipo.dbValue,
      'descricao': descricao,
      'data_hora': now,
      'latitude': latitude,
      'longitude': longitude,
      'foto_path': fotoPath,
      'created_by': 'motorista-local',
      'created_at': now,
      'updated_at': now,
      'status_sync': StatusSync.pendente.dbValue,
    });
    final payload = <String, Object?>{
      'viagem_id': viagemId,
      'tipo': tipo.dbValue,
      'descricao': descricao,
    };
    if (latitude != null) payload['latitude'] = latitude;
    if (longitude != null) payload['longitude'] = longitude;
    await _enqueue(TipoEventoSync.ocorrenciaRegistrada, payload);
    await _auditar(
      entidade: 'logistica_ocorrencias',
      entidadeId: viagemId,
      descricao: 'Ocorrencia ${tipo.dbValue} registrada.',
    );
  }

  Future<List<Map<String, Object?>>> listarHistorico(String viagemId) async {
    final db = await databaseHelper.database;
    final itens = <Map<String, Object?>>[];
    for (final entry in {
      'checklist': 'logistica_checklists',
      'despesa': 'logistica_abastecimentos',
      'ocorrencia': 'logistica_ocorrencias',
      'comprovante': 'logistica_comprovantes',
      'sync': 'logistica_sync_items',
    }.entries) {
      final where = entry.key == 'sync'
          ? 'payload_json LIKE ?'
          : 'viagem_id_local = ?';
      final whereArgs = entry.key == 'sync' ? ['%$viagemId%'] : [viagemId];
      final rows = await db.query(
        entry.value,
        where: where,
        whereArgs: whereArgs,
      );
      for (final row in rows) {
        itens.add({'categoria': entry.key, ...row});
      }
    }
    return itens;
  }

  Future<bool> _checklistConcluido(String viagemId, String tipo) async {
    final db = await databaseHelper.database;
    final result = await db.query(
      'logistica_checklists',
      where: 'viagem_id_local = ? AND tipo = ? AND concluido = 1',
      whereArgs: [viagemId, tipo],
      limit: 1,
    );
    return result.isNotEmpty;
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

  Future<void> _enqueue(
    TipoEventoSync tipo,
    Map<String, dynamic> payload,
  ) async {
    final db = await databaseHelper.database;
    final item = queue.criarItem(tipoEvento: tipo, payload: payload);
    await db.insert('logistica_sync_items', item.toMap());
  }

  Future<void> _auditar({
    required String entidade,
    required String entidadeId,
    required String descricao,
  }) async {
    final db = await databaseHelper.database;
    final now = DateTime.now().toIso8601String();
    await db.insert('auditoria_eventos', {
      'id': 'aud-${DateTime.now().microsecondsSinceEpoch}',
      'entity_type': entidade,
      'entity_id': entidadeId,
      'action': 'create',
      'actor_id': 'motorista-local',
      'descricao': descricao,
      'device_id': 'mobile-local',
      'version': 1,
      'created_at': now,
      'updated_at': now,
      'sync_status': 'pending',
    });
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
