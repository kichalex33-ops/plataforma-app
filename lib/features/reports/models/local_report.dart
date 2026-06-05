class LocalReportMetric {
  final String key;
  final String label;
  final num value;
  final String description;

  const LocalReportMetric({
    required this.key,
    required this.label,
    required this.value,
    required this.description,
  });
}

class LocalReportSection {
  final String title;
  final List<LocalReportMetric> metrics;

  const LocalReportSection({required this.title, required this.metrics});
}

class LocalReport {
  final String title;
  final DateTime generatedAt;
  final List<LocalReportSection> sections;
  final List<String> warnings;

  const LocalReport({
    required this.title,
    required this.generatedAt,
    required this.sections,
    this.warnings = const [],
  });

  num total(String key) {
    for (final section in sections) {
      for (final metric in section.metrics) {
        if (metric.key == key) return metric.value;
      }
    }
    return 0;
  }
}
