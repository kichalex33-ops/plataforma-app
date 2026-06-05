import 'package:flutter/foundation.dart';

import '../../../core/agents/agents.dart';
import '../../../core/sync/providers/sync_providers.dart';
import '../../indicators/providers/local_indicators_providers.dart';
import '../models/local_report.dart';
import '../models/report_filter.dart';
import '../services/local_report_service.dart';

class LocalReportState {
  final bool loading;
  final LocalReport? report;
  final String? error;

  const LocalReportState({required this.loading, this.report, this.error});

  const LocalReportState.loading()
    : loading = true,
      report = null,
      error = null;

  const LocalReportState.loaded(this.report) : loading = false, error = null;

  const LocalReportState.error(String message)
    : loading = false,
      report = null,
      error = message;
}

class LocalReportController extends ChangeNotifier {
  final LocalReportService service;

  LocalReportController({required this.service});

  LocalReportState _state = const LocalReportState.loading();

  LocalReportState get state => _state;

  Future<void> generate(ReportFilter filter) async {
    _state = const LocalReportState.loading();
    notifyListeners();
    try {
      _state = LocalReportState.loaded(await service.generate(filter));
    } catch (error) {
      _state = LocalReportState.error(error.toString());
    }
    notifyListeners();
  }
}

LocalReportService buildLocalReportService() {
  return LocalReportService(
    reportAgent: ReportAgent(),
    validationAgent: ValidationAgent(),
    appHealthAgent: appHealthAgentProvider,
    indicatorsService: buildLocalIndicatorsService(),
  );
}

LocalReportController buildLocalReportController() {
  return LocalReportController(service: buildLocalReportService());
}
