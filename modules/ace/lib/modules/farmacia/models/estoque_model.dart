import '../../sync/models/sync_metadata.dart';

class EstoqueModel {
  final SyncMetadata sync;
  final String medicamentoId;
  final String? lote;
  final String? validade;
  final int quantidade;
  final String? unidadeSaudeId;
  final int estoqueMinimo;
  final String? observacoes;

  const EstoqueModel({
    required this.sync,
    required this.medicamentoId,
    this.lote,
    this.validade,
    this.quantidade = 0,
    this.unidadeSaudeId,
    this.estoqueMinimo = 0,
    this.observacoes,
  });

  Map<String, dynamic> toMap() => {
    ...sync.toMap(),
    'medicamento_id': medicamentoId,
    'lote': lote,
    'validade': validade,
    'quantidade': quantidade,
    'unidade_saude_id': unidadeSaudeId,
    'estoque_minimo': estoqueMinimo,
    'observacoes': observacoes,
  };

  factory EstoqueModel.fromMap(Map<String, dynamic> map) {
    return EstoqueModel(
      sync: SyncMetadata.fromMap(map),
      medicamentoId: map['medicamento_id']?.toString() ?? '',
      lote: map['lote'] as String?,
      validade: map['validade'] as String?,
      quantidade: map['quantidade'] as int? ?? 0,
      unidadeSaudeId: map['unidade_saude_id'] as String?,
      estoqueMinimo: map['estoque_minimo'] as int? ?? 0,
      observacoes: map['observacoes'] as String?,
    );
  }
}
