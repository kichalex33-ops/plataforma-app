class ExclusaoLogModel {
  final int? id;
  final String entidade;
  final int entidadeId;
  final String descricao;
  final String justificativa;
  final String agente;
  final String municipio;
  final String dataHora;
  final String origem;
  final int sincronizado;
  final String? sincronizadoEm;
  final String? erroSincronizacao;

  const ExclusaoLogModel({
    this.id,
    required this.entidade,
    required this.entidadeId,
    required this.descricao,
    required this.justificativa,
    required this.agente,
    required this.municipio,
    required this.dataHora,
    this.origem = 'app_flutter',
    this.sincronizado = 0,
    this.sincronizadoEm,
    this.erroSincronizacao,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'entidade': entidade,
      'entidade_id': entidadeId,
      'descricao': descricao,
      'justificativa': justificativa,
      'agente': agente,
      'municipio': municipio,
      'data_hora': dataHora,
      'origem': origem,
      'sincronizado': sincronizado,
      'sincronizado_em': sincronizadoEm,
      'erro_sincronizacao': erroSincronizacao,
    };
  }

  factory ExclusaoLogModel.fromMap(Map<String, dynamic> map) {
    return ExclusaoLogModel(
      id: map['id'] as int?,
      entidade: map['entidade'] as String? ?? '',
      entidadeId: map['entidade_id'] as int? ?? 0,
      descricao: map['descricao'] as String? ?? '',
      justificativa: map['justificativa'] as String? ?? '',
      agente: map['agente'] as String? ?? '',
      municipio: map['municipio'] as String? ?? '',
      dataHora: map['data_hora'] as String? ?? '',
      origem: map['origem'] as String? ?? 'app_flutter',
      sincronizado: map['sincronizado'] as int? ?? 0,
      sincronizadoEm: map['sincronizado_em'] as String?,
      erroSincronizacao: map['erro_sincronizacao'] as String?,
    );
  }
}
