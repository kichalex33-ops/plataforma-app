class AreaPrioritariaModel {
  final int? id;
  final String nome;
  final String endereco;
  final String tipoRisco;
  final String grauRisco;
  final String motivoPrioridade;
  final String municipio;
  final String agente;
  final String dataRegistro;
  final String status;
  final String observacoes;
  final int gravidade;
  final int urgencia;
  final int tendencia;
  final double latitude;
  final double longitude;

  const AreaPrioritariaModel({
    this.id,
    required this.nome,
    required this.endereco,
    required this.tipoRisco,
    required this.grauRisco,
    required this.motivoPrioridade,
    required this.municipio,
    required this.agente,
    required this.dataRegistro,
    required this.status,
    required this.observacoes,
    required this.gravidade,
    required this.urgencia,
    required this.tendencia,
    required this.latitude,
    required this.longitude,
  });

  int get prioridadeGUT => gravidade * urgencia * tendencia;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'endereco': endereco,
      'tipo_risco': tipoRisco,
      'grau_risco': grauRisco,
      'motivo_prioridade': motivoPrioridade,
      'municipio': municipio,
      'agente': agente,
      'data_registro': dataRegistro,
      'status': status,
      'observacoes': observacoes,
      'gravidade': gravidade,
      'urgencia': urgencia,
      'tendencia': tendencia,
      'prioridade_gut': prioridadeGUT,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory AreaPrioritariaModel.fromMap(Map<String, dynamic> map) {
    return AreaPrioritariaModel(
      id: map['id'],
      nome: map['nome'] ?? '',
      endereco: map['endereco'] ?? '',
      tipoRisco: map['tipo_risco'] ?? '',
      grauRisco: map['grau_risco'] ?? '',
      motivoPrioridade: map['motivo_prioridade'] ?? '',
      municipio: map['municipio'] ?? '',
      agente: map['agente'] ?? '',
      dataRegistro: map['data_registro'] ?? '',
      status: map['status'] ?? '',
      observacoes: map['observacoes'] ?? '',
      gravidade: map['gravidade'] ?? 1,
      urgencia: map['urgencia'] ?? 1,
      tendencia: map['tendencia'] ?? 1,
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0,
    );
  }
}
