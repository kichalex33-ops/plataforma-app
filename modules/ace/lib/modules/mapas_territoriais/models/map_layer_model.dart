class MapLayerModel {
  final String id;
  final String municipioId;
  final String nome;
  final String tipo;
  final bool ativa;
  final String? configuracaoJson;
  final String createdAt;
  final String updatedAt;
  final String syncStatus;

  const MapLayerModel({
    required this.id,
    required this.municipioId,
    required this.nome,
    required this.tipo,
    this.ativa = true,
    this.configuracaoJson,
    required this.createdAt,
    required this.updatedAt,
    this.syncStatus = 'pending',
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'municipio_id': municipioId,
    'nome': nome,
    'tipo': tipo,
    'ativa': ativa ? 1 : 0,
    'configuracao_json': configuracaoJson,
    'created_at': createdAt,
    'updated_at': updatedAt,
    'sync_status': syncStatus,
  };

  factory MapLayerModel.fromMap(Map<String, dynamic> map) {
    return MapLayerModel(
      id: map['id']?.toString() ?? '',
      municipioId: map['municipio_id']?.toString() ?? 'local',
      nome: map['nome']?.toString() ?? '',
      tipo: map['tipo']?.toString() ?? '',
      ativa: (map['ativa'] as int? ?? 1) == 1,
      configuracaoJson: map['configuracao_json'] as String?,
      createdAt: map['created_at']?.toString() ?? '',
      updatedAt: map['updated_at']?.toString() ?? '',
      syncStatus: map['sync_status']?.toString() ?? 'pending',
    );
  }
}
