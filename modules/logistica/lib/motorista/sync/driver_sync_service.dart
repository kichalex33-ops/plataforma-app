import 'package:flutter/foundation.dart';

import '../../core/api/driver_api_client.dart';
import '../../database/database_helper.dart';
import '../../services/sync_service.dart';
import '../eventos/services/evento_sync_service.dart';

class DriverSyncStatus {
  final bool online;
  final int enviados;
  final int falhas;
  final String? ultimoSync;
  final String? mensagem;

  const DriverSyncStatus({
    required this.online,
    this.enviados = 0,
    this.falhas = 0,
    this.ultimoSync,
    this.mensagem,
  });

  String get rotuloConexao => online ? 'Online' : 'Offline';

  String get resumoSync {
    final partes = <String>[
      rotuloConexao,
      'Enviados: $enviados',
      'Falhas: $falhas',
    ];
    if (ultimoSync != null && ultimoSync!.isNotEmpty) {
      partes.add('Ultimo sync: $ultimoSync');
    }
    return partes.join(' | ');
  }
}

class DriverSyncService {
  static const chaveOnline = 'driver_sync_online';
  static const chaveEnviados = 'driver_sync_enviados';
  static const chaveFalhas = 'driver_sync_falhas';
  static const chaveUltimoSync = 'driver_sync_ultimo';

  final DriverApiClient apiClient;
  final EventoSyncService eventoSyncService;
  final DatabaseHelper database;

  DriverSyncService({
    DriverApiClient? apiClient,
    EventoSyncService? eventoSyncService,
    DatabaseHelper? database,
  }) : apiClient = apiClient ?? DriverApiClient(),
       eventoSyncService = eventoSyncService ?? EventoSyncService(),
       database = database ?? DatabaseHelper.instance;

  Future<void> garantirUrlPadrao() async {
    final salvo = await database.carregarValorConfiguracao(
      SyncService.chaveServidorUrl,
    );
    if (salvo == null || salvo.trim().isEmpty) {
      await SyncService.salvarServidorUrl(
        SyncService.servidorPadrao,
        database: database,
      );
    }
  }

  Future<DriverSyncStatus> carregarStatusSalvo() async {
    final online =
        (await database.carregarValorConfiguracao(chaveOnline)) == 'true';
    final enviados =
        int.tryParse(
          await database.carregarValorConfiguracao(chaveEnviados) ?? '0',
        ) ??
        0;
    final falhas =
        int.tryParse(
          await database.carregarValorConfiguracao(chaveFalhas) ?? '0',
        ) ??
        0;
    final ultimoSync = await database.carregarValorConfiguracao(
      chaveUltimoSync,
    );

    return DriverSyncStatus(
      online: online,
      enviados: enviados,
      falhas: falhas,
      ultimoSync: _formatarUltimoSync(ultimoSync),
    );
  }

  Future<DriverSyncStatus> testarConexao() async {
    debugPrint('[SYNC] testarConexao');
    await garantirUrlPadrao();

    final online = await apiClient.testarConexao();
    final status = DriverSyncStatus(
      online: online,
      enviados:
          int.tryParse(
            await database.carregarValorConfiguracao(chaveEnviados) ?? '0',
          ) ??
          0,
      falhas:
          int.tryParse(
            await database.carregarValorConfiguracao(chaveFalhas) ?? '0',
          ) ??
          0,
      ultimoSync: _formatarUltimoSync(
        await database.carregarValorConfiguracao(chaveUltimoSync),
      ),
      mensagem: online ? null : 'Servidor offline ou indisponivel',
    );

    await _persistir(status);
    return status;
  }

  Future<DriverSyncStatus> sincronizarAgora() async {
    debugPrint('[SYNC] sincronizarAgora');
    await garantirUrlPadrao();

    final online = await apiClient.testarConexao();
    if (!online) {
      final offline = DriverSyncStatus(
        online: false,
        enviados:
            int.tryParse(
              await database.carregarValorConfiguracao(chaveEnviados) ?? '0',
            ) ??
            0,
        falhas:
            int.tryParse(
              await database.carregarValorConfiguracao(chaveFalhas) ?? '0',
            ) ??
            0,
        ultimoSync: _formatarUltimoSync(
          await database.carregarValorConfiguracao(chaveUltimoSync),
        ),
        mensagem: 'Servidor offline ou indisponivel',
      );
      await _persistir(offline);
      return offline;
    }

    final resultado = await eventoSyncService.enviarPendentes();
    debugPrint(
      '[SYNC] eventos enviados=${resultado.enviados} falhas=${resultado.falhas}',
    );

    final agora = DateTime.now().toIso8601String();
    final status = DriverSyncStatus(
      online: true,
      enviados: resultado.enviados,
      falhas: resultado.falhas,
      ultimoSync: _formatarUltimoSync(agora),
      mensagem: resultado.erro,
    );

    await _persistir(status, ultimoSyncIso: agora);
    await SyncService.salvarUltimaSincronizacao(
      DateTime.now(),
      database: database,
    );
    return status;
  }

  Future<void> _persistir(
    DriverSyncStatus status, {
    String? ultimoSyncIso,
  }) async {
    await database.salvarValorConfiguracao(
      chaveOnline,
      status.online ? 'true' : 'false',
    );
    await database.salvarValorConfiguracao(chaveEnviados, '${status.enviados}');
    await database.salvarValorConfiguracao(chaveFalhas, '${status.falhas}');
    if (ultimoSyncIso != null) {
      await database.salvarValorConfiguracao(chaveUltimoSync, ultimoSyncIso);
    }
  }

  String? _formatarUltimoSync(String? valor) {
    if (valor == null || valor.trim().isEmpty) return null;
    final data = DateTime.tryParse(valor);
    if (data == null) return valor;
    return '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/'
        '${data.year} '
        '${data.hour.toString().padLeft(2, '0')}:'
        '${data.minute.toString().padLeft(2, '0')}';
  }
}
