import 'package:flutter/foundation.dart';

import '../../auth/motorista_model.dart';
import '../../motorista/eventos/services/evento_operacional_service.dart';
import '../../modules/transportes/models/viagem_model.dart';

class ViagemExecucaoController extends ChangeNotifier {
  final EventoOperacionalService service;

  ViagemExecucaoController({EventoOperacionalService? service})
    : service = service ?? EventoOperacionalService();

  bool processando = false;
  String? erro;

  Future<void> registrarAcao({
    required ViagemModel viagem,
    required MotoristaModel motorista,
    required String tipo,
  }) async {
    processando = true;
    erro = null;
    notifyListeners();

    try {
      await service.registrar(viagem: viagem, motorista: motorista, tipo: tipo);
    } catch (error) {
      erro = error.toString();
    } finally {
      processando = false;
      notifyListeners();
    }
  }
}
