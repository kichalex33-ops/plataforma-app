typedef LocalReportBuilder<T> = Future<T> Function();

class ReportAgent {
  Future<T> consolidate<T>({
    required String reportName,
    required LocalReportBuilder<T> builder,
  }) {
    return builder();
  }
}
