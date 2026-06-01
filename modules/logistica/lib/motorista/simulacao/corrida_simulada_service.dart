import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../auth/motorista_model.dart';
import '../../core/api/driver_api_client.dart';

class CorridaSimuladaStatus {
  final bool rodando;
  final int enviados;
  final int falhas;
  final int segundosRestantes;
  final String? mensagem;

  const CorridaSimuladaStatus({
    required this.rodando,
    this.enviados = 0,
    this.falhas = 0,
    this.segundosRestantes = 0,
    this.mensagem,
  });

  int get minutosRestantes => (segundosRestantes / 60).ceil();

  String get resumo {
    if (!rodando) {
      return mensagem ?? 'Simulacao parada';
    }

    return 'Simulando viagem: $minutosRestantes min restantes | '
        'enviados: $enviados | falhas: $falhas';
  }
}

class CorridaSimuladaService extends ChangeNotifier {
  static const duracao = Duration(minutes: 5);
  static const intervalo = Duration(seconds: 10);

  final DriverApiClient apiClient;

  CorridaSimuladaService({DriverApiClient? apiClient})
    : apiClient = apiClient ?? DriverApiClient();

  Timer? _timer;
  DateTime? _fimEm;
  MotoristaModel? _motorista;
  String? _viagemId;
  int _tick = 0;
  int _enviados = 0;
  int _falhas = 0;
  bool _rodando = false;
  String? _mensagem;

  CorridaSimuladaStatus get status => CorridaSimuladaStatus(
    rodando: _rodando,
    enviados: _enviados,
    falhas: _falhas,
    segundosRestantes: _segundosRestantes(),
    mensagem: _mensagem,
  );

  Future<void> iniciar(MotoristaModel motorista) async {
    if (_rodando) return;

    _motorista = motorista;
    _viagemId = await _resolverViagemId();
    _tick = 0;
    _enviados = 0;
    _falhas = 0;
    _rodando = true;
    _fimEm = DateTime.now().add(duracao);
    _mensagem = 'Simulacao iniciada';
    debugPrint('[SYNC] simulacao corrida iniciada viagem=$_viagemId');
    notifyListeners();

    await _enviarInicio();
    await _enviarPonto();

    _timer = Timer.periodic(intervalo, (_) async {
      if (_segundosRestantes() <= 0) {
        await finalizar();
        return;
      }

      await _enviarPonto();
    });
  }

  Future<void> finalizar() async {
    if (!_rodando) return;

    _timer?.cancel();
    _timer = null;

    await _enviarFim();
    _rodando = false;
    _fimEm = null;
    _mensagem = 'Simulacao concluida';
    debugPrint(
      '[SYNC] simulacao corrida finalizada enviados=$_enviados falhas=$_falhas',
    );
    notifyListeners();
  }

  void cancelar() {
    _timer?.cancel();
    _timer = null;
    _rodando = false;
    _fimEm = null;
    _mensagem = 'Simulacao cancelada';
    debugPrint('[SYNC] simulacao corrida cancelada');
    notifyListeners();
  }

  Future<String> _resolverViagemId() async {
    final viagens = await apiClient.buscarViagensMockadas();
    if (viagens.isNotEmpty) {
      final id = viagens.first['id']?.toString();
      if (id != null && id.isNotEmpty) return id;
    }
    return 'viagem-simulada-${const Uuid().v4()}';
  }

  Future<void> _enviarInicio() async {
    await _enviarEvento('viagem_iniciada');
    await _enviarStatus('em_andamento');
  }

  Future<void> _enviarFim() async {
    await _enviarEvento('viagem_encerrada');
    await _enviarStatus('concluida');
  }

  Future<void> _enviarPonto() async {
    final motorista = _motorista;
    final viagemId = _viagemId;
    if (motorista == null || viagemId == null) return;

    final ponto = _pontoDaRota(_tick);
    final agora = DateTime.now().toIso8601String();
    final payload = {
      'id': const Uuid().v4(),
      'viagem_id': viagemId,
      'viagemId': viagemId,
      'motorista_id': motorista.id,
      'motoristaId': motorista.id,
      'motorista_nome': motorista.nome,
      'latitude': ponto.$1,
      'longitude': ponto.$2,
      'velocidade': 34 + (_tick % 5) * 3,
      'origem': 'app_motorista_simulacao_5min',
      'created_at': agora,
    };

    debugPrint('[API] simulacao POST localizacao tick=$_tick');
    await _contabilizar(apiClient.enviarLocalizacao(payload));

    if (_tick == 6 || _tick == 18) {
      await _enviarEvento(
        _tick == 6 ? 'chegada_confirmada' : 'embarque_confirmado',
      );
    }

    _tick++;
    notifyListeners();
  }

  Future<void> _enviarEvento(String tipo) async {
    final motorista = _motorista;
    final viagemId = _viagemId;
    if (motorista == null || viagemId == null) return;

    final agora = DateTime.now().toIso8601String();
    final payload = {
      'id': const Uuid().v4(),
      'viagem_id': viagemId,
      'motorista_id': motorista.id,
      'municipio_id': motorista.municipio,
      'tipo': tipo,
      'payload_json': '{"origem":"simulacao_corrida_5min"}',
      'created_at': agora,
      'sync_status': 'synced',
    };

    debugPrint('[EVENTO] simulacao POST evento tipo=$tipo');
    await _contabilizar(apiClient.enviarEvento(payload));
  }

  Future<void> _enviarStatus(String status) async {
    final motorista = _motorista;
    final viagemId = _viagemId;
    if (motorista == null || viagemId == null) return;

    final payload = {
      'id': const Uuid().v4(),
      'viagem_id': viagemId,
      'viagemId': viagemId,
      'motorista_id': motorista.id,
      'motoristaId': motorista.id,
      'status': status,
      'origem': 'app_motorista_simulacao_5min',
      'created_at': DateTime.now().toIso8601String(),
    };

    debugPrint('[API] simulacao POST status=$status');
    await _contabilizar(apiClient.enviarStatusViagem(payload));
  }

  Future<void> _contabilizar(Future<bool> envio) async {
    final ok = await envio;
    if (ok) {
      _enviados++;
    } else {
      _falhas++;
      _mensagem = 'Servidor offline ou indisponivel';
    }
    notifyListeners();
  }

  (double, double) _pontoDaRota(int tick) {
    const inicioLat = -29.4483;
    const inicioLng = -51.6715;
    const fimLat = -29.4676;
    const fimLng = -51.7008;
    final progresso = (tick / 30).clamp(0.0, 1.0);
    final oscilacao = tick.isEven ? 0.00018 : -0.00012;
    return (
      inicioLat + ((fimLat - inicioLat) * progresso) + oscilacao,
      inicioLng + ((fimLng - inicioLng) * progresso) - oscilacao,
    );
  }

  int _segundosRestantes() {
    final fim = _fimEm;
    if (fim == null) return 0;
    final restante = fim.difference(DateTime.now()).inSeconds;
    return restante < 0 ? 0 : restante;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
