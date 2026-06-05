import '../../indicators/models/local_indicators.dart';

class ReportFilter {
  final String title;
  final DateTime? start;
  final DateTime? end;
  final LocalIndicatorsLoadStatus? status;

  const ReportFilter({required this.title, this.start, this.end, this.status});
}
