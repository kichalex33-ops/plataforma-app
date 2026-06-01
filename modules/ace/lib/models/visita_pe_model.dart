class VisitaPEModel {
  final int? id;
  final int peId;
  final String dataVisita;
  final String entradaEm;
  final String saidaEm;
  final String municipio;
  final String agente;
  final String situacao;
  final bool focoPositivo;
  final int quantidadeTubitos;
  final String observacoes;
  final String fotoPath;
  final double? latitude;
  final double? longitude;
  final double? entradaLatitude;
  final double? entradaLongitude;
  final double? saidaLatitude;
  final double? saidaLongitude;
  final List<int> tubitos;

  VisitaPEModel({
    this.id,
    required this.peId,
    required this.dataVisita,
    required this.entradaEm,
    required this.saidaEm,
    required this.municipio,
    required this.agente,
    required this.situacao,
    required this.focoPositivo,
    required this.quantidadeTubitos,
    required this.observacoes,
    required this.fotoPath,
    this.latitude,
    this.longitude,
    this.entradaLatitude,
    this.entradaLongitude,
    this.saidaLatitude,
    this.saidaLongitude,
    this.tubitos = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'pe_id': peId,
      'data_visita': dataVisita,
      'entrada_em': entradaEm,
      'saida_em': saidaEm,
      'municipio': municipio,
      'agente': agente,
      'situacao': situacao,
      'foco_positivo': focoPositivo ? 1 : 0,
      'quantidade_tubitos': quantidadeTubitos,
      'observacoes': observacoes,
      'foto_path': fotoPath,
      'latitude': latitude,
      'longitude': longitude,
      'entrada_latitude': entradaLatitude,
      'entrada_longitude': entradaLongitude,
      'saida_latitude': saidaLatitude,
      'saida_longitude': saidaLongitude,
    };
  }

  factory VisitaPEModel.fromMap(
    Map<String, dynamic> map, {
    List<int> tubitos = const [],
  }) {
    return VisitaPEModel(
      id: map['id'],
      peId: map['pe_id'],
      dataVisita: map['data_visita'] ?? '',
      entradaEm: map['entrada_em'] ?? map['data_visita'] ?? '',
      saidaEm: map['saida_em'] ?? map['data_visita'] ?? '',
      municipio: map['municipio'] ?? '',
      agente: map['agente'] ?? '',
      situacao: map['situacao'] ?? '',
      focoPositivo: map['foco_positivo'] == 1,
      quantidadeTubitos: map['quantidade_tubitos'] ?? 0,
      observacoes: map['observacoes'] ?? '',
      fotoPath: map['foto_path'] ?? '',
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      entradaLatitude: (map['entrada_latitude'] as num?)?.toDouble(),
      entradaLongitude: (map['entrada_longitude'] as num?)?.toDouble(),
      saidaLatitude: (map['saida_latitude'] as num?)?.toDouble(),
      saidaLongitude: (map['saida_longitude'] as num?)?.toDouble(),
      tubitos: tubitos,
    );
  }
}
