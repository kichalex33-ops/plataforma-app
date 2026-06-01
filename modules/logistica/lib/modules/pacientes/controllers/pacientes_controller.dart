import 'package:flutter/foundation.dart';

import '../models/paciente_model.dart';
import '../repositories/pacientes_repository.dart';

class PacientesController extends ChangeNotifier {
  final PacientesRepository repository;

  PacientesController({PacientesRepository? repository})
    : repository = repository ?? PacientesRepository();

  int total = 0;
  List<PacienteModel> pacientes = const [];
  bool carregando = false;

  Future<void> carregar() async {
    carregando = true;
    notifyListeners();
    total = await repository.contar();
    pacientes = await repository.listar();
    carregando = false;
    notifyListeners();
  }

  Future<void> criar({
    required String nome,
    String? telefone,
    String? endereco,
    String? necessidadesEspeciais,
  }) async {
    await repository.criar(
      municipioId: 'local',
      nome: nome,
      telefone: telefone,
      endereco: endereco,
      necessidadesEspeciais: necessidadesEspeciais,
    );
    await carregar();
  }
}
