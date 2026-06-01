class OvitrampaModel {
  final int? id;
  final String codigo;
  final String endereco;
  final String referencia;
  final String municipio;
  final String agenteInstalacao;
  final String instaladaEm;
  final String status;
  final double latitude;
  final double longitude;
  final String? ultimaChecagem;

  const OvitrampaModel({
    this.id,
    required this.codigo,
    required this.endereco,
    required this.referencia,
    required this.municipio,
    required this.agenteInstalacao,
    required this.instaladaEm,
    required this.status,
    required this.latitude,
    required this.longitude,
    this.ultimaChecagem,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'codigo': codigo,
      'endereco': endereco,
      'referencia': referencia,
      'municipio': municipio,
      'agente_instalacao': agenteInstalacao,
      'instalada_em': instaladaEm,
      'status': status,
      'latitude': latitude,
      'longitude': longitude,
      'ultima_checagem': ultimaChecagem,
    };
  }

  factory OvitrampaModel.fromMap(Map<String, dynamic> map) {
    return OvitrampaModel(
      id: map['id'],
      codigo: map['codigo'] ?? '',
      endereco: map['endereco'] ?? '',
      referencia: map['referencia'] ?? '',
      municipio: map['municipio'] ?? '',
      agenteInstalacao: map['agente_instalacao'] ?? '',
      instaladaEm: map['instalada_em'] ?? '',
      status: map['status'] ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0,
      ultimaChecagem: map['ultima_checagem'],
    );
  }
}
