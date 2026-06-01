import '../../sync/models/sync_metadata.dart';
import 'viagem_status.dart';

class ViagemModel {
  final SyncMetadata sync;
  final String? motoristaId;
  final String? veiculoId;
  final String origem;
  final String destino;
  final String dataHoraSaida;
  final String? dataHoraRetorno;
  final String status;
  final String? finalidade;
  final String? rotaGeojson;
  final String? observacoes;

  const ViagemModel({
    required this.sync,
    this.motoristaId,
    this.veiculoId,
    required this.origem,
    required this.destino,
    required this.dataHoraSaida,
    this.dataHoraRetorno,
    this.status = ViagemStatus.rascunho,
    this.finalidade,
    this.rotaGeojson,
    this.observacoes,
  });

  Map<String, dynamic> toMap() => {
    ...sync.toMap(),
    'motorista_id': motoristaId,
    'veiculo_id': veiculoId,
    'origem': origem,
    'destino': destino,
    'data_hora_saida': dataHoraSaida,
    'data_hora_retorno': dataHoraRetorno,
    'status': status,
    'finalidade': finalidade,
    'rota_geojson': rotaGeojson,
    'observacoes': observacoes,
  };

  factory ViagemModel.fromMap(Map<String, dynamic> map) {
    return ViagemModel(
      sync: SyncMetadata.fromMap(map),
      motoristaId: map['motorista_id'] as String?,
      veiculoId: map['veiculo_id'] as String?,
      origem: map['origem']?.toString() ?? '',
      destino: map['destino']?.toString() ?? '',
      dataHoraSaida: map['data_hora_saida']?.toString() ?? '',
      dataHoraRetorno: map['data_hora_retorno'] as String?,
      status: map['status']?.toString() ?? ViagemStatus.rascunho,
      finalidade: map['finalidade'] as String?,
      rotaGeojson: map['rota_geojson'] as String?,
      observacoes: map['observacoes'] as String?,
    );
  }
}
