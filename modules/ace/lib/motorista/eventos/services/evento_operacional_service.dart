import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../../../auth/motorista_model.dart';
import '../../../modules/transportes/models/viagem_model.dart';
import '../models/evento_operacional_model.dart';
import '../repositories/evento_operacional_repository.dart';

class EventoOperacionalService {
  final EventoOperacionalRepository repository;

  EventoOperacionalService({EventoOperacionalRepository? repository})
    : repository = repository ?? EventoOperacionalRepository();

  Future<EventoOperacionalModel> registrar({
    required ViagemModel viagem,
    required MotoristaModel motorista,
    required String tipo,
    Map<String, dynamic> payload = const {},
    double? latitude,
    double? longitude,
  }) async {
    final now = DateTime.now().toIso8601String();
    final evento = EventoOperacionalModel(
      id: const Uuid().v4(),
      viagemId: viagem.sync.id,
      motoristaId: motorista.id,
      municipioId: motorista.municipio,
      tipo: tipo,
      payloadJson: jsonEncode({
        'viagem_id': viagem.sync.id,
        'motorista_id': motorista.id,
        ...payload,
      }),
      latitude: latitude,
      longitude: longitude,
      createdAt: now,
    );

    await repository.salvar(evento);
    return evento;
  }

  Future<List<EventoOperacionalModel>> listarPendentes() {
    return repository.listarPendentes();
  }
}
