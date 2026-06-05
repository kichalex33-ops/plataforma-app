import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:plataforma_logistica_driver/database/database_helper.dart';
import 'package:plataforma_logistica_driver/motorista/minhas_viagens/minhas_viagens_repository.dart';

void main() {
  test('lista somente viagens atribuidas ao motorista informado', () async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    final db = await DatabaseHelper.instance.database;
    await db.delete('transportes_viagens');
    await db.insert('transportes_viagens', {
      'id': 'viagem-1',
      'municipio_id': 'local',
      'motorista_id': 'motorista-1',
      'origem': 'UBS Centro',
      'destino': 'Hospital',
      'data_hora_saida': '2026-05-28T10:00:00.000',
      'status': 'agendada',
      'device_id': 'device',
      'version': 1,
      'created_at': '2026-05-28T09:00:00.000',
      'updated_at': '2026-05-28T09:00:00.000',
      'sync_status': 'pending',
    });
    await db.insert('transportes_viagens', {
      'id': 'viagem-2',
      'municipio_id': 'local',
      'motorista_id': 'motorista-2',
      'origem': 'UBS Norte',
      'destino': 'Clinica',
      'data_hora_saida': '2026-05-28T11:00:00.000',
      'status': 'agendada',
      'device_id': 'device',
      'version': 1,
      'created_at': '2026-05-28T09:00:00.000',
      'updated_at': '2026-05-28T09:00:00.000',
      'sync_status': 'pending',
    });

    final viagens = await MinhasViagensRepository().listarPorMotorista(
      'motorista-1',
    );

    expect(viagens, hasLength(1));
    expect(viagens.single.sync.id, 'viagem-1');
  });
}
