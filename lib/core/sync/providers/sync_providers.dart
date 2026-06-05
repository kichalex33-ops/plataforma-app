import '../../agents/app_health_agent.dart';
import '../../agents/audit_agent.dart';
import '../../agents/connectivity_agent.dart';
import '../../agents/sync_agent.dart';
import '../../audit/providers/audit_providers.dart';
import '../../connectivity/providers/connectivity_providers.dart';
import '../repositories/sync_queue_repository.dart';
import '../services/sync_queue_service.dart';

final syncQueueRepositoryProvider = SharedPreferencesSyncQueueRepository();

final auditAgentProvider = AuditAgent(logService: auditLogServiceProvider);

final syncQueueServiceProvider = SyncQueueService(
  repository: syncQueueRepositoryProvider,
  dispatcher: (_) async {},
);

final syncAgentProvider = SyncAgent(
  queueService: syncQueueServiceProvider,
  connectivityAgent: connectivityAgentProvider,
  auditAgent: auditAgentProvider,
);

final appHealthAgentProvider = AppHealthAgent(
  repository: syncQueueRepositoryProvider,
  auditAgent: auditAgentProvider,
  connectivityAgent: connectivityAgentProvider,
);

ConnectivityAgent get appConnectivityAgentProvider => connectivityAgentProvider;
