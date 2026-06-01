import 'package:uuid/uuid.dart';

import '../../../database/database_helper.dart';

class SyncLogRepository {
  final DatabaseHelper databaseHelper;

  SyncLogRepository({DatabaseHelper? databaseHelper})
    : databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  Future<void> registrar({
    String? entityType,
    String? entityId,
    required String status,
    String? message,
  }) async {
    final db = await databaseHelper.database;
    await db.insert('sync_logs', {
      'id': const Uuid().v4(),
      'entity_type': entityType,
      'entity_id': entityId,
      'status': status,
      'message': message,
      'created_at': DateTime.now().toIso8601String(),
    });
  }
}
