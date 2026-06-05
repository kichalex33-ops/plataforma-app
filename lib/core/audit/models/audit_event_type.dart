enum AuditEventType {
  appOpened,
  login,
  logout,
  tripStarted,
  tripCompleted,
  statusChanged,
  checklistStarted,
  checklistCompleted,
  occurrenceRegistered,
  indicatorsViewed,
  indicatorsRefreshed,
  reportViewed,
  reportGenerated,
  syncAttempt,
  syncCompleted,
  syncFailed,
  syncSkipped,
  generic,
}

extension AuditEventTypeLabel on AuditEventType {
  String get value {
    final name = this.name;
    final buffer = StringBuffer();
    for (var i = 0; i < name.length; i++) {
      final char = name[i];
      final isUpper = char.toUpperCase() == char && char.toLowerCase() != char;
      if (isUpper && i > 0) buffer.write('_');
      buffer.write(char.toLowerCase());
    }
    return buffer.toString();
  }

  String get label {
    return switch (this) {
      AuditEventType.appOpened => 'Abertura do app',
      AuditEventType.login => 'Login',
      AuditEventType.logout => 'Logout',
      AuditEventType.tripStarted => 'Inicio de viagem',
      AuditEventType.tripCompleted => 'Conclusao de viagem',
      AuditEventType.statusChanged => 'Alteracao de status',
      AuditEventType.checklistStarted => 'Checklist iniciado',
      AuditEventType.checklistCompleted => 'Checklist concluido',
      AuditEventType.occurrenceRegistered => 'Ocorrencia registrada',
      AuditEventType.indicatorsViewed => 'Acesso aos indicadores',
      AuditEventType.indicatorsRefreshed => 'Atualizacao de indicadores',
      AuditEventType.reportViewed => 'Acesso aos relatorios',
      AuditEventType.reportGenerated => 'Relatorio gerado',
      AuditEventType.syncAttempt => 'Tentativa de sincronizacao',
      AuditEventType.syncCompleted => 'Sincronizacao concluida',
      AuditEventType.syncFailed => 'Falha de sincronizacao',
      AuditEventType.syncSkipped => 'Sincronizacao ignorada',
      AuditEventType.generic => 'Evento',
    };
  }

  static AuditEventType parse(String? value) {
    if (value == null || value.trim().isEmpty) return AuditEventType.generic;
    for (final type in AuditEventType.values) {
      if (type.value == value || type.name == value) return type;
    }
    return AuditEventType.generic;
  }
}
