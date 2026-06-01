import '../../sync/models/sync_metadata.dart';

class MedicamentoModel {
  final SyncMetadata sync;
  final String nome;
  final String? principioAtivo;
  final String? apresentacao;
  final String? codigoBarras;
  final bool controlado;
  final String status;
  final String? observacoes;

  const MedicamentoModel({
    required this.sync,
    required this.nome,
    this.principioAtivo,
    this.apresentacao,
    this.codigoBarras,
    this.controlado = false,
    this.status = 'ativo',
    this.observacoes,
  });

  Map<String, dynamic> toMap() => {
    ...sync.toMap(),
    'nome': nome,
    'principio_ativo': principioAtivo,
    'apresentacao': apresentacao,
    'codigo_barras': codigoBarras,
    'controlado': controlado ? 1 : 0,
    'status': status,
    'observacoes': observacoes,
  };

  factory MedicamentoModel.fromMap(Map<String, dynamic> map) {
    return MedicamentoModel(
      sync: SyncMetadata.fromMap(map),
      nome: map['nome']?.toString() ?? '',
      principioAtivo: map['principio_ativo'] as String?,
      apresentacao: map['apresentacao'] as String?,
      codigoBarras: map['codigo_barras'] as String?,
      controlado: (map['controlado'] as int? ?? 0) == 1,
      status: map['status']?.toString() ?? 'ativo',
      observacoes: map['observacoes'] as String?,
    );
  }
}
