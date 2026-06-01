import '../../sync/models/sync_metadata.dart';

class VeiculoModel {
  final SyncMetadata sync;
  final String placa;
  final String modelo;
  final String tipo;
  final int capacidade;
  final String status;
  final String? observacoes;

  const VeiculoModel({
    required this.sync,
    required this.placa,
    required this.modelo,
    required this.tipo,
    this.capacidade = 0,
    this.status = 'ativo',
    this.observacoes,
  });

  Map<String, dynamic> toMap() => {
    ...sync.toMap(),
    'placa': placa,
    'modelo': modelo,
    'tipo': tipo,
    'capacidade': capacidade,
    'status': status,
    'observacoes': observacoes,
  };

  factory VeiculoModel.fromMap(Map<String, dynamic> map) {
    return VeiculoModel(
      sync: SyncMetadata.fromMap(map),
      placa: map['placa']?.toString() ?? '',
      modelo: map['modelo']?.toString() ?? '',
      tipo: map['tipo']?.toString() ?? '',
      capacidade: map['capacidade'] as int? ?? 0,
      status: map['status']?.toString() ?? 'ativo',
      observacoes: map['observacoes'] as String?,
    );
  }
}
