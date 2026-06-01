import '../../sync/models/sync_metadata.dart';

class PacienteModel {
  final SyncMetadata sync;
  final String nome;
  final String? cpf;
  final String? cns;
  final String? dataNascimento;
  final String? telefone;
  final String? endereco;
  final String? bairro;
  final String? referencia;
  final double? latitude;
  final double? longitude;
  final String? necessidadesEspeciais;
  final String? observacoes;
  final String status;

  const PacienteModel({
    required this.sync,
    required this.nome,
    this.cpf,
    this.cns,
    this.dataNascimento,
    this.telefone,
    this.endereco,
    this.bairro,
    this.referencia,
    this.latitude,
    this.longitude,
    this.necessidadesEspeciais,
    this.observacoes,
    this.status = 'ativo',
  });

  Map<String, dynamic> toMap() => {
    ...sync.toMap(),
    'nome': nome,
    'cpf': cpf,
    'cns': cns,
    'data_nascimento': dataNascimento,
    'telefone': telefone,
    'endereco': endereco,
    'bairro': bairro,
    'referencia': referencia,
    'latitude': latitude,
    'longitude': longitude,
    'necessidades_especiais': necessidadesEspeciais,
    'observacoes': observacoes,
    'status': status,
  };

  factory PacienteModel.fromMap(Map<String, dynamic> map) {
    return PacienteModel(
      sync: SyncMetadata.fromMap(map),
      nome: map['nome']?.toString() ?? '',
      cpf: map['cpf'] as String?,
      cns: map['cns'] as String?,
      dataNascimento: map['data_nascimento'] as String?,
      telefone: map['telefone'] as String?,
      endereco: map['endereco'] as String?,
      bairro: map['bairro'] as String?,
      referencia: map['referencia'] as String?,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      necessidadesEspeciais: map['necessidades_especiais'] as String?,
      observacoes: map['observacoes'] as String?,
      status: map['status']?.toString() ?? 'ativo',
    );
  }
}
