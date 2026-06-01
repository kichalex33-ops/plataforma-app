import 'dart:convert';

import 'package:http/http.dart' as http;

import '../repositories/sync_queue_repository.dart';
import 'sync_service.dart';

class SyncManager {
  final SyncQueueRepository queueRepository;

  SyncManager({SyncQueueRepository? queueRepository})
    : queueRepository = queueRepository ?? SyncQueueRepository();

  static const Map<String, String> _rotas = {
    'localidades': '/api/localidades',
    'setores_operacionais': '/api/setores-operacionais',
    'quarteiroes_operacionais': '/api/quarteiroes-operacionais',
    'atribuicoes_setor': '/api/atribuicoes-setor',
    'progresso_quarteirao': '/api/progresso-quarteirao',
    'auditoria_eventos': '/api/auditoria-eventos',
    'transportes_motoristas': '/api/transportes/motoristas',
    'transportes_veiculos': '/api/transportes/veiculos',
    'transportes_viagens': '/api/transportes/viagens',
    'transportes_passageiros': '/api/transportes/passageiros',
    'pacientes': '/api/pacientes',
    'rastreamento_viagem': '/api/rastreamento-viagem',
    'mapas_camadas': '/api/mapas/camadas',
  };

  Future<void> processQueue() async {
    final baseUrl = await SyncService.carregarServidorUrl();
    final pendentes = await queueRepository.listarPendentes();

    for (final item in pendentes) {
      final rota = _rotas[item.entityType];
      if (rota == null) continue;

      await queueRepository.marcarProcessando(item.id);

      try {
        final payload = jsonDecode(item.payload) as Map<String, dynamic>;
        final response = await http
            .post(
              Uri.parse('$baseUrl$rota'),
              headers: {'Content-Type': 'application/json; charset=utf-8'},
              body: jsonEncode({
                ...payload,
                '_sync': {
                  'operation': item.operation,
                  'checksum': item.checksum,
                  'device_id': item.deviceId,
                  'version': item.version,
                },
              }),
            )
            .timeout(const Duration(seconds: 10));

        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw Exception('Falha ${response.statusCode}: ${response.body}');
        }

        await queueRepository.marcarSincronizado(item.id);
      } catch (error) {
        await queueRepository.marcarFalha(item, error);
      }
    }

    await SyncService.salvarUltimaSincronizacao(DateTime.now());
  }
}
