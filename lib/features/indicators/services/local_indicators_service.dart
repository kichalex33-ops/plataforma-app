import 'package:plataforma_logistica_driver/core/logistica/logistica_enums.dart';
import 'package:plataforma_logistica_driver/database/database_helper.dart';

import '../../../core/agents/agents.dart';
import '../models/local_indicators.dart';

class LocalIndicatorsService {
  final DatabaseHelper databaseHelper;
  final AppHealthAgent appHealthAgent;
  final AuditAgent auditAgent;
  final ReportAgent reportAgent;
  final ValidationAgent validationAgent;

  LocalIndicatorsService({
    DatabaseHelper? databaseHelper,
    required this.appHealthAgent,
    required this.auditAgent,
    required this.reportAgent,
    required this.validationAgent,
  }) : databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  Future<LocalIndicators> load() async {
    auditAgent.registerIndicatorsViewed();
    return _consolidate();
  }

  Future<LocalIndicators> refresh() async {
    auditAgent.registerIndicatorsRefreshed();
    return _consolidate();
  }

  Future<LocalIndicators> _consolidate() {
    return reportAgent.consolidate(
      reportName: 'indicadores_locais',
      builder: _buildIndicators,
    );
  }

  Future<LocalIndicators> _buildIndicators() async {
    final db = await databaseHelper.database;
    final health = await appHealthAgent.snapshot();

    final totalViagens = await _count(db, 'logistica_viagens');
    final viagensPendentes =
        await _countWhereIn(db, 'logistica_viagens', 'status', [
          StatusViagem.aguardando.dbValue,
          StatusViagem.preparacao.dbValue,
          StatusViagem.saidaConfirmada.dbValue,
          StatusViagem.pendenteSincronizacao.dbValue,
          StatusViagem.pendenteRevisao.dbValue,
        ]);
    final viagensEmAndamento =
        await _countWhereIn(db, 'logistica_viagens', 'status', [
          StatusViagem.emTransitoIda.dbValue,
          StatusViagem.emEspera.dbValue,
          StatusViagem.reembarqueRetorno.dbValue,
          StatusViagem.emTransitoVolta.dbValue,
          StatusViagem.finalizacao.dbValue,
        ]);
    final viagensConcluidas = await _countWhereIn(
      db,
      'logistica_viagens',
      'status',
      [StatusViagem.concluida.dbValue, StatusViagem.sincronizada.dbValue],
    );
    final passageirosTransportados = await _countWhereIn(
      db,
      'logistica_passageiros_viagem',
      'status_ida',
      [
        StatusPacienteIda.embarcado.dbValue,
        StatusPacienteIda.desembarcado.dbValue,
      ],
    );
    final ocorrenciasRegistradas = await _count(db, 'logistica_ocorrencias');
    final checklistsConcluidos = await _count(
      db,
      'logistica_checklists',
      where: 'concluido = ?',
      whereArgs: [1],
    );
    final pendenciasLogisticas = await _count(
      db,
      'logistica_sync_items',
      where: 'status_sync != ?',
      whereArgs: [StatusSync.sincronizado.dbValue],
    );
    final errosLogisticos = await _recentLogisticSyncErrors(db);

    final itensPendentesSincronizacao =
        health.pendingItems + pendenciasLogisticas;
    final errosRecentes = <String>[...health.recentErrors, ...errosLogisticos];

    validationAgent.ensureIndicatorCounts({
      'totalViagens': totalViagens,
      'viagensPendentes': viagensPendentes,
      'viagensEmAndamento': viagensEmAndamento,
      'viagensConcluidas': viagensConcluidas,
      'passageirosTransportados': passageirosTransportados,
      'ocorrenciasRegistradas': ocorrenciasRegistradas,
      'checklistsConcluidos': checklistsConcluidos,
      'itensPendentesSincronizacao': itensPendentesSincronizacao,
    });

    return LocalIndicators(
      totalViagens: totalViagens,
      viagensPendentes: viagensPendentes,
      viagensEmAndamento: viagensEmAndamento,
      viagensConcluidas: viagensConcluidas,
      passageirosTransportados: passageirosTransportados,
      ocorrenciasRegistradas: ocorrenciasRegistradas,
      checklistsConcluidos: checklistsConcluidos,
      itensPendentesSincronizacao: itensPendentesSincronizacao,
      ultimaSincronizacao: health.lastSuccessfulSync,
      statusConexao: health.connectivityStatus,
      statusSincronizacao: health.status,
      errosRecentes: errosRecentes,
      loadStatus: LocalIndicatorsLoadStatus.loaded,
    );
  }

  Future<int> _count(
    dynamic db,
    String table, {
    String? where,
    List<Object?> whereArgs = const [],
  }) async {
    try {
      final sql = StringBuffer('SELECT COUNT(*) AS total FROM $table');
      if (where != null && where.trim().isNotEmpty) {
        sql.write(' WHERE $where');
      }
      final result = await db.rawQuery(sql.toString(), whereArgs);
      final value = result.first['total'];
      return value is int ? value : int.tryParse(value.toString()) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<int> _countWhereIn(
    dynamic db,
    String table,
    String column,
    List<String> values,
  ) async {
    if (values.isEmpty) return 0;
    final placeholders = List.filled(values.length, '?').join(',');
    return _count(
      db,
      table,
      where: '$column IN ($placeholders)',
      whereArgs: values,
    );
  }

  Future<List<String>> _recentLogisticSyncErrors(dynamic db) async {
    try {
      final rows = await db.query(
        'logistica_sync_items',
        columns: ['erro'],
        where: 'erro IS NOT NULL AND erro != ?',
        whereArgs: [''],
        orderBy: 'updated_at DESC',
        limit: 5,
      );
      return rows
          .map((row) => row['erro']?.toString() ?? '')
          .where((error) => error.trim().isNotEmpty)
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }
}

extension LocalIndicatorsFallback on LocalIndicatorsService {
  Future<LocalIndicators> emptyFallback() async {
    final health = await appHealthAgent.snapshot();
    return LocalIndicators.empty(
      statusConexao: health.connectivityStatus,
      statusSincronizacao: health.status,
    ).copyWith(loadStatus: LocalIndicatorsLoadStatus.loaded);
  }
}
