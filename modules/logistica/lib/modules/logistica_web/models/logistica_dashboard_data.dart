import '../../rastreamento/models/rastreamento_ponto_model.dart';
import '../../transportes/models/motorista_model.dart';
import '../../transportes/models/veiculo_model.dart';
import '../../transportes/models/viagem_model.dart';
import '../../../models/sync_queue_item_model.dart';

class LogisticaDashboardData {
  final List<ViagemModel> viagens;
  final List<MotoristaModel> motoristas;
  final List<VeiculoModel> veiculos;
  final int pacientes;
  final int passageiros;
  final List<RastreamentoPontoModel> rastreamentos;
  final List<SyncQueueItemModel> syncRecentes;
  final Map<String, int> syncPorStatus;
  final bool servidorOnline;
  final DateTime atualizadoEm;

  const LogisticaDashboardData({
    required this.viagens,
    required this.motoristas,
    required this.veiculos,
    required this.pacientes,
    required this.passageiros,
    required this.rastreamentos,
    required this.syncRecentes,
    required this.syncPorStatus,
    required this.servidorOnline,
    required this.atualizadoEm,
  });

  int get viagensDoDia {
    final hoje = DateTime.now();
    return viagens.where((viagem) {
      final data = DateTime.tryParse(viagem.dataHoraSaida);
      return data != null &&
          data.year == hoje.year &&
          data.month == hoje.month &&
          data.day == hoje.day;
    }).length;
  }

  int get viagensEmAndamento => viagens
      .where((viagem) => viagem.status.toLowerCase().contains('andamento'))
      .length;

  int get viagensAtrasadas => viagens
      .where((viagem) => viagem.status.toLowerCase().contains('atras'))
      .length;

  int get pendencias =>
      (syncPorStatus['pending'] ?? 0) + (syncPorStatus['failed'] ?? 0);

  int get motoristasAtivos =>
      motoristas.where((item) => item.status == 'ativo').length;

  int get veiculosAtivos =>
      veiculos.where((item) => item.status == 'ativo').length;

  int get alertasCriticos =>
      viagensAtrasadas + (syncPorStatus['failed'] ?? 0) + offlineOperacional;

  int get offlineOperacional => servidorOnline ? 0 : 1;

  Map<String, int> get viagensPorStatus {
    final map = <String, int>{};
    for (final viagem in viagens) {
      map[viagem.status] = (map[viagem.status] ?? 0) + 1;
    }
    return map;
  }
}
