enum AuditSeverity { info, warning, error, critical }

extension AuditSeverityLabel on AuditSeverity {
  String get value => name;

  String get label {
    return switch (this) {
      AuditSeverity.info => 'Informativo',
      AuditSeverity.warning => 'Atencao',
      AuditSeverity.error => 'Erro',
      AuditSeverity.critical => 'Critico',
    };
  }

  static AuditSeverity parse(String? value) {
    return AuditSeverity.values.firstWhere(
      (severity) => severity.value == value || severity.name == value,
      orElse: () => AuditSeverity.info,
    );
  }
}
