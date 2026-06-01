import '../../auth/motorista_model.dart';
import '../../modules/transportes/models/viagem_model.dart';

class ViagemExecucaoRepository {
  Future<void> registrarPlaceholder({
    required ViagemModel viagem,
    required MotoristaModel motorista,
    required String tipo,
  }) async {
    // Eventos reais serao persistidos localmente na etapa de execucao offline.
  }
}
