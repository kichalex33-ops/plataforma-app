import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../../database/database_helper.dart';
import '../../../repositories/sync_queue_repository.dart';
import '../../../services/device_id_service.dart';
import '../../sync/models/sync_metadata.dart';
import '../models/motorista_model.dart';
import '../models/passageiro_model.dart';
import '../models/veiculo_model.dart';
import '../models/viagem_model.dart';
import '../models/viagem_status.dart';

class TransportesRepository {
  final DatabaseHelper databaseHelper;
  final SyncQueueRepository syncQueueRepository;
  final DeviceIdService deviceIdService;

  TransportesRepository({
    DatabaseHelper? databaseHelper,
    SyncQueueRepository? syncQueueRepository,
    DeviceIdService? deviceIdService,
  }) : databaseHelper = databaseHelper ?? DatabaseHelper.instance,
       syncQueueRepository = syncQueueRepository ?? SyncQueueRepository(),
       deviceIdService = deviceIdService ?? const DeviceIdService();

  Future<Map<String, int>> resumo() async {
    final db = await databaseHelper.database;
    return {
      'viagens': await _count(db, 'transportes_viagens'),
      'motoristas': await _count(db, 'transportes_motoristas'),
      'veiculos': await _count(db, 'transportes_veiculos'),
      'passageiros': await _count(db, 'transportes_passageiros'),
    };
  }

  Future<List<ViagemModel>> listarViagens() async {
    final db = await databaseHelper.database;
    final result = await db.query(
      'transportes_viagens',
      orderBy: 'data_hora_saida DESC',
    );
    return result.map(ViagemModel.fromMap).toList();
  }

  Future<List<MotoristaModel>> listarMotoristas() async {
    final db = await databaseHelper.database;
    final result = await db.query(
      'transportes_motoristas',
      orderBy: 'nome ASC',
    );
    return result.map(MotoristaModel.fromMap).toList();
  }

  Future<List<VeiculoModel>> listarVeiculos() async {
    final db = await databaseHelper.database;
    final result = await db.query('transportes_veiculos', orderBy: 'placa ASC');
    return result.map(VeiculoModel.fromMap).toList();
  }

  Future<List<PassageiroModel>> listarPassageiros() async {
    final db = await databaseHelper.database;
    final result = await db.query(
      'transportes_passageiros',
      orderBy: 'created_at DESC',
    );
    return result.map(PassageiroModel.fromMap).toList();
  }

  Future<ViagemModel> criarViagem({
    required String municipioId,
    required String origem,
    required String destino,
    required DateTime dataHoraSaida,
    String? motoristaId,
    String? veiculoId,
    String? finalidade,
    String status = ViagemStatus.agendada,
    String? observacoes,
    String prioridade = 'normal',
    String? observacoesCentral,
    String? unidadeDestino,
    String? dataConsulta,
    String? horarioConsulta,
    String? destinoPrincipal,
  }) async {
    final now = DateTime.now().toIso8601String();
    final viagem = ViagemModel(
      sync: await _metadata(municipioId, now),
      motoristaId: motoristaId,
      veiculoId: veiculoId,
      origem: origem,
      destino: destino,
      dataHoraSaida: dataHoraSaida.toIso8601String(),
      finalidade: finalidade,
      status: status,
      observacoes: observacoes,
      prioridade: prioridade,
      observacoesCentral: observacoesCentral,
      unidadeDestino: unidadeDestino,
      dataConsulta: dataConsulta,
      horarioConsulta: horarioConsulta,
      destinoPrincipal: destinoPrincipal,
      statusOperacional: ViagemStatus.aguardando,
    );
    await _insertAndQueue(
      'transportes_viagens',
      viagem.sync.id,
      viagem.toMap(),
    );
    return viagem;
  }

  Future<MotoristaModel> criarMotorista({
    required String municipioId,
    required String nome,
    String? telefone,
  }) async {
    final now = DateTime.now().toIso8601String();
    final motorista = MotoristaModel(
      sync: await _metadata(municipioId, now),
      nome: nome,
      telefone: telefone,
    );
    await _insertAndQueue(
      'transportes_motoristas',
      motorista.sync.id,
      motorista.toMap(),
    );
    return motorista;
  }

  Future<VeiculoModel> criarVeiculo({
    required String municipioId,
    required String placa,
    required String modelo,
    required String tipo,
    int capacidade = 0,
  }) async {
    final now = DateTime.now().toIso8601String();
    final veiculo = VeiculoModel(
      sync: await _metadata(municipioId, now),
      placa: placa,
      modelo: modelo,
      tipo: tipo,
      capacidade: capacidade,
    );
    await _insertAndQueue(
      'transportes_veiculos',
      veiculo.sync.id,
      veiculo.toMap(),
    );
    return veiculo;
  }

  Future<PassageiroModel> adicionarPassageiro({
    required String municipioId,
    required String viagemId,
    required String nome,
    String? pacienteId,
    String? necessidadeEspecial,
    String? embarque,
    String? desembarque,
    bool acompanhante = false,
    String? acessibilidade,
    String? telefone,
    String? enderecoEmbarque,
    bool cadeirante = false,
    bool mobilidadeReduzida = false,
    bool acompanhanteObrigatorio = false,
    String? observacoesEmbarque,
  }) async {
    final now = DateTime.now().toIso8601String();
    final passageiro = PassageiroModel(
      sync: await _metadata(municipioId, now),
      viagemId: viagemId,
      pacienteId: pacienteId,
      nome: nome,
      necessidadeEspecial: necessidadeEspecial,
      embarque: embarque,
      desembarque: desembarque,
      acompanhante: acompanhante,
      acessibilidade: acessibilidade,
      telefone: telefone,
      enderecoEmbarque: enderecoEmbarque,
      cadeirante: cadeirante,
      mobilidadeReduzida: mobilidadeReduzida,
      acompanhanteObrigatorio: acompanhanteObrigatorio,
      observacoesEmbarque: observacoesEmbarque,
    );
    await _insertAndQueue(
      'transportes_passageiros',
      passageiro.sync.id,
      passageiro.toMap(),
    );
    return passageiro;
  }

  Future<SyncMetadata> _metadata(String municipioId, String now) async {
    return SyncMetadata(
      id: const Uuid().v4(),
      municipioId: municipioId,
      deviceId: await deviceIdService.getDeviceId(),
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<void> _insertAndQueue(
    String table,
    String entityId,
    Map<String, dynamic> payload,
  ) async {
    final db = await databaseHelper.database;
    await db.insert(
      table,
      payload,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await syncQueueRepository.enqueue(
      entityType: table,
      entityId: entityId,
      operation: 'upsert',
      payload: payload,
    );
  }

  Future<int> _count(Database db, String table) async {
    final result = await db.rawQuery('SELECT COUNT(*) AS total FROM $table');
    return result.first['total'] as int? ?? 0;
  }
}
