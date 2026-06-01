class RGQuarteiraoModel {
  final int? id;
  final String codigo;
  final int ordem;
  final double latitude;
  final double longitude;

  const RGQuarteiraoModel({
    this.id,
    required this.codigo,
    required this.ordem,
    required this.latitude,
    required this.longitude,
  });

  factory RGQuarteiraoModel.fromMap(Map<String, dynamic> map) {
    return RGQuarteiraoModel(
      id: map['id'],
      codigo: map['codigo'] ?? '',
      ordem: map['ordem'] ?? 0,
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0,
    );
  }
}
