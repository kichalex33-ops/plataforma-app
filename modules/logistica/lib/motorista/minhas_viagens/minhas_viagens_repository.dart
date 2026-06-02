import '../../database/database_helper.dart';
import '../../modules/transportes/models/viagem_model.dart';

class ViagemAtribuidaResumo {
  final int pacientes;
  final int acompanhantes;
  final bool possuiAcessibilidade;

  const ViagemAtribuidaResumo({
    this.pacientes = 0,
    this.acompanhantes = 0,
    this.possuiAcessibilidade = false,
  });
}

class MinhasViagensRepository {
  final DatabaseHelper databaseHelper;

  MinhasViagensRepository({DatabaseHelper? databaseHelper})
    : databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  Future<List<ViagemModel>> listarPorMotorista(String motoristaId) async {
    final db = await databaseHelper.database;
    final normalizado = motoristaId.trim();

    final filtradas = normalizado.isEmpty
        ? <Map<String, Object?>>[]
        : await db.query(
            'transportes_viagens',
            where: 'motorista_id = ?',
            whereArgs: [normalizado],
            orderBy: 'data_hora_saida ASC',
          );

    if (filtradas.isNotEmpty) {
      return filtradas.map(ViagemModel.fromMap).toList();
    }

    final fallback = await db.query(
      'transportes_viagens',
      where: 'motorista_id IS NULL OR motorista_id = ?',
      whereArgs: [''],
      orderBy: 'data_hora_saida ASC',
    );

    return fallback.map(ViagemModel.fromMap).toList();
  }

  Future<Map<String, ViagemAtribuidaResumo>> carregarResumos(
    List<ViagemModel> viagens,
  ) async {
    if (viagens.isEmpty) return const {};

    final db = await databaseHelper.database;
    final resultado = <String, ViagemAtribuidaResumo>{};

    for (final viagem in viagens) {
      final passageiros = await db.query(
        'transportes_passageiros',
        columns: [
          'acompanhante',
          'necessidade_especial',
          'acessibilidade',
          'cadeirante',
          'mobilidade_reduzida',
          'acompanhante_obrigatorio',
        ],
        where: 'viagem_id = ?',
        whereArgs: [viagem.sync.id],
      );

      var acompanhantes = 0;
      var acessibilidade = false;
      for (final passageiro in passageiros) {
        final isAcompanhante = _boolFromDb(passageiro['acompanhante']);
        if (isAcompanhante) acompanhantes++;

        acessibilidade =
            acessibilidade ||
            _boolFromDb(passageiro['cadeirante']) ||
            _boolFromDb(passageiro['mobilidade_reduzida']) ||
            _boolFromDb(passageiro['acompanhante_obrigatorio']) ||
            (passageiro['necessidade_especial']?.toString().trim().isNotEmpty ??
                false) ||
            (passageiro['acessibilidade']?.toString().trim().isNotEmpty ??
                false);
      }

      resultado[viagem.sync.id] = ViagemAtribuidaResumo(
        pacientes: passageiros.length,
        acompanhantes: acompanhantes,
        possuiAcessibilidade: acessibilidade,
      );
    }

    return resultado;
  }

  bool _boolFromDb(Object? value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) return value == '1' || value.toLowerCase() == 'true';
    return false;
  }
}
