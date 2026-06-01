import 'package:flutter/foundation.dart';

import '../../../core/api/driver_api_client.dart';
import '../repositories/evento_operacional_repository.dart';

class EventoSyncResult {
  final int enviados;
  final int falhas;
  final String? erro;

  const EventoSyncResult({
    required this.enviados,
    required this.falhas,
    this.erro,
  });
}

class EventoSyncService {
  final EventoOperacionalRepository repository;
  final DriverApiClient apiClient;

  EventoSyncService({
    EventoOperacionalRepository? repository,
    DriverApiClient? apiClient,
  }) : repository = repository ?? EventoOperacionalRepository(),
       apiClient = apiClient ?? DriverApiClient();

  Future<EventoSyncResult> enviarPendentes() async {
    final eventos = await repository.listarPendentes();
    debugPrint('[SYNC] eventos pendentes=${eventos.length}');
    var enviados = 0;
    var falhas = 0;
    String? ultimoErro;

    for (final evento in eventos) {
      try {
        debugPrint('[EVENTO] enviando id=${evento.id} tipo=${evento.tipo}');
        final ok = await apiClient.enviarEvento(evento.toMap());
        if (!ok) {
          throw Exception('Falha ao enviar evento ${evento.id}');
        }

        await repository.atualizarSyncStatus(
          eventoId: evento.id,
          syncStatus: 'synced',
        );
        enviados++;
        debugPrint('[EVENTO] sincronizado id=${evento.id}');
      } catch (error) {
        await repository.atualizarSyncStatus(
          eventoId: evento.id,
          syncStatus: 'failed',
        );
        falhas++;
        ultimoErro = error.toString();
        debugPrint('[EVENTO] falha id=${evento.id}: $error');
      }
    }

    return EventoSyncResult(
      enviados: enviados,
      falhas: falhas,
      erro: ultimoErro,
    );
  }
}
