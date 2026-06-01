import '../../sync/models/sync_metadata.dart';

class PassageiroModel {
  final SyncMetadata sync;
  final String viagemId;
  final String? pacienteId;
  final String nome;
  final String? documento;
  final String? necessidadeEspecial;
  final String? embarque;
  final String? desembarque;
  final String status;
  final String? observacoes;

  const PassageiroModel({
    required this.sync,
    required this.viagemId,
    this.pacienteId,
    required this.nome,
    this.documento,
    this.necessidadeEspecial,
    this.embarque,
    this.desembarque,
    this.status = 'agendado',
    this.observacoes,
  });

  Map<String, dynamic> toMap() => {
    ...sync.toMap(),
    'viagem_id': viagemId,
    'paciente_id': pacienteId,
    'nome': nome,
    'documento': documento,
    'necessidade_especial': necessidadeEspecial,
    'embarque': embarque,
    'desembarque': desembarque,
    'status': status,
    'observacoes': observacoes,
  };

  factory PassageiroModel.fromMap(Map<String, dynamic> map) {
    return PassageiroModel(
      sync: SyncMetadata.fromMap(map),
      viagemId: map['viagem_id']?.toString() ?? '',
      pacienteId: map['paciente_id'] as String?,
      nome: map['nome']?.toString() ?? '',
      documento: map['documento'] as String?,
      necessidadeEspecial: map['necessidade_especial'] as String?,
      embarque: map['embarque'] as String?,
      desembarque: map['desembarque'] as String?,
      status: map['status']?.toString() ?? 'agendado',
      observacoes: map['observacoes'] as String?,
    );
  }
}
