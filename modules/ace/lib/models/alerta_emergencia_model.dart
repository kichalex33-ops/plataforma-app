class AlertaEmergenciaModel {
  final int? id;
  final String agente;
  final String municipio;
  final String dataHora;
  final String mensagem;
  final double? latitude;
  final double? longitude;
  final String status;

  const AlertaEmergenciaModel({
    this.id,
    required this.agente,
    required this.municipio,
    required this.dataHora,
    required this.mensagem,
    this.latitude,
    this.longitude,
    this.status = 'Registrado',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'agente': agente,
      'municipio': municipio,
      'data_hora': dataHora,
      'mensagem': mensagem,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
    };
  }

  factory AlertaEmergenciaModel.fromMap(Map<String, dynamic> map) {
    return AlertaEmergenciaModel(
      id: map['id'] as int?,
      agente: map['agente'] as String? ?? '',
      municipio: map['municipio'] as String? ?? '',
      dataHora: map['data_hora'] as String? ?? '',
      mensagem: map['mensagem'] as String? ?? '',
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      status: map['status'] as String? ?? 'Registrado',
    );
  }
}
