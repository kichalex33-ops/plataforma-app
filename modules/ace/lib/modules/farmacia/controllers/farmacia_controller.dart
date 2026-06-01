import 'package:flutter/foundation.dart';

import '../models/medicamento_model.dart';
import '../repositories/farmacia_repository.dart';

class FarmaciaController extends ChangeNotifier {
  final FarmaciaRepository repository;

  FarmaciaController({FarmaciaRepository? repository})
    : repository = repository ?? FarmaciaRepository();

  Map<String, int> resumo = const {};
  List<MedicamentoModel> medicamentos = const [];
  bool carregando = false;

  Future<void> carregar() async {
    carregando = true;
    notifyListeners();
    resumo = await repository.resumo();
    medicamentos = await repository.listarMedicamentos();
    carregando = false;
    notifyListeners();
  }

  Future<void> criarMedicamento({
    required String nome,
    String? apresentacao,
    String? principioAtivo,
  }) async {
    await repository.criarMedicamento(
      municipioId: 'local',
      nome: nome,
      apresentacao: apresentacao,
      principioAtivo: principioAtivo,
    );
    await carregar();
  }
}
