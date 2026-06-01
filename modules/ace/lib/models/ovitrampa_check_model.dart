class OvitrampaCheckModel {
  final int? id;
  final int ovitrampaId;
  final String dataChecagem;
  final String agente;
  final String resultado;
  final int quantidadeOvos;
  final String observacoes;
  final double latitude;
  final double longitude;

  const OvitrampaCheckModel({
    this.id,
    required this.ovitrampaId,
    required this.dataChecagem,
    required this.agente,
    required this.resultado,
    required this.quantidadeOvos,
    required this.observacoes,
    required this.latitude,
    required this.longitude,
  });

  factory OvitrampaCheckModel.fromMap(Map<String, dynamic> map) {
    return OvitrampaCheckModel(
      id: map['id'],
      ovitrampaId: map['ovitrampa_id'],
      dataChecagem: map['data_checagem'] ?? '',
      agente: map['agente'] ?? '',
      resultado: map['resultado'] ?? '',
      quantidadeOvos: map['quantidade_ovos'] ?? 0,
      observacoes: map['observacoes'] ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0,
    );
  }
}
