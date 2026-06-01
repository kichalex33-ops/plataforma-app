import 'dart:convert';

class EventoOperacionalTipo {
  static const viagemRecebida = 'viagem_recebida';
  static const viagemAceita = 'viagem_aceita';
  static const checklistSaidaConfirmado = 'checklist_saida_confirmado';
  static const viagemIniciada = 'viagem_iniciada';
  static const embarqueConfirmado = 'embarque_confirmado';
  static const passageiroAusente = 'passageiro_ausente';
  static const chegadaConfirmada = 'chegada_confirmada';
  static const ocorrenciaRegistrada = 'ocorrencia_registrada';
  static const localizacaoEnviada = 'localizacao_enviada';
  static const viagemEncerrada = 'viagem_encerrada';
  static const syncExecutado = 'sync_executado';

  static const todos = [
    viagemRecebida,
    viagemAceita,
    checklistSaidaConfirmado,
    viagemIniciada,
    embarqueConfirmado,
    passageiroAusente,
    chegadaConfirmada,
    ocorrenciaRegistrada,
    localizacaoEnviada,
    viagemEncerrada,
    syncExecutado,
  ];
}

class EventoOperacionalModel {
  final String id;
  final String viagemId;
  final String motoristaId;
  final String municipioId;
  final String tipo;
  final String payloadJson;
  final double? latitude;
  final double? longitude;
  final String createdAt;
  final String syncStatus;

  const EventoOperacionalModel({
    required this.id,
    required this.viagemId,
    required this.motoristaId,
    required this.municipioId,
    required this.tipo,
    required this.payloadJson,
    this.latitude,
    this.longitude,
    required this.createdAt,
    this.syncStatus = 'pending',
  });

  Map<String, dynamic> get payload {
    final decoded = jsonDecode(payloadJson);
    if (decoded is Map<String, dynamic>) return decoded;
    return {'valor': decoded};
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'viagem_id': viagemId,
    'motorista_id': motoristaId,
    'municipio_id': municipioId,
    'tipo': tipo,
    'payload_json': payloadJson,
    'latitude': latitude,
    'longitude': longitude,
    'created_at': createdAt,
    'sync_status': syncStatus,
  };

  factory EventoOperacionalModel.fromMap(Map<String, dynamic> map) {
    return EventoOperacionalModel(
      id: map['id']?.toString() ?? '',
      viagemId: map['viagem_id']?.toString() ?? '',
      motoristaId: map['motorista_id']?.toString() ?? '',
      municipioId: map['municipio_id']?.toString() ?? 'local',
      tipo: map['tipo']?.toString() ?? '',
      payloadJson: map['payload_json']?.toString() ?? '{}',
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      createdAt: map['created_at']?.toString() ?? '',
      syncStatus: map['sync_status']?.toString() ?? 'pending',
    );
  }

  EventoOperacionalModel copyWith({String? syncStatus}) {
    return EventoOperacionalModel(
      id: id,
      viagemId: viagemId,
      motoristaId: motoristaId,
      municipioId: municipioId,
      tipo: tipo,
      payloadJson: payloadJson,
      latitude: latitude,
      longitude: longitude,
      createdAt: createdAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}
