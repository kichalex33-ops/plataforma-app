class ACEProfileModel {
  final int? id;
  final String nome;
  final String municipio;
  final String senha;
  final String createdAt;

  ACEProfileModel({
    this.id,
    required this.nome,
    required this.municipio,
    required this.senha,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'nome': nome,
      'municipio': municipio,
      'senha': senha,
      'created_at': createdAt,
    };

    if (id != null) {
      map['id'] = id;
    }

    return map;
  }

  factory ACEProfileModel.fromMap(Map<String, dynamic> map) {
    return ACEProfileModel(
      id: map['id'],
      nome: map['nome'] ?? '',
      municipio: map['municipio'] ?? '',
      senha: map['senha'] ?? '',
      createdAt: map['created_at'] ?? '',
    );
  }
}
