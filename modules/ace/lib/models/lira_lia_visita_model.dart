class LiraLiaVisitaModel {
  final int? id;
  final int? rgQuarteiraoId;
  final String rgQuarteiraoCodigo;
  final String tipoLevantamento;
  final String municipio;
  final String agente;
  final String dataRegistro;
  final int imoveisPrevistos;
  final int imoveisTrabalhados;
  final int imoveisFechados;
  final int focosPositivos;
  final String observacoes;
  final double latitude;
  final double longitude;

  const LiraLiaVisitaModel({
    this.id,
    this.rgQuarteiraoId,
    required this.rgQuarteiraoCodigo,
    required this.tipoLevantamento,
    required this.municipio,
    required this.agente,
    required this.dataRegistro,
    required this.imoveisPrevistos,
    required this.imoveisTrabalhados,
    required this.imoveisFechados,
    required this.focosPositivos,
    required this.observacoes,
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'rg_quarteirao_id': rgQuarteiraoId,
      'rg_quarteirao_codigo': rgQuarteiraoCodigo,
      'tipo_levantamento': tipoLevantamento,
      'municipio': municipio,
      'agente': agente,
      'data_registro': dataRegistro,
      'imoveis_previstos': imoveisPrevistos,
      'imoveis_trabalhados': imoveisTrabalhados,
      'imoveis_fechados': imoveisFechados,
      'focos_positivos': focosPositivos,
      'observacoes': observacoes,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory LiraLiaVisitaModel.fromMap(Map<String, dynamic> map) {
    return LiraLiaVisitaModel(
      id: map['id'],
      rgQuarteiraoId: map['rg_quarteirao_id'],
      rgQuarteiraoCodigo: map['rg_quarteirao_codigo'] ?? '',
      tipoLevantamento: map['tipo_levantamento'] ?? '',
      municipio: map['municipio'] ?? '',
      agente: map['agente'] ?? '',
      dataRegistro: map['data_registro'] ?? '',
      imoveisPrevistos: map['imoveis_previstos'] ?? 0,
      imoveisTrabalhados: map['imoveis_trabalhados'] ?? 0,
      imoveisFechados: map['imoveis_fechados'] ?? 0,
      focosPositivos: map['focos_positivos'] ?? 0,
      observacoes: map['observacoes'] ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0,
    );
  }
}
