class AtividadeQuarteiraoModel {
  final int? id;
  final int quarteiraoId;
  final String quarteiraoNumero;
  final String localidade;
  final String dataAtividade;
  final String agente;
  final String atividade;
  final int imoveisPrevistos;
  final int imoveisVisitados;
  final int imoveisFechados;
  final int imoveisRecusados;
  final int imoveisPendentes;
  final int coletasRealizadas;
  final int coletasPositivas;
  final int coletasNegativas;
  final String observacoes;
  final double? latitude;
  final double? longitude;

  const AtividadeQuarteiraoModel({
    this.id,
    required this.quarteiraoId,
    required this.quarteiraoNumero,
    required this.localidade,
    required this.dataAtividade,
    required this.agente,
    required this.atividade,
    required this.imoveisPrevistos,
    required this.imoveisVisitados,
    required this.imoveisFechados,
    required this.imoveisRecusados,
    required this.imoveisPendentes,
    required this.coletasRealizadas,
    required this.coletasPositivas,
    required this.coletasNegativas,
    required this.observacoes,
    this.latitude,
    this.longitude,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'quarteirao_id': quarteiraoId,
      'quarteirao_numero': quarteiraoNumero,
      'localidade': localidade,
      'data_atividade': dataAtividade,
      'agente': agente,
      'atividade': atividade,
      'imoveis_previstos': imoveisPrevistos,
      'imoveis_visitados': imoveisVisitados,
      'imoveis_fechados': imoveisFechados,
      'imoveis_recusados': imoveisRecusados,
      'imoveis_pendentes': imoveisPendentes,
      'coletas_realizadas': coletasRealizadas,
      'coletas_positivas': coletasPositivas,
      'coletas_negativas': coletasNegativas,
      'observacoes': observacoes,
      'latitude': latitude,
      'longitude': longitude,
    };

    if (id != null) {
      map['id'] = id;
    }

    return map;
  }

  factory AtividadeQuarteiraoModel.fromMap(Map<String, dynamic> map) {
    return AtividadeQuarteiraoModel(
      id: map['id'],
      quarteiraoId: map['quarteirao_id'] ?? 0,
      quarteiraoNumero: map['quarteirao_numero'] ?? '',
      localidade: map['localidade'] ?? '',
      dataAtividade: map['data_atividade'] ?? '',
      agente: map['agente'] ?? '',
      atividade: map['atividade'] ?? '',
      imoveisPrevistos: map['imoveis_previstos'] ?? 0,
      imoveisVisitados: map['imoveis_visitados'] ?? 0,
      imoveisFechados: map['imoveis_fechados'] ?? 0,
      imoveisRecusados: map['imoveis_recusados'] ?? 0,
      imoveisPendentes: map['imoveis_pendentes'] ?? 0,
      coletasRealizadas: map['coletas_realizadas'] ?? 0,
      coletasPositivas: map['coletas_positivas'] ?? 0,
      coletasNegativas: map['coletas_negativas'] ?? 0,
      observacoes: map['observacoes'] ?? '',
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
    );
  }
}
