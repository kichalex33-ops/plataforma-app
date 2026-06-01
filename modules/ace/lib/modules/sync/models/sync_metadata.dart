class SyncMetadata {
  final String id;
  final String municipioId;
  final String? deviceId;
  final int version;
  final String createdAt;
  final String updatedAt;
  final String syncStatus;

  const SyncMetadata({
    required this.id,
    required this.municipioId,
    this.deviceId,
    this.version = 1,
    required this.createdAt,
    required this.updatedAt,
    this.syncStatus = 'pending',
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'municipio_id': municipioId,
    'device_id': deviceId,
    'version': version,
    'created_at': createdAt,
    'updated_at': updatedAt,
    'sync_status': syncStatus,
  };

  factory SyncMetadata.fromMap(Map<String, dynamic> map) {
    return SyncMetadata(
      id: map['id']?.toString() ?? '',
      municipioId: map['municipio_id']?.toString() ?? 'local',
      deviceId: map['device_id'] as String?,
      version: map['version'] as int? ?? 1,
      createdAt: map['created_at']?.toString() ?? '',
      updatedAt: map['updated_at']?.toString() ?? '',
      syncStatus: map['sync_status']?.toString() ?? 'pending',
    );
  }
}
