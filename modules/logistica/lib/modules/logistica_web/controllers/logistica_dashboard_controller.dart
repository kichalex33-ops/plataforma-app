import 'package:flutter/foundation.dart';

import '../../../repositories/sync_queue_repository.dart';
import '../../../services/sync_manager.dart';
import '../models/logistica_dashboard_data.dart';
import '../repositories/logistica_dashboard_repository.dart';

class LogisticaDashboardController extends ChangeNotifier {
  final LogisticaDashboardRepository repository;
  final SyncQueueRepository syncQueueRepository;
  final SyncManager syncManager;

  LogisticaDashboardController({
    LogisticaDashboardRepository? repository,
    SyncQueueRepository? syncQueueRepository,
    SyncManager? syncManager,
  }) : repository = repository ?? LogisticaDashboardRepository(),
       syncQueueRepository = syncQueueRepository ?? SyncQueueRepository(),
       syncManager = syncManager ?? SyncManager();

  LogisticaDashboardData? data;
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
