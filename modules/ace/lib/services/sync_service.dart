import 'dart:convert';

import 'package:http/http.dart' as http;

import '../database/database_helper.dart';
import '../models/pe_model.dart';

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
    'ACE_SERVER_URL',
    defaultValue: 'http://10.0.0.3:3000',
  );

  static const Map<String, String> _rotas = {
    'pontos_estrategicos': '/api/pes',
    'visitas_pe': '/api/visitas-pe',
    'visitas_domiciliares': '/api/visitas-domiciliares',
    'bti_aplicacoes': '/api/bti',
    'bti_pontos': '/api/bti-pontos',
    'ovitrampas': '/api/ovitrampas',
    'ovitrampa_checagens': '/api/ovitrampas/checagens',
    'areas_prioritarias': '/api/areas-prioritarias',
    'lira_lia_visitas': '/api/lira-lia',
    'quarteiroes': '/api/quarteiroes',
    'atividades_quarteirao': '/api/atividades-quarteirao',
    'exclusoes_log': '/api/exclusoes-log',
    'alertas_emergencia': '/api/alertas-emergencia',
  };

  final DatabaseHelper database;
  final String servidorUrl;

  SyncService({DatabaseHelper? database, String? servidorUrl})
    : database = database ?? DatabaseHelper.instance,
      servidorUrl = servidorUrl ?? servidorPadrao;

  static Future<String> carregarServidorUrl({DatabaseHelper? database}) async {
    final db = database ?? DatabaseHelper.instance;
    final salvo = await db.carregarValorConfiguracao(chaveServidorUrl);
    if (salvo == null || salvo.trim().isEmpty) return servidorPadrao;

    final normalizado = normalizarServidorUrl(salvo);
    if (normalizado.contains('10.10.11.119')) {
      await salvarServidorUrl(servidorPadrao, database: db);
      return servidorPadrao;
    }

    return normalizado;
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
    var enviados = 0;
    var falhas = 0;

    try {
      await _testarServidor();

      for (final entrada in _rotas.entries) {
        final tabela = entrada.key;
        final rota = entrada.value;
        final pendentes = await database.listarPendentesSincronizacao(tabela);

        for (final registro in pendentes) {
          final id = registro['id'] as int?;
          if (id == null) continue;

          try {
            await _enviar(rota, _normalizarPayload(tabela, registro));
            await database.marcarSincronizado(
              tabela: tabela,
              id: id,
              sincronizadoEm: DateTime.now().toIso8601String(),
            );
            enviados++;
          } catch (error) {
            falhas++;
            await database.marcarErroSincronizacao(
              tabela: tabela,
              id: id,
              erro: error.toString(),
            );
          }
        }
      }

      await salvarUltimaSincronizacao(DateTime.now(), database: database);

      return SyncResult(enviados: enviados, falhas: falhas);
    } catch (error) {
      return SyncResult(
        enviados: enviados,
        falhas: falhas,
        erro: error.toString(),
      );
    }
  }

  Future<void> _testarServidor() async {
    final uri = Uri.parse('$servidorUrl/api/status');
    final response = await http.get(uri).timeout(const Duration(seconds: 8));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Servidor respondeu ${response.statusCode}.');
    }
  }

  Future<void> _enviar(String rota, Map<String, dynamic> payload) async {
    final uri = Uri.parse('$servidorUrl$rota');
    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json; charset=utf-8'},
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Falha ${response.statusCode}: ${response.body}');
    }
  }

  Future<int?> reservarTubitos({
    required int quantidade,
    required String municipio,
    required String agente,
  }) async {
    if (quantidade <= 0) return null;

    final uri = Uri.parse('$servidorUrl/api/tubitos/reservar');
    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json; charset=utf-8'},
          body: jsonEncode({
            'quantidade': quantidade,
            'municipio': municipio,
            'ace_responsavel': agente,
          }),
        )
        .timeout(const Duration(seconds: 8));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Falha ${response.statusCode}: ${response.body}');
    }

    final dados = jsonDecode(response.body) as Map<String, dynamic>;
    final primeiro = dados['primeiro_numero'];
    if (primeiro is num) return primeiro.toInt();

    return int.tryParse('$primeiro');
  }

  Future<void> enviarPE(PEModel pe) async {
    await _enviar(
      '/api/pes',
      _normalizarPayload('pontos_estrategicos', pe.toMap()),
    );
  }

  Future<void> enviarVisitaPE(Map<String, dynamic> visita) async {
    await _enviar('/api/visitas-pe', _normalizarPayload('visitas_pe', visita));
  }

  Map<String, dynamic> _normalizarPayload(
    String tabela,
    Map<String, dynamic> registro,
  ) {
    final payload = Map<String, dynamic>.from(registro);
    payload['origem'] = 'app_flutter_offline';

    if (payload['agente'] != null) {
      payload['ace_responsavel'] = payload['agente'];
    }

    if (tabela == 'pontos_estrategicos') {
      payload['ultimaVisita'] = payload['ultima_visita'];
    }

    if (tabela == 'visitas_pe') {
      payload['data'] = payload['data_visita'];
      payload['hora'] = _extrairHora(
        payload['saida_em'] ?? payload['entrada_em'],
      );
      payload['status'] = payload['situacao'];
      payload['latitude'] = payload['saida_latitude'] ?? payload['latitude'];
      payload['longitude'] = payload['saida_longitude'] ?? payload['longitude'];
      payload['foco_positivo'] = payload['foco_positivo'] == 1;
    }

    if (tabela == 'visitas_domiciliares') {
      payload['data'] = _extrairData(payload['saida_em']);
      payload['hora'] = _extrairHora(payload['saida_em']);
      payload['status'] = payload['situacao'];
      payload['latitude'] = payload['saida_latitude'];
      payload['longitude'] = payload['saida_longitude'];
      payload['foco_positivo'] = payload['foco_positivo'] == 1;
    }

    if (tabela == 'bti_aplicacoes') {
      payload['data'] = payload['data_aplicacao'];
      payload['status'] = 'Aplicado';
      payload['tipo'] = payload['tipo_criadouro'];
    }

    if (tabela == 'bti_pontos') {
      payload['tipo'] = 'Ponto BTI';
      payload['status'] = 'Cadastrado';
      payload['observacoes'] = payload['descricao'];
      payload['origem'] = 'ponto_bti_app';
    }

    if (tabela == 'ovitrampas') {
      payload['data'] = _extrairData(payload['instalada_em']);
      payload['hora'] = _extrairHora(payload['instalada_em']);
      payload['ace_responsavel'] = payload['agente_instalacao'];
      payload['tipo'] = 'Ovitrampa';
    }

    if (tabela == 'ovitrampa_checagens') {
      payload['data'] = _extrairData(payload['data_checagem']);
      payload['hora'] = _extrairHora(payload['data_checagem']);
      payload['ace_responsavel'] = payload['agente'];
      payload['status'] = payload['resultado'];
      payload['tipo'] = 'Checagem de ovitrampa';
    }

    if (tabela == 'areas_prioritarias') {
      payload['data'] = payload['data_registro'];
      payload['ace_responsavel'] = payload['agente'];
      payload['tipo'] = payload['tipo_risco'];
      payload['origem'] = 'area_prioritaria_app';
    }

    if (tabela == 'lira_lia_visitas') {
      final focos = payload['focos_positivos'];
      final totalFocos = focos is num ? focos : int.tryParse('$focos') ?? 0;

      payload['data'] = payload['data_registro'];
      payload['ace_responsavel'] = payload['agente'];
      payload['tipo'] = payload['tipo_levantamento'];
      payload['status'] = totalFocos > 0 ? 'Com foco' : 'Sem foco';
      payload['origem'] = 'lira_lia_app';
    }

    if (tabela == 'quarteiroes') {
      payload['tipo'] = 'Quarteirao';
      payload['status'] = payload['status_trabalho'];
      payload['origem'] = 'quarteirao_app';
    }

    if (tabela == 'atividades_quarteirao') {
      payload['data'] = payload['data_atividade'];
      payload['ace_responsavel'] = payload['agente'];
      payload['tipo'] = payload['atividade'];
      payload['status'] = payload['resultado_coletas'];
      payload['origem'] = 'atividade_quarteirao_app';
    }

    if (tabela == 'exclusoes_log') {
      payload['data'] = payload['data_hora'];
      payload['hora'] = _extrairHora(payload['data_hora']);
      payload['ace_responsavel'] = payload['agente'];
      payload['tipo'] = payload['entidade'];
      payload['status'] = 'Excluido';
      payload['origem'] = 'exclusao_app';
    }

    if (tabela == 'alertas_emergencia') {
      payload['data'] = payload['data_hora'];
      payload['hora'] = _extrairHora(payload['data_hora']);
      payload['ace_responsavel'] = payload['agente'];
      payload['tipo'] = 'Alerta de emergencia';
      payload['origem'] = 'alerta_emergencia_app';
    }

    return payload;
  }

  String? _extrairData(dynamic valor) {
    final texto = valor?.toString();
    if (texto == null || texto.isEmpty) return null;

    final data = DateTime.tryParse(texto);
    if (data != null) return data.toIso8601String().substring(0, 10);

    if (texto.length >= 10) return texto.substring(0, 10);
    return texto;
  }

  String? _extrairHora(dynamic valor) {
    final texto = valor?.toString();
    if (texto == null || texto.isEmpty) return null;

    final data = DateTime.tryParse(texto);
    if (data != null) {
      return '${data.hour.toString().padLeft(2, '0')}:'
          '${data.minute.toString().padLeft(2, '0')}';
    }

    final partes = texto.split(' ');
    if (partes.length > 1) return partes.last;
    return null;
  }
}
