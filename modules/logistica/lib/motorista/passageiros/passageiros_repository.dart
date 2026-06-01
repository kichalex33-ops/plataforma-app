import '../../database/database_helper.dart';
import '../../modules/transportes/models/passageiro_model.dart';

class PassageirosRepository {
  final DatabaseHelper databaseHelper;

  PassageirosRepository({DatabaseHelper? databaseHelper})
    : databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  Future<List<PassageiroModel>> listarPorViagem(String viagemId) async {
    final db = await databaseHelper.database;
    final result = await db.query(
      'transportes_passageiros',
      where: 'viagem_id = ?',
      whereArgs: [viagemId],
      orderBy: 'nome ASC',
    );

    return result.map(PassageiroModel.fromMap).toList();
  }
}
