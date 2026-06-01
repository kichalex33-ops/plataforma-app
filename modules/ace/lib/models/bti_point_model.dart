class BTIPointModel {
  final int? id;
  final String nome;
  final String descricao;
  final double latitude;
  final double longitude;

  const BTIPointModel({
    this.id,
    required this.nome,
    required this.descricao,
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'descricao': descricao,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory BTIPointModel.fromMap(Map<String, dynamic> map) {
    return BTIPointModel(
      id: map['id'],
      nome: map['nome'] ?? '',
      descricao: map['descricao'] ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0,
    );
  }
}
