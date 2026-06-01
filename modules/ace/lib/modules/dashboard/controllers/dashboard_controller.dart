import 'package:flutter/foundation.dart';

import '../models/plataforma_indicadores.dart';
import '../repositories/dashboard_repository.dart';

class PlataformaDashboardController extends ChangeNotifier {
  final PlataformaDashboardRepository repository;

  PlataformaDashboardController({PlataformaDashboardRepository? repository})
    : repository = repository ?? PlataformaDashboardRepository();

  PlataformaIndicadores? indicadores;
  bool carregando = false;

  Future<void> carregar() async {
    carregando = true;
    notifyListeners();
    indicadores = await repository.carregar();
    carregando = false;
    notifyListeners();
  }
}
