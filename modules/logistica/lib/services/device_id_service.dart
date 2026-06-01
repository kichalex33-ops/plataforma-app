import 'package:uuid/uuid.dart';

import '../database/database_helper.dart';

class DeviceIdService {
  static const _key = 'device_id';

  const DeviceIdService();

  Future<String> getDeviceId() async {
    final db = DatabaseHelper.instance;
    final salvo = await db.carregarValorConfiguracao(_key);
    if (salvo != null && salvo.isNotEmpty) return salvo;

    final novo = const Uuid().v4();
    await db.salvarValorConfiguracao(_key, novo);
    return novo;
  }
}
