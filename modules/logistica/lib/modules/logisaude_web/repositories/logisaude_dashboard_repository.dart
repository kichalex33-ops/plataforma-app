import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../core/api/driver_api_client.dart';
import '../../../models/sync_queue_item_model.dart';
import '../../../repositories/sync_queue_repository.dart';
import '../../rastreamento/models/rastreamento_ponto_model.dart';
import '../../sync/models/sync_metadata.dart';
import '../../transportes/models/motorista_model.dart';
import '../../transportes/models/veiculo_model.dart';
import '../../transportes/models/viagem_model.dart';
import '../../transportes/models/viagem_status.dart';
import '../../pacientes/repositories/pacientes_repository.dart';
import '../../rastreamento/repositories/rastreamento_repository.dart';
import '../../transportes/repositories/transportes_repository.dart';
import '../models/logisaude_dashboard_data.dart';

class LogisaudeDashboardRepository {
  final TransportesRepository transportesRepository;
  final PacientesRepository pacientesRepository;
  final RastreamentoRepository rastreamentoRepository;
  final SyncQueueRepository syncQueueRepository;
  final DriverApiClient apiClient;

  LogisaudeDashboardRepository({
    TransportesRepository? transportesRepository,
    PacientesRepository? pacientesRepository,
    RastreamentoRepository? rastreamentoRepository,
    SyncQueueRepository? syncQueueRepository,
    DriverApiClient? apiClient,
  }) : transportesRepository = transportesRepository ?? TransportesRepository(),
       pacientesRepository = pacientesRepository ?? PacientesRepository(),
       rastreamentoRepository =
           rastreamentoRepository ?? RastreamentoRepository(),
       syncQueueRepository = syncQueueRepository ?? SyncQueueRepository(),
       apiClient = apiClient ?? DriverApiClient();

  Future<LogisaudeDashboardData> carregar() async {
    if (kIsWeb) {
      return _carregarWeb();
    }

    final viagens = await transportesRepository.listarViagens();
    final motoristas = await transportesRepository.listarMotoristas();
    final veiculos = await transportesRepository.listarVeiculos();
    final passageiros = await transportesRepository.listarPassageiros();
    final pacientes = await pacientesRepository.contar();
    final rastreamentos = await rastreamentoRepository.listarRecentes();
    final syncRecentes = await syncQueueRepository.listarRecentes(limit: 8);
    final syncPorStatus = await syncQueueRepository.contarPorStatus();
    final servidorOnline = await apiClient.testarConexao();

    return LogisaudeDashboardData(
      viagens: viagens,
      motoristas: motoristas,
      veiculos: veiculos,
      pacientes: pacientes,
      passageiros: passageiros.length,
      rastreamentos: rastreamentos,
      syncRecentes: syncRecentes,
      syncPorStatus: syncPorStatus,
      servidorOnline: servidorOnline,
      atualizadoEm: DateTime.now(),
    );
  }

  Future<LogisaudeDashboardData> _carregarWeb() async {
    final servidorOnline = await apiClient.testarConexao();
    final viagensApi = await apiClient.buscarLogisaudeViagens();
    final viagensDriverApi = await apiClient.buscarViagensMockadas();
    final motoristasApi = await apiClient.buscarLogisaudeMotoristas();
    final veiculosApi = await apiClient.buscarLogisaudeVeiculos();
    final pacientesApi = await apiClient.buscarLogisaudePacientes();
    final passageirosApi = await apiClient.buscarLogisaudePassageiros();
    final localizacoesApi = await apiClient.buscarLocalizacoesRecebidas();
    final eventosApi = await apiClient.buscarEventosRecebidos();
    final statusApi = await apiClient.buscarStatusViagensRecebidos();

    final viagensOrigem = viagensApi.isNotEmpty ? viagensApi : viagensDriverApi;
    final syncRecentes = <SyncQueueItemModel>[
      ...eventosApi.map((item) => _syncItemFromApi(item, 'driver_event')),
      ...statusApi.map((item) => _syncItemFromApi(item, 'driver_trip_status')),
    ].take(8).toList();

    // No Web administrativo não há SQLite local/sync_queue. Os contadores abaixo
    // representam dados recebidos pela API e preservam o painel sem depender do worker sqflite.
    final syncPorStatus = <String, int>{
      'pending': 0,
      'failed': 0,
      'synced': eventosApi.length + statusApi.length + localizacoesApi.length,
    };

    return LogisaudeDashboardData(
      viagens: viagensOrigem.map(_viagemFromApi).toList(),
      motoristas: motoristasApi.map(_motoristaFromApi).toList(),
      veiculos: veiculosApi.map(_veiculoFromApi).toList(),
      pacientes: pacientesApi.length,
      passageiros: passageirosApi.isNotEmpty
          ? passageirosApi.length
          : pacientesApi.length,
      rastreamentos: localizacoesApi.map(_rastreamentoFromApi).toList(),
      syncRecentes: syncRecentes,
      syncPorStatus: syncPorStatus,
      servidorOnline: servidorOnline,
      atualizadoEm: DateTime.now(),
    );
  }

  ViagemModel _viagemFromApi(Map<String, dynamic> map) {
    final now = DateTime.now().toIso8601String();
    return ViagemModel(
      sync: _syncFromApi(map, now),
      motoristaId: _stringValue(map, ['motorista_id', 'motoristaId']),
      veiculoId: _stringValue(map, ['veiculo_id', 'veiculoId']),
      origem: _stringValue(map, ['origem', 'from']) ?? 'Origem nao informada',
      destino: _stringValue(map, ['destino', 'to']) ?? 'Destino nao informado',
      dataHoraSaida:
          _stringValue(map, ['data_hora_saida', 'dataHoraSaida', 'horario']) ??
          now,
      dataHoraRetorno: _stringValue(map, [
        'data_hora_retorno',
        'dataHoraRetorno',
      ]),
      status: _normalizarStatus(_stringValue(map, ['status', 'situacao'])),
      finalidade: _stringValue(map, ['finalidade', 'especialidade']),
      observacoes: _stringValue(map, ['observacoes', 'descricao', 'nome']),
    );
  }

  MotoristaModel _motoristaFromApi(Map<String, dynamic> map) {
    return MotoristaModel(
      sync: _syncFromApi(map, DateTime.now().toIso8601String()),
      nome: _stringValue(map, ['nome', 'name', 'motorista']) ?? 'Motorista',
      cpf: _stringValue(map, ['cpf']),
      telefone: _stringValue(map, ['telefone', 'phone']),
      cnh: _stringValue(map, ['cnh']),
      status: _stringValue(map, ['status', 'situacao']) ?? 'ativo',
      observacoes: _stringValue(map, ['observacoes']),
    );
  }

  VeiculoModel _veiculoFromApi(Map<String, dynamic> map) {
    return VeiculoModel(
      sync: _syncFromApi(map, DateTime.now().toIso8601String()),
      placa: _stringValue(map, ['placa']) ?? '',
      modelo: _stringValue(map, ['modelo', 'nome', 'veiculo']) ?? 'Veiculo',
      tipo: _stringValue(map, ['tipo']) ?? 'transporte',
      capacidade: _intValue(map, ['capacidade']) ?? 0,
      status: _stringValue(map, ['status', 'situacao']) ?? 'ativo',
      observacoes: _stringValue(map, ['observacoes']),
    );
  }

  RastreamentoPontoModel _rastreamentoFromApi(Map<String, dynamic> map) {
    final now = DateTime.now().toIso8601String();
    return RastreamentoPontoModel(
      sync: _syncFromApi(map, now),
      viagemId:
          _stringValue(map, ['viagem_id', 'viagemId', 'tripId', 'trip_id']) ??
          'sem-viagem',
      latitude: _doubleValue(map, ['latitude', 'lat']) ?? 0,
      longitude: _doubleValue(map, ['longitude', 'lng', 'lon']) ?? 0,
      velocidade: _doubleValue(map, ['velocidade', 'speed']),
      timestamp:
          _stringValue(map, ['timestamp', 'horario', 'created_at']) ?? now,
      origemDado: _stringValue(map, ['origem_dado', 'origemDado']) ?? 'api',
    );
  }

  SyncQueueItemModel _syncItemFromApi(Map<String, dynamic> map, String type) {
    final now = DateTime.now().toIso8601String();
    final id = _stringValue(map, ['id']) ?? '$type-$now';
    return SyncQueueItemModel(
      id: id,
      entityType: type,
      entityId: _stringValue(map, ['entity_id', 'viagemId', 'tripId']) ?? id,
      operation: _stringValue(map, ['operation', 'tipo']) ?? 'received',
      payload: jsonEncode(map),
      checksum: _stringValue(map, ['checksum']) ?? '',
      status: 'synced',
      retryCount: 0,
      deviceId: _stringValue(map, ['device_id', 'deviceId']) ?? 'web-api',
      version: _intValue(map, ['version']) ?? 1,
      createdAt: _stringValue(map, ['created_at', 'timestamp']) ?? now,
      updatedAt: _stringValue(map, ['updated_at', 'timestamp']) ?? now,
      lastAttemptAt: _stringValue(map, ['last_attempt_at']),
      errorMessage: _stringValue(map, ['error_message', 'erro']),
    );
  }

  SyncMetadata _syncFromApi(Map<String, dynamic> map, String now) {
    return SyncMetadata(
      id: _stringValue(map, ['id']) ?? 'api-$now',
      municipioId: _stringValue(map, ['municipio_id', 'municipioId']) ?? 'web',
      deviceId: _stringValue(map, ['device_id', 'deviceId']),
      version: _intValue(map, ['version']) ?? 1,
      createdAt: _stringValue(map, ['created_at', 'createdAt']) ?? now,
      updatedAt: _stringValue(map, ['updated_at', 'updatedAt']) ?? now,
      syncStatus: _stringValue(map, ['sync_status', 'syncStatus']) ?? 'synced',
    );
  }

  String _normalizarStatus(String? value) {
    final status = value?.toLowerCase();
    if (status == null || status.isEmpty) return ViagemStatus.rascunho;
    if (status.contains('andamento') || status.contains('rota')) {
      return ViagemStatus.emAndamento;
    }
    if (status.contains('conclu')) return ViagemStatus.concluida;
    if (status.contains('cancel')) return ViagemStatus.cancelada;
    if (status.contains('atras')) return 'atrasada';
    return value!;
  }

  String? _stringValue(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return null;
  }

  int? _intValue(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value != null) return int.tryParse(value.toString());
    }
    return null;
  }

  double? _doubleValue(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is double) return value;
      if (value is num) return value.toDouble();
      if (value != null) return double.tryParse(value.toString());
    }
    return null;
  }
}
