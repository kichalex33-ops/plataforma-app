import 'package:flutter/foundation.dart';

import '../../../repositories/sync_queue_repository.dart';
import '../../../services/sync_manager.dart';
import '../models/logisaude_dashboard_data.dart';
import '../repositories/logisaude_dashboard_repository.dart';

class LogisaudeDashboardController extends ChangeNotifier {
  final LogisaudeDashboardRepository repository;
  final SyncQueueRepository syncQueueRepository;
  final SyncManager syncManager;

  LogisaudeDashboardController({
    LogisaudeDashboardRepository? repository,
    SyncQueueRepository? syncQueueRepository,
    SyncManager? syncManager,
  }) : repository = repository ?? LogisaudeDashboardRepository(),
       syncQueueRepository = syncQueueRepository ?? SyncQueueRepository(),
       syncManager = syncManager ?? SyncManager();

  LogisaudeDashboardData? data;
  bool carregando = false;
  String? erro;

  Future<void> carregar() async {
    carregando = true;
    erro = null;
    notifyListeners();

    try {
      data = await repository.carregar();
    } catch (error) {
      erro = error.toString();
    } finally {
      carregando = false;
      notifyListeners();
    }
  }

  Future<void> solicitarSincronizacao() async {
    carregando = true;
    erro = null;
    notifyListeners();

    try {
      if (!kIsWeb) {
        await syncManager.processQueue();
      }
      data = await repository.carregar();
    } catch (error) {
      erro = error.toString();
    } finally {
      carregando = false;
      notifyListeners();
    }
  }

  Future<void> reprocessarPendencias() async {
    if (kIsWeb) {
      await carregar();
      return;
    }

    await syncQueueRepository.retryFailed();
    await carregar();
  }
}
