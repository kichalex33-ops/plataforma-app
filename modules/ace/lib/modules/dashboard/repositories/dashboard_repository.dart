import 'package:sqflite/sqflite.dart';

import '../../../database/database_helper.dart';
import '../models/plataforma_indicadores.dart';

class PlataformaDashboardRepository {
  final DatabaseHelper databaseHelper;

  PlataformaDashboardRepository({DatabaseHelper? databaseHelper})
    : databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  Future<PlataformaIndicadores> carregar() async {
    final db = await databaseHelper.database;
    return PlataformaIndicadores(
      viagens: await _count(db, 'transportes_viagens'),
      pacientes: await _count(db, 'pacientes'),
      passageiros: await _count(db, 'transportes_passageiros'),
      veiculos: await _count(db, 'transportes_veiculos'),
      pendenciasSync: await databaseHelper.contarPendentesSincronizacao(),
    );
  }

  Future<int> _count(Database db, String table) async {
    final result = await db.rawQuery('SELECT COUNT(*) AS total FROM $table');
    return result.first['total'] as int? ?? 0;
  }
}
