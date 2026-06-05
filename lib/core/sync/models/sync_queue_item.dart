import 'dart:math';

import 'sync_operation_type.dart';
import 'sync_status.dart';

class SyncQueueItem {
  final String id;
  final SyncOperationType operationType;
  final String entityType;
  final String entityId;
  final Map<String, dynamic> payload;
  final SyncStatus status;
  final int attempts;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastAttemptAt;
  final DateTime? syncedAt;
  final String? error;

  SyncQueueItem({
    required this.id,
    required this.operationType,
    required this.entityType,
    required this.entityId,
    required Map<String, dynamic> payload,
    required this.status,
    required this.attempts,
    required this.createdAt,
    required this.updatedAt,
    this.lastAttemptAt,
    this.syncedAt,
    this.error,
  }) : payload = Map.unmodifiable(payload);

  factory SyncQueueItem.pending({
    required SyncOperationType operationType,
    required String entityType,
    required String entityId,
    required Map<String, dynamic> payload,
    DateTime? now,
  }) {
    final createdAt = now ?? DateTime.now();
    return SyncQueueItem(
      id: createSecureLocalId(createdAt),
      operationType: operationType,
      entityType: entityType,
      entityId: entityId,
      payload: payload,
      status: SyncStatus.pending,
      attempts: 0,
      createdAt: createdAt,
      updatedAt: createdAt,
    );
  }

  SyncQueueItem copyWith({
    SyncOperationType? operationType,
    String? entityType,
    String? entityId,
    Map<String, dynamic>? payload,
    SyncStatus? status,
    int? attempts,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastAttemptAt,
    DateTime? syncedAt,
    String? error,
    bool clearError = false,
  }) {
    return SyncQueueItem(
      id: id,
      operationType: operationType ?? this.operationType,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      payload: payload ?? this.payload,
      status: status ?? this.status,
      attempts: attempts ?? this.attempts,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      syncedAt: syncedAt ?? this.syncedAt,
      error: clearError ? null : error ?? this.error,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'operation_type': operationType.value,
      'entity_type': entityType,
      'entity_id': entityId,
      'payload': payload,
      'status': status.value,
      'attempts': attempts,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'last_attempt_at': lastAttemptAt?.toIso8601String(),
      'synced_at': syncedAt?.toIso8601String(),
      'error': error,
    };
  }

  factory SyncQueueItem.fromJson(Map<String, dynamic> json) {
    return SyncQueueItem(
      id: json['id']?.toString() ?? createSecureLocalId(),
      operationType: SyncOperationTypeExtension.parse(
        json['operation_type']?.toString(),
      ),
      entityType: json['entity_type']?.toString() ?? '',
      entityId: json['entity_id']?.toString() ?? '',
      payload: Map<String, dynamic>.from(
        json['payload'] as Map? ?? const <String, dynamic>{},
      ),
      status: SyncStatusExtension.parse(json['status']?.toString()),
      attempts: int.tryParse(json['attempts']?.toString() ?? '') ?? 0,
      createdAt: _parseDate(json['created_at']) ?? DateTime.now(),
      updatedAt: _parseDate(json['updated_at']) ?? DateTime.now(),
      lastAttemptAt: _parseDate(json['last_attempt_at']),
      syncedAt: _parseDate(json['synced_at']),
      error: json['error']?.toString(),
    );
  }

  static String createSecureLocalId([DateTime? now]) {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    final hex = bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0'));
    final timestamp = (now ?? DateTime.now()).microsecondsSinceEpoch;
    return 'sync_${timestamp}_${hex.join()}';
  }

  static DateTime? _parseDate(Object? value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
