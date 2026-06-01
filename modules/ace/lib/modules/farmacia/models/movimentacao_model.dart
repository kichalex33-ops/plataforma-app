import '../../sync/models/sync_metadata.dart';

class MovimentacaoFarmaciaModel {
  final SyncMetadata sync;
  final String medicamentoId;
  final String? estoqueId;
  final String tipo;
  final int quantidade;
  final String dataMovimentacao;
  final String? responsavel;
  final String? motivo;
  final String? pacienteId;
  final String? observacoes;

  const MovimentacaoFarmaciaModel({
    required this.sync,
    required this.medicamentoId,
    this.estoqueId,
    required this.tipo,
    required this.quantidade,
    required this.dataMovimentacao,
    this.responsavel,
    this.motivo,
    this.pacienteId,
    this.observacoes,
  });

  Map<String, dynamic> toMap() => {
    ...sync.toMap(),
    'medicamento_id': medicamentoId,
    'estoque_id': estoqueId,
    'tipo': tipo,
    'quantidade': quantidade,
    'data_movimentacao': dataMovimentacao,
    'responsavel': responsavel,
    'motivo': motivo,
    'paciente_id': pacienteId,
    'observacoes': observacoes,
  };
}
