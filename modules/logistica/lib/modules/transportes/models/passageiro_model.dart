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
  final bool acompanhante;
  final String? acessibilidade;
  final String? telefone;
  final String? enderecoEmbarque;
  final bool cadeirante;
  final bool mobilidadeReduzida;
  final bool acompanhanteObrigatorio;
  final String? observacoesEmbarque;

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
    this.acompanhante = false,
    this.acessibilidade,
    this.telefone,
    this.enderecoEmbarque,
    this.cadeirante = false,
    this.mobilidadeReduzida = false,
    this.acompanhanteObrigatorio = false,
    this.observacoesEmbarque,
  });

  bool get possuiAcessibilidade {
    return cadeirante ||
        mobilidadeReduzida ||
        acompanhanteObrigatorio ||
        (necessidadeEspecial?.trim().isNotEmpty == true) ||
        (acessibilidade?.trim().isNotEmpty == true);
  }

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
    'acompanhante': acompanhante ? 1 : 0,
    'acessibilidade': acessibilidade,
    'telefone': telefone,
    'endereco_embarque': enderecoEmbarque,
    'cadeirante': cadeirante ? 1 : 0,
    'mobilidade_reduzida': mobilidadeReduzida ? 1 : 0,
    'acompanhante_obrigatorio': acompanhanteObrigatorio ? 1 : 0,
    'observacoes_embarque': observacoesEmbarque,
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
      acompanhante: _boolFromDb(map['acompanhante']),
      acessibilidade: map['acessibilidade'] as String?,
      telefone: map['telefone'] as String?,
      enderecoEmbarque: map['endereco_embarque'] as String?,
      cadeirante: _boolFromDb(map['cadeirante']),
      mobilidadeReduzida: _boolFromDb(map['mobilidade_reduzida']),
      acompanhanteObrigatorio: _boolFromDb(map['acompanhante_obrigatorio']),
      observacoesEmbarque: map['observacoes_embarque'] as String?,
    );
  }

  static bool _boolFromDb(Object? value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) return value == '1' || value.toLowerCase() == 'true';
    return false;
  }
}
