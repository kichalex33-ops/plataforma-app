class SyncQueueItemModel {
  final String id;
  final String entityType;
  final String entityId;
  final String operation;
  final String payload;
  final String checksum;
  final String status;
  final int retryCount;
  final String deviceId;
  final int version;
  final String createdAt;
  final String updatedAt;
  final String? lastAttemptAt;
  final String? errorMessage;

  const SyncQueueItemModel({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.payload,
    required this.checksum,
    required this.status,
    required this.retryCount,
    required this.deviceId,
    required this.version,
    required this.createdAt,
    required this.updatedAt,
    this.lastAttemptAt,
    this.errorMessage,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'entity_type': entityType,
    'entity_id': entityId,
    'operation': operation,
    'payload': payload,
    'checksum': checksum,
    'status': status,
    'retry_count': retryCount,
    'device_id': deviceId,
    'version': version,
    'created_at': createdAt,
    'updated_at': updatedAt,
    'last_attempt_at': lastAttemptAt,
    'error_message': errorMessage,
  };

  factory SyncQueueItemModel.fromMap(Map<String, dynamic> map) {
    return SyncQueueItemModel(
      id: map['id']?.toString() ?? '',
      entityType: map['entity_type']?.toString() ?? '',
      entityId: map['entity_id']?.toString() ?? '',
      operation: map['operation']?.toString() ?? '',
      payload: map['payload']?.toString() ?? '{}',
      checksum: map['checksum']?.toString() ?? '',
      status: map['status']?.toString() ?? 'pending',
      retryCount: map['retry_count'] as int? ?? 0,
      deviceId: map['device_id']?.toString() ?? '',
      version: map['version'] as int? ?? 1,
      createdAt: map['created_at']?.toString() ?? '',
      updatedAt: map['updated_at']?.toString() ?? '',
      lastAttemptAt: map['last_attempt_at'] as String?,
      errorMessage: map['error_message'] as String?,
    );
  }
}
