import '../../sync/models/sync_metadata.dart';

class MotoristaModel {
  final SyncMetadata sync;
  final String nome;
  final String? cpf;
  final String? telefone;
  final String? cnh;
  final String status;
  final String? observacoes;

  const MotoristaModel({
    required this.sync,
    required this.nome,
    this.cpf,
    this.telefone,
    this.cnh,
    this.status = 'ativo',
    this.observacoes,
  });

  Map<String, dynamic> toMap() => {
    ...sync.toMap(),
    'nome': nome,
    'cpf': cpf,
    'telefone': telefone,
    'cnh': cnh,
    'status': status,
    'observacoes': observacoes,
  };

  factory MotoristaModel.fromMap(Map<String, dynamic> map) {
    return MotoristaModel(
      sync: SyncMetadata.fromMap(map),
      nome: map['nome']?.toString() ?? '',
      cpf: map['cpf'] as String?,
      telefone: map['telefone'] as String?,
      cnh: map['cnh'] as String?,
      status: map['status']?.toString() ?? 'ativo',
      observacoes: map['observacoes'] as String?,
    );
  }
}
