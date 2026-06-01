class BTIModel {
  final int? id;
  final int? pontoBtiId;
  final String local;
  final String tipoCriadouro;
  final String municipio;
  final String agente;
  final String dataAplicacao;
  final double volumeLitros;
  final double dosagemGramas;
  final String periodicidade;
  final String observacoes;
  final double latitude;
  final double longitude;

  const BTIModel({
    this.id,
    this.pontoBtiId,
    required this.local,
    required this.tipoCriadouro,
    required this.municipio,
    required this.agente,
    required this.dataAplicacao,
    required this.volumeLitros,
    required this.dosagemGramas,
    required this.periodicidade,
    required this.observacoes,
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ponto_bti_id': pontoBtiId,
      'local': local,
      'tipo_criadouro': tipoCriadouro,
      'municipio': municipio,
      'agente': agente,
      'data_aplicacao': dataAplicacao,
      'volume_litros': volumeLitros,
      'dosagem_gramas': dosagemGramas,
      'periodicidade': periodicidade,
      'observacoes': observacoes,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory BTIModel.fromMap(Map<String, dynamic> map) {
    return BTIModel(
      id: map['id'],
      pontoBtiId: map['ponto_bti_id'],
      local: map['local'] ?? '',
      tipoCriadouro: map['tipo_criadouro'] ?? '',
      municipio: map['municipio'] ?? '',
      agente: map['agente'] ?? '',
      dataAplicacao: map['data_aplicacao'] ?? '',
      volumeLitros: (map['volume_litros'] as num?)?.toDouble() ?? 0,
      dosagemGramas: (map['dosagem_gramas'] as num?)?.toDouble() ?? 0,
      periodicidade: map['periodicidade'] ?? '',
      observacoes: map['observacoes'] ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0,
    );
  }
}
