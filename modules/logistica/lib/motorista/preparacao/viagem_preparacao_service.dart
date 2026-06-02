import 'package:uuid/uuid.dart';

import '../../auth/motorista_model.dart';
import '../../modules/transportes/models/viagem_model.dart';
import '../../modules/transportes/models/viagem_status.dart';
import 'models/viagem_preparacao_model.dart';

abstract class ViagemPreparacaoStore {
  Future<void> salvarPreparacao(ViagemPreparacaoModel preparacao);
  Future<void> atualizarEstadoViagem({
    required ViagemModel viagem,
    required String statusOperacional,
    String? statusLegado,
    double? kmSaida,
    String? horarioSaidaConfirmada,
  });
  Future<void> registrarEvento({
    required ViagemModel viagem,
    required MotoristaModel motorista,
    required String tipo,
    Map<String, dynamic> payload,
  });
}

class ViagemPreparacaoException implements Exception {
  final String message;

  const ViagemPreparacaoException(this.message);

  @override
  String toString() => message;
}

class ViagemPreparacaoService {
  final ViagemPreparacaoStore store;
  final Uuid uuid;

  ViagemPreparacaoService({
    required this.store,
    Uuid? uuid,
  }) : uuid = uuid ?? const Uuid();

  Future<ViagemPreparacaoModel> iniciarPreparacao({
    required ViagemModel viagem,
    required MotoristaModel motorista,
  }) async {
    final now = DateTime.now().toIso8601String();
    final preparacao = ViagemPreparacaoModel(
      id: uuid.v4(),
      municipioId: viagem.sync.municipioId,
      viagemId: viagem.sync.id,
      motoristaId: motorista.id,
      veiculoId: viagem.veiculoId,
      horarioPreparacao: now,
      status: ViagemStatus.preparacao,
    );

    await store.salvarPreparacao(preparacao);
    await store.atualizarEstadoViagem(
      viagem: viagem,
      statusOperacional: ViagemStatus.preparacao,
    );
    await store.registrarEvento(
      viagem: viagem,
      motorista: motorista,
      tipo: 'preparacao_iniciada',
      payload: {'preparacao_id': preparacao.id},
    );

    return preparacao;
  }

  Future<ViagemPreparacaoModel> confirmarSaida({
    required ViagemModel viagem,
    required MotoristaModel motorista,
    required ViagemPreparacaoModel preparacao,
    required double? kmInicial,
    required Map<String, bool> checklist,
  }) async {
    validarSaida(kmInicial: kmInicial, checklist: checklist);

    final now = DateTime.now().toIso8601String();
    final atualizada = preparacao.copyWith(
      kmInicial: kmInicial,
      checklistConcluido: true,
      checklist: checklist,
      horarioSaida: now,
      status: ViagemStatus.saidaConfirmada,
    );

    await store.salvarPreparacao(atualizada);
    await store.atualizarEstadoViagem(
      viagem: viagem,
      statusOperacional: ViagemStatus.saidaConfirmada,
      statusLegado: ViagemStatus.emAndamento,
      kmSaida: kmInicial,
      horarioSaidaConfirmada: now,
    );
    await store.registrarEvento(
      viagem: viagem,
      motorista: motorista,
      tipo: 'saida_confirmada',
      payload: {
        'preparacao_id': preparacao.id,
        'km_inicial': kmInicial,
        'checklist': checklist,
      },
    );

    return atualizada;
  }

  Future<void> iniciarTransitoIda({
    required ViagemModel viagem,
    required MotoristaModel motorista,
  }) async {
    await store.atualizarEstadoViagem(
      viagem: viagem,
      statusOperacional: ViagemStatus.emTransitoIda,
      statusLegado: ViagemStatus.emAndamento,
    );
    await store.registrarEvento(
      viagem: viagem,
      motorista: motorista,
      tipo: 'rota_ida_iniciada',
    );
  }

  void validarSaida({
    required double? kmInicial,
    required Map<String, bool> checklist,
  }) {
    if (kmInicial == null || kmInicial <= 0) {
      throw const ViagemPreparacaoException('Informe o KM inicial.');
    }

    if (checklist.isEmpty || checklist.values.any((value) => !value)) {
      throw const ViagemPreparacaoException(
        'Conclua o checklist pre-uso antes de confirmar a saida.',
      );
    }
  }
}
