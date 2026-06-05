class ValidationResult {
  final bool isValid;
  final List<String> errors;

  const ValidationResult({required this.isValid, required this.errors});
}

class ValidationAgent {
  ValidationResult validateIndicatorCounts(Map<String, int> counts) {
    final errors = <String>[];
    for (final entry in counts.entries) {
      if (entry.value < 0) {
        errors.add('${entry.key} nao pode ser negativo.');
      }
    }
    return ValidationResult(isValid: errors.isEmpty, errors: errors);
  }

  void ensureIndicatorCounts(Map<String, int> counts) {
    final result = validateIndicatorCounts(counts);
    if (!result.isValid) {
      throw StateError(result.errors.join(' '));
    }
  }

  void ensureReportFilter(DateTime? start, DateTime? end) {
    if (start != null && end != null && start.isAfter(end)) {
      throw StateError('Data inicial nao pode ser posterior a data final.');
    }
  }
}
