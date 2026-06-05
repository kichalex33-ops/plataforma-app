import '../../../core/connectivity/models/connectivity_status.dart';
import '../../../core/sync/models/sync_status.dart';

enum LocalIndicatorsLoadStatus { loading, empty, error, loaded }

class LocalIndicators {
  final int totalViagens;
  final int viagensPendentes;
  final int viagensEmAndamento;
  final int viagensConcluidas;
  final int passageirosTransportados;
  final int ocorrenciasRegistradas;
  final int checklistsConcluidos;
  final int itensPendentesSincronizacao;
  final DateTime? ultimaSincronizacao;
  final ConnectivityStatus statusConexao;
  final SyncStatus statusSincronizacao;
  final List<String> errosRecentes;
  final LocalIndicatorsLoadStatus loadStatus;

  const LocalIndicators({
    required this.totalViagens,
    required this.viagensPendentes,
    required this.viagensEmAndamento,
    required this.viagensConcluidas,
    required this.passageirosTransportados,
    required this.ocorrenciasRegistradas,
    required this.checklistsConcluidos,
    required this.itensPendentesSincronizacao,
    required this.ultimaSincronizacao,
    required this.statusConexao,
    required this.statusSincronizacao,
    required this.errosRecentes,
    required this.loadStatus,
  });

  factory LocalIndicators.empty({
    ConnectivityStatus statusConexao = ConnectivityStatus.offline,
    SyncStatus statusSincronizacao = SyncStatus.pending,
  }) {
    return LocalIndicators(
      totalViagens: 0,
      viagensPendentes: 0,
      viagensEmAndamento: 0,
      viagensConcluidas: 0,
      passageirosTransportados: 0,
      ocorrenciasRegistradas: 0,
      checklistsConcluidos: 0,
      itensPendentesSincronizacao: 0,
      ultimaSincronizacao: null,
      statusConexao: statusConexao,
      statusSincronizacao: statusSincronizacao,
      errosRecentes: const [],
      loadStatus: LocalIndicatorsLoadStatus.empty,
    );
  }

  bool get hasOperationalData {
    return totalViagens > 0 ||
        passageirosTransportados > 0 ||
        ocorrenciasRegistradas > 0 ||
        checklistsConcluidos > 0 ||
        itensPendentesSincronizacao > 0;
  }

  LocalIndicators copyWith({LocalIndicatorsLoadStatus? loadStatus}) {
    return LocalIndicators(
      totalViagens: totalViagens,
      viagensPendentes: viagensPendentes,
      viagensEmAndamento: viagensEmAndamento,
      viagensConcluidas: viagensConcluidas,
      passageirosTransportados: passageirosTransportados,
      ocorrenciasRegistradas: ocorrenciasRegistradas,
      checklistsConcluidos: checklistsConcluidos,
      itensPendentesSincronizacao: itensPendentesSincronizacao,
      ultimaSincronizacao: ultimaSincronizacao,
      statusConexao: statusConexao,
      statusSincronizacao: statusSincronizacao,
      errosRecentes: errosRecentes,
      loadStatus: loadStatus ?? this.loadStatus,
    );
  }
}
