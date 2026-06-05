enum SyncStatus { pending, syncing, synced, failed }

extension SyncStatusExtension on SyncStatus {
  String get value {
    switch (this) {
      case SyncStatus.pending:
        return 'pending';
      case SyncStatus.syncing:
        return 'syncing';
      case SyncStatus.synced:
        return 'synced';
      case SyncStatus.failed:
        return 'failed';
    }
  }

  String get label {
    switch (this) {
      case SyncStatus.pending:
        return 'Pendente';
      case SyncStatus.syncing:
        return 'Sincronizando';
      case SyncStatus.synced:
        return 'Sincronizado';
      case SyncStatus.failed:
        return 'Erro de sincronizacao';
    }
  }

  bool get isUnsynced => this != SyncStatus.synced;

  static SyncStatus parse(String? value) {
    switch (value) {
      case 'syncing':
        return SyncStatus.syncing;
      case 'synced':
        return SyncStatus.synced;
      case 'failed':
        return SyncStatus.failed;
      case 'pending':
      default:
        return SyncStatus.pending;
    }
  }
}
