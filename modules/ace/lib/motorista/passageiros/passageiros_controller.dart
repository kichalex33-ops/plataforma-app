import 'package:flutter/foundation.dart';

import '../../auth/motorista_model.dart';
import '../../motorista/eventos/services/evento_operacional_service.dart';
import '../../modules/transportes/models/passageiro_model.dart';
import '../../modules/transportes/models/viagem_model.dart';
import 'passageiros_repository.dart';

class PassageirosController extends ChangeNotifier {
  final PassageirosRepository repository;
  final EventoOperacionalService eventosService;

  PassageirosController({
    PassageirosRepository? repository,
    EventoOperacionalService? eventosService,
  }) : repository = repository ?? PassageirosRepository(),
       eventosService = eventosService ?? EventoOperacionalService();

  bool carregando = false;
  List<PassageiroModel> passageiros = const [];
  String? erro;
  final Map<String, String> operacoesLocais = {};
  final Map<String, String> observacoesLocais = {};

  Future<void> carregar(String viagemId) async {
    carregando = true;
    erro = null;
    notifyListeners();

    try {
      passageiros = await repository.listarPorViagem(viagemId);
    } catch (error) {
      erro = error.toString();
      passageiros = const [];
    } finally {
      carregando = false;
      notifyListeners();
    }
  }

  Future<void> registrarOperacao({
    required ViagemModel viagem,
    required MotoristaModel motorista,
    required PassageiroModel passageiro,
    required String operacao,
  }) async {
    await eventosService.registrar(
      viagem: viagem,
      motorista: motorista,
      tipo: operacao,
      payload: {
        'passageiro_id': passageiro.sync.id,
        'passageiro_nome': passageiro.nome,
      },
    );
    final passageiroId = passageiro.sync.id;
    operacoesLocais[passageiroId] = operacao;
    notifyListeners();
  }

  Future<void> registrarObservacao({
    required ViagemModel viagem,
    required MotoristaModel motorista,
    required PassageiroModel passageiro,
    required String observacao,
    required String operacao,
  }) async {
    await eventosService.registrar(
      viagem: viagem,
      motorista: motorista,
      tipo: operacao,
      payload: {
        'passageiro_id': passageiro.sync.id,
        'passageiro_nome': passageiro.nome,
        'observacao': observacao,
      },
    );
    final passageiroId = passageiro.sync.id;
    observacoesLocais[passageiroId] = observacao;
    operacoesLocais[passageiroId] = operacao;
    notifyListeners();
  }
}
