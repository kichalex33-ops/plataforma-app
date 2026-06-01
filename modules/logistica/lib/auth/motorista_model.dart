class MotoristaModel {
  final String id;
  final String nome;
  final String municipio;

  const MotoristaModel({
    required this.id,
    required this.nome,
    required this.municipio,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'nome': nome,
    'municipio': municipio,
  };

  factory MotoristaModel.fromMap(Map<String, dynamic> map) {
    return MotoristaModel(
      id: map['id']?.toString() ?? 'motorista-local',
      nome: map['nome']?.toString() ?? '',
      municipio: map['municipio']?.toString() ?? '',
    );
  }
}
