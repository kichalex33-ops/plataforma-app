import 'package:flutter/foundation.dart';

import '../../../core/agents/agents.dart';
import '../../../core/sync/providers/sync_providers.dart';
import '../models/local_indicators.dart';
import '../services/local_indicators_service.dart';

class LocalIndicatorsState {
  final LocalIndicatorsLoadStatus status;
  final LocalIndicators? indicators;
  final String? error;

  const LocalIndicatorsState({
    required this.status,
    this.indicators,
    this.error,
  });

  const LocalIndicatorsState.loading()
    : status = LocalIndicatorsLoadStatus.loading,
      indicators = null,
      error = null;

  const LocalIndicatorsState.error(String message)
    : status = LocalIndicatorsLoadStatus.error,
      indicators = null,
      error = message;

  LocalIndicatorsState.loaded(LocalIndicators indicators)
    : status = indicators.hasOperationalData
          ? LocalIndicatorsLoadStatus.loaded
          : LocalIndicatorsLoadStatus.empty,
      indicators = indicators,
      error = null;
}

class LocalIndicatorsController extends ChangeNotifier {
  final LocalIndicatorsService service;

  LocalIndicatorsController({required this.service});

  LocalIndicatorsState _state = const LocalIndicatorsState.loading();

  LocalIndicatorsState get state => _state;

  Future<void> load() async {
    _state = const LocalIndicatorsState.loading();
    notifyListeners();
    try {
      final indicators = await service.load();
      _state = LocalIndicatorsState.loaded(indicators);
    } catch (error) {
      _state = LocalIndicatorsState.error(error.toString());
    }
    notifyListeners();
  }

  Future<void> refresh() async {
    try {
      final indicators = await service.refresh();
      _state = LocalIndicatorsState.loaded(indicators);
    } catch (error) {
      _state = LocalIndicatorsState.error(error.toString());
    }
    notifyListeners();
  }
}

LocalIndicatorsService buildLocalIndicatorsService() {
  return LocalIndicatorsService(
    appHealthAgent: appHealthAgentProvider,
    auditAgent: auditAgentProvider,
    reportAgent: ReportAgent(),
    validationAgent: ValidationAgent(),
  );
}

LocalIndicatorsController buildLocalIndicatorsController() {
  return LocalIndicatorsController(service: buildLocalIndicatorsService());
}

ConnectivityAgent get localIndicatorsConnectivityAgent =>
    appConnectivityAgentProvider;
