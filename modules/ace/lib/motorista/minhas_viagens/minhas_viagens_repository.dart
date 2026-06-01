import '../../database/database_helper.dart';
import '../../modules/transportes/models/viagem_model.dart';

class MinhasViagensRepository {
  final DatabaseHelper databaseHelper;

  MinhasViagensRepository({DatabaseHelper? databaseHelper})
    : databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  Future<List<ViagemModel>> listarPorMotorista(String motoristaId) async {
    final db = await databaseHelper.database;
    final normalizado = motoristaId.trim();

    final filtradas = normalizado.isEmpty
        ? <Map<String, Object?>>[]
        : await db.query(
            'transportes_viagens',
            where: 'motorista_id = ?',
            whereArgs: [normalizado],
            orderBy: 'data_hora_saida ASC',
          );

    if (filtradas.isNotEmpty) {
      return filtradas.map(ViagemModel.fromMap).toList();
    }

    final fallback = await db.query(
      'transportes_viagens',
      where: 'motorista_id IS NULL OR motorista_id = ?',
      whereArgs: [''],
      orderBy: 'data_hora_saida ASC',
    );

    return fallback.map(ViagemModel.fromMap).toList();
  }
}
