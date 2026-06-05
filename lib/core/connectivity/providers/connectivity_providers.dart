import '../../agents/connectivity_agent.dart';
import '../services/connectivity_service.dart';

final connectivityServiceProvider = ConnectivityService();

final connectivityAgentProvider = ConnectivityAgent(
  service: connectivityServiceProvider,
);
