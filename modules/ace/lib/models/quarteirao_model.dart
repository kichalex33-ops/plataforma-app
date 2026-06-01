class QuarteiraoModel {
  final int? id;
  final String numero;
  final String localidade;
  final int totalImoveis;
  final int residencias;
  final int comercios;
  final int pontosEstrategicos;
  final int outros;
  final String status;
  final String? ultimaDataTrabalhada;
  final String atividadeAtual;
  final double? latitude;
  final double? longitude;

  const QuarteiraoModel({
    this.id,
    required this.numero,
    required this.localidade,
    required this.totalImoveis,
    required this.residencias,
    required this.comercios,
    required this.pontosEstrategicos,
    required this.outros,
    required this.status,
    this.ultimaDataTrabalhada,
    required this.atividadeAtual,
    this.latitude,
    this.longitude,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'numero': numero,
      'localidade': localidade,
      'total_imoveis': totalImoveis,
      'residencias': residencias,
      'comercios': comercios,
      'pontos_estrategicos': pontosEstrategicos,
      'outros': outros,
      'status': status,
      'ultima_data_trabalhada': ultimaDataTrabalhada,
      'atividade_atual': atividadeAtual,
      'latitude': latitude,
      'longitude': longitude,
    };

    if (id != null) {
      map['id'] = id;
    }

    return map;
  }

  factory QuarteiraoModel.fromMap(Map<String, dynamic> map) {
    return QuarteiraoModel(
      id: map['id'],
      numero: map['numero'] ?? '',
      localidade: map['localidade'] ?? '',
      totalImoveis: map['total_imoveis'] ?? 0,
      residencias: map['residencias'] ?? 0,
      comercios: map['comercios'] ?? 0,
      pontosEstrategicos: map['pontos_estrategicos'] ?? 0,
      outros: map['outros'] ?? 0,
      status: map['status'] ?? 'Nao iniciado',
      ultimaDataTrabalhada: map['ultima_data_trabalhada'],
      atividadeAtual: map['atividade_atual'] ?? 'Rotina',
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
    );
  }
}
