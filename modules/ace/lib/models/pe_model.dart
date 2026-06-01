class PEModel {
  final int? id;
  final String nome;
  final String endereco;
  final String tipo;
  final String status;
  final String? ultimaVisita;
  final double? latitude;
  final double? longitude;

  PEModel({
    this.id,
    required this.nome,
    required this.endereco,
    required this.tipo,
    required this.status,
    this.ultimaVisita,
    this.latitude,
    this.longitude,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'endereco': endereco,
      'tipo': tipo,
      'status': status,
      'ultima_visita': ultimaVisita,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory PEModel.fromMap(Map<String, dynamic> map) {
    return PEModel(
      id: map['id'],
      nome: map['nome'],
      endereco: map['endereco'],
      tipo: map['tipo'],
      status: map['status'],
      ultimaVisita: map['ultima_visita'],
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
    );
  }
}
