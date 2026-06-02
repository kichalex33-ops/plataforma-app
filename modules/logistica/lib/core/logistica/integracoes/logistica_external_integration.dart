import 'dart:convert';

import 'package:uuid/uuid.dart';

enum LogisticaExternalDestination {
  seguradora,
  guincho,
  assistenciaTecnica,
  manutencao,
  centralExterna,
}

enum LogisticaExternalDispatchStatus {
  aguardandoEnvio,
  enviado,
  recebido,
  confirmado,
  emAtendimento,
  concluido,
  erro,
}

class LogisticaExternalDispatchItem {
  final String id;
  final LogisticaExternalDestination destination;
  final String tipoEvento;
  final String payloadJson;
  final LogisticaExternalDispatchStatus status;
  final int attempts;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastAttemptAt;
  final String? error;

  const LogisticaExternalDispatchItem({
    required this.id,
    required this.destination,
    required this.tipoEvento,
    required this.payloadJson,
    required this.status,
    required this.attempts,
    required this.createdAt,
    required this.updatedAt,
    this.lastAttemptAt,
    this.error,
  });

  Map<String, dynamic> get payload =>
      jsonDecode(payloadJson) as Map<String, dynamic>;

  LogisticaExternalDispatchItem copyWith({
    LogisticaExternalDispatchStatus? status,
    int? attempts,
    DateTime? updatedAt,
    DateTime? lastAttemptAt,
    String? error,
    bool clearError = false,
  }) {
    return LogisticaExternalDispatchItem(
      id: id,
      destination: destination,
      tipoEvento: tipoEvento,
      payloadJson: payloadJson,
      status: status ?? this.status,
      attempts: attempts ?? this.attempts,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class LogisticaExternalIntegrationLog {
  final String id;
  final String dispatchId;
  final LogisticaExternalDestination destination;
  final LogisticaExternalDispatchStatus status;
  final String message;
  final DateTime createdAt;

  const LogisticaExternalIntegrationLog({
    required this.id,
    required this.dispatchId,
    required this.destination,
    required this.status,
    required this.message,
    required this.createdAt,
  });
}

class LogisticaWebhookSimulationGateway {
  final int failuresBeforeSuccess;
  int _attempts = 0;

  LogisticaWebhookSimulationGateway({this.failuresBeforeSuccess = 0});

  Future<LogisticaWebhookSimulationResult> send(
    LogisticaExternalDispatchItem item,
  ) async {
    _attempts += 1;
    if (_attempts <= failuresBeforeSuccess) {
      return const LogisticaWebhookSimulationResult.failure(
        'falha simulada de integracao externa',
      );
    }
    return const LogisticaWebhookSimulationResult.success();
  }
}

class LogisticaWebhookSimulationResult {
  final bool sent;
  final String? error;

  const LogisticaWebhookSimulationResult.success()
      : sent = true,
        error = null;

  const LogisticaWebhookSimulationResult.failure(this.error) : sent = false;
}

class LogisticaExternalDispatchQueue {
  final LogisticaWebhookSimulationGateway gateway;
  final Uuid uuid;
  final List<LogisticaExternalDispatchItem> _items = [];
  final List<LogisticaExternalIntegrationLog> _logs = [];

  LogisticaExternalDispatchQueue({
    required this.gateway,
    this.uuid = const Uuid(),
  });

  List<LogisticaExternalDispatchItem> get items => List.unmodifiable(_items);
  List<LogisticaExternalIntegrationLog> get logs => List.unmodifiable(_logs);

  LogisticaExternalDispatchItem enqueue({
    required LogisticaExternalDestination destino,
    required String tipoEvento,
    required Map<String, dynamic> payload,
    DateTime? createdAt,
  }) {
    final now = createdAt ?? DateTime.now();
    final item = LogisticaExternalDispatchItem(
      id: uuid.v4(),
      destination: destino,
      tipoEvento: tipoEvento,
      payloadJson: jsonEncode(payload),
      status: LogisticaExternalDispatchStatus.aguardandoEnvio,
      attempts: 0,
      createdAt: now,
      updatedAt: now,
    );
    _items.add(item);
    _addLog(item, 'Item aguardando envio para ${destino.name}.', now);
    return item;
  }

  Future<LogisticaExternalDispatchItem> processNext({DateTime? now}) async {
    final index = _items.indexWhere(
      (item) =>
          item.status == LogisticaExternalDispatchStatus.aguardandoEnvio ||
          item.status == LogisticaExternalDispatchStatus.erro,
    );
    if (index == -1) {
      throw StateError('Nenhum item pendente para envio externo.');
    }

    final timestamp = now ?? DateTime.now();
    final current = _items[index];
    final result = await gateway.send(current);
    final updated = current.copyWith(
      status: result.sent
          ? LogisticaExternalDispatchStatus.enviado
          : LogisticaExternalDispatchStatus.erro,
      attempts: current.attempts + 1,
      updatedAt: timestamp,
      lastAttemptAt: timestamp,
      error: result.error,
      clearError: result.sent,
    );
    _items[index] = updated;
    _addLog(
      updated,
      result.sent
          ? 'Envio simulado concluido.'
          : 'Envio simulado falhou: ${result.error}.',
      timestamp,
    );
    return updated;
  }

  void _addLog(
    LogisticaExternalDispatchItem item,
    String message,
    DateTime createdAt,
  ) {
    _logs.add(
      LogisticaExternalIntegrationLog(
        id: uuid.v4(),
        dispatchId: item.id,
        destination: item.destination,
        status: item.status,
        message: message,
        createdAt: createdAt,
      ),
    );
  }
}

enum LogisticaWhatsappUseCase {
  avisoMotorista,
  avisoUnidadeSaude,
  confirmacaoPassageiro,
  alertaGestor,
  comunicacaoOcorrencia,
}

class LogisticaWhatsappSimulationMessage {
  final String id;
  final LogisticaWhatsappUseCase casoUso;
  final String destinatario;
  final String mensagem;
  final bool simulado;
  final bool disparoRealExecutado;
  final DateTime createdAt;

  const LogisticaWhatsappSimulationMessage({
    required this.id,
    required this.casoUso,
    required this.destinatario,
    required this.mensagem,
    required this.simulado,
    required this.disparoRealExecutado,
    required this.createdAt,
  });
}

class LogisticaWhatsappSimulationService {
  final Uuid uuid;
  final List<LogisticaWhatsappSimulationMessage> _messages = [];
  final List<LogisticaExternalIntegrationLog> _logs = [];

  LogisticaWhatsappSimulationService({this.uuid = const Uuid()});

  List<LogisticaWhatsappSimulationMessage> get messages =>
      List.unmodifiable(_messages);
  List<LogisticaExternalIntegrationLog> get logs => List.unmodifiable(_logs);

  LogisticaWhatsappSimulationMessage registrarMensagem({
    required LogisticaWhatsappUseCase casoUso,
    required String destinatario,
    required String mensagem,
    DateTime? now,
  }) {
    final timestamp = now ?? DateTime.now();
    final message = LogisticaWhatsappSimulationMessage(
      id: uuid.v4(),
      casoUso: casoUso,
      destinatario: destinatario,
      mensagem: mensagem,
      simulado: true,
      disparoRealExecutado: false,
      createdAt: timestamp,
    );
    _messages.add(message);
    _logs.add(
      LogisticaExternalIntegrationLog(
        id: uuid.v4(),
        dispatchId: message.id,
        destination: LogisticaExternalDestination.centralExterna,
        status: LogisticaExternalDispatchStatus.concluido,
        message: 'WhatsApp simulado registrado para ${casoUso.name}.',
        createdAt: timestamp,
      ),
    );
    return message;
  }
}
