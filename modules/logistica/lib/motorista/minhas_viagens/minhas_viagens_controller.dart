import 'package:flutter/foundation.dart';

import '../../core/api/driver_api_client.dart';
import '../../modules/sync/models/sync_metadata.dart';
import '../../modules/transportes/models/viagem_model.dart';
import '../../modules/transportes/models/viagem_status.dart';
import 'minhas_viagens_repository.dart';

class MinhasViagensController extends ChangeNotifier {
  final MinhasViagensRepository repository;
  final DriverApiClient apiClient;

  MinhasViagensController({
    MinhasViagensRepository? repository,
    DriverApiClient? apiClient,
  }) : repository = repository ?? MinhasViagensRepository(),
       apiClient = apiClient ?? DriverApiClient();

  bool carregando = false;
  List<ViagemModel> viagens = const [];
  String? erro;
  bool servidorOnline = false;

  Future<void> carregar(String motoristaId) async {
    carregando = true;
    erro = null;
    notifyListeners();

    try {
      viagens = await repository.listarPorMotorista(motoristaId);
      servidorOnline = await apiClient.testarConexao();
      notifyListeners();

      final remotas = await apiClient.buscarViagensMockadas();
      if (remotas.isEmpty) return;

      final doServidor = remotas
          .map((item) => _viagemFromApi(item, motoristaId))
          .where((viagem) => viagem != null)
          .cast<ViagemModel>()
          .toList();

      if (doServidor.isNotEmpty) {
        viagens = doServidor;
        debugPrint('[SYNC] viagens do servidor=${doServidor.length}');
      }
    } catch (error) {
      erro = error.toString();
      viagens = const [];
      debugPrint('[SYNC] carregar viagens falhou: $error');
    } finally {
      carregando = false;
      notifyListeners();
    }
  }

  ViagemModel? _viagemFromApi(Map<String, dynamic> item, String motoristaId) {
    final id = item['id']?.toString();
    if (id == null || id.isEmpty) return null;

    final agora = DateTime.now().toIso8601String();
    return ViagemModel(
      sync: SyncMetadata(
        id: id,
        municipioId: item['municipio_id']?.toString() ?? 'local',
        createdAt: item['created_at']?.toString() ?? agora,
        updatedAt: item['updated_at']?.toString() ?? agora,
        syncStatus: 'synced',
      ),
      motoristaId: item['motorista_id']?.toString() ?? motoristaId,
      veiculoId: item['veiculo_id']?.toString(),
      origem: item['origem']?.toString() ?? 'Origem servidor',
      destino: item['destino']?.toString() ?? 'Destino servidor',
      dataHoraSaida:
          item['data_hora_saida']?.toString() ??
          item['dataHoraSaida']?.toString() ??
          agora,
      status: item['status']?.toString() ?? ViagemStatus.rascunho,
      finalidade: item['finalidade']?.toString(),
      observacoes: item['observacoes']?.toString(),
    );
  }
}
