enum SyncOperationType {
  create,
  update,
  delete,
  event,
  gps,
  audit,
  checklist,
  occurrence,
  fuel,
  proof,
}

extension SyncOperationTypeExtension on SyncOperationType {
  String get value {
    switch (this) {
      case SyncOperationType.create:
        return 'create';
      case SyncOperationType.update:
        return 'update';
      case SyncOperationType.delete:
        return 'delete';
      case SyncOperationType.event:
        return 'event';
      case SyncOperationType.gps:
        return 'gps';
      case SyncOperationType.audit:
        return 'audit';
      case SyncOperationType.checklist:
        return 'checklist';
      case SyncOperationType.occurrence:
        return 'occurrence';
      case SyncOperationType.fuel:
        return 'fuel';
      case SyncOperationType.proof:
        return 'proof';
    }
  }

  static SyncOperationType parse(String? value) {
    switch (value) {
      case 'update':
        return SyncOperationType.update;
      case 'delete':
        return SyncOperationType.delete;
      case 'event':
        return SyncOperationType.event;
      case 'gps':
        return SyncOperationType.gps;
      case 'audit':
        return SyncOperationType.audit;
      case 'checklist':
        return SyncOperationType.checklist;
      case 'occurrence':
        return SyncOperationType.occurrence;
      case 'fuel':
        return SyncOperationType.fuel;
      case 'proof':
        return SyncOperationType.proof;
      case 'create':
      default:
        return SyncOperationType.create;
    }
  }
}
