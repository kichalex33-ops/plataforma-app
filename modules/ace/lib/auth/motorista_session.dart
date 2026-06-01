import 'dart:convert';

import '../database/database_helper.dart';
import 'motorista_model.dart';

class MotoristaSession {
  static const chaveSessao = 'motorista_session';

  final DatabaseHelper databaseHelper;

  MotoristaSession({DatabaseHelper? databaseHelper})
    : databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  Future<void> salvar(MotoristaModel motorista) async {
    await databaseHelper.salvarValorConfiguracao(
      chaveSessao,
      jsonEncode(motorista.toMap()),
    );
    await databaseHelper.salvarConfiguracao(
      municipio: motorista.municipio,
      agente: motorista.nome,
    );
  }

  Future<MotoristaModel?> carregar() async {
    final valor = await databaseHelper.carregarValorConfiguracao(chaveSessao);
    if (valor == null || valor.trim().isEmpty) return null;

    final dados = jsonDecode(valor) as Map<String, dynamic>;
    return MotoristaModel.fromMap(dados);
  }

  Future<void> limpar() async {
    await databaseHelper.salvarValorConfiguracao(chaveSessao, '');
  }
}
