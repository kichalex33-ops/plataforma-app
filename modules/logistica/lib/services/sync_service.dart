import 'package:http/http.dart' as http;

import '../database/database_helper.dart';

class SyncResult {
  final int enviados;
  final int falhas;
  final String? erro;

  const SyncResult({required this.enviados, required this.falhas, this.erro});

  bool get sucesso => falhas == 0 && erro == null;
}

class SyncTestResult {
  final bool conectado;
  final String servidorUrl;
  final String? erro;

  const SyncTestResult({
    required this.conectado,
    required this.servidorUrl,
    this.erro,
  });
}

class SyncService {
  static const chaveServidorUrl = 'servidor_url';
  static const chaveUltimaSincronizacao = 'ultima_sincronizacao';
  static const servidorPadrao = String.fromEnvironment(
    'Logistica_SERVER_URL',
    defaultValue: 'http://10.0.0.4:3000',
  );

  final DatabaseHelper database;
  final String servidorUrl;

  SyncService({DatabaseHelper? database, String? servidorUrl})
    : database = database ?? DatabaseHelper.instance,
      servidorUrl = servidorUrl ?? servidorPadrao;

  static Future<String> carregarServidorUrl({DatabaseHelper? database}) async {
    final db = database ?? DatabaseHelper.instance;
    final salvo = await db.carregarValorConfiguracao(chaveServidorUrl);
    if (salvo == null || salvo.trim().isEmpty) return servidorPadrao;
    return normalizarServidorUrl(salvo);
  }

  static Future<void> salvarServidorUrl(
    String valor, {
    DatabaseHelper? database,
  }) async {
    final db = database ?? DatabaseHelper.instance;
    await db.salvarValorConfiguracao(
      chaveServidorUrl,
      normalizarServidorUrl(valor),
    );
  }

  static Future<void> salvarUltimaSincronizacao(
    DateTime data, {
    DatabaseHelper? database,
  }) async {
    final db = database ?? DatabaseHelper.instance;
    await db.salvarValorConfiguracao(
      chaveUltimaSincronizacao,
      data.toIso8601String(),
    );
  }

  static Future<String?> carregarUltimaSincronizacao({
    DatabaseHelper? database,
  }) async {
    final db = database ?? DatabaseHelper.instance;
    return db.carregarValorConfiguracao(chaveUltimaSincronizacao);
  }

  static String normalizarServidorUrl(String valor) {
    var texto = valor.trim();
    if (texto.isEmpty) return servidorPadrao;

    if (!texto.startsWith('http://') && !texto.startsWith('https://')) {
      texto = 'http://$texto';
    }

    while (texto.endsWith('/')) {
      texto = texto.substring(0, texto.length - 1);
    }

    return texto;
  }

  static Future<bool> testarConexao(String servidorUrl) async {
    final resultado = await testarConexaoDetalhada(servidorUrl);
    return resultado.conectado;
  }

  static Future<SyncTestResult> testarConexaoDetalhada(
    String servidorUrl,
  ) async {
    final url = normalizarServidorUrl(servidorUrl);
    final servico = SyncService(servidorUrl: url);

    try {
      await servico._testarServidor();
      return SyncTestResult(conectado: true, servidorUrl: url);
    } catch (error) {
      return SyncTestResult(
        conectado: false,
        servidorUrl: url,
        erro: error.toString(),
      );
    }
  }

  static Future<SyncService> configurado({DatabaseHelper? database}) async {
    final db = database ?? DatabaseHelper.instance;
    final servidorUrl = await carregarServidorUrl(database: db);
    return SyncService(database: db, servidorUrl: servidorUrl);
  }

  Future<SyncResult> sincronizarPendentes() async {
    try {
      await _testarServidor();
      await salvarUltimaSincronizacao(DateTime.now(), database: database);
      return const SyncResult(enviados: 0, falhas: 0);
    } catch (error) {
      return SyncResult(enviados: 0, falhas: 0, erro: error.toString());
    }
  }

  Future<void> _testarServidor() async {
    final uri = Uri.parse('$servidorUrl/api/status');
    final response = await http.get(uri).timeout(const Duration(seconds: 8));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Servidor respondeu ${response.statusCode}.');
    }
  }
}
