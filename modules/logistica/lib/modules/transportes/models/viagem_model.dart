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
  final String prioridade;
  final String? observacoesCentral;
  final String? unidadeDestino;
  final String? dataConsulta;
  final String? horarioConsulta;
  final String? destinoPrincipal;
  final String? statusOperacional;
  final double? kmSaida;
  final String? horarioSaidaConfirmada;

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
    this.prioridade = 'normal',
    this.observacoesCentral,
    this.unidadeDestino,
    this.dataConsulta,
    this.horarioConsulta,
    this.destinoPrincipal,
    this.statusOperacional,
    this.kmSaida,
    this.horarioSaidaConfirmada,
  });

  String get estadoOperacional => statusOperacional ?? status;
  String get destinoExibicao => destinoPrincipal?.isNotEmpty == true
      ? destinoPrincipal!
      : unidadeDestino?.isNotEmpty == true
      ? unidadeDestino!
      : destino;

  bool get isPrioritaria => prioridade.toLowerCase() == 'alta';
  bool get isTransferencia =>
      finalidade?.toLowerCase().contains('transfer') == true;
  bool get isRetorno => finalidade?.toLowerCase().contains('retorno') == true;

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
    'prioridade': prioridade,
    'observacoes_central': observacoesCentral,
    'unidade_destino': unidadeDestino,
    'data_consulta': dataConsulta,
    'horario_consulta': horarioConsulta,
    'destino_principal': destinoPrincipal,
    'status_operacional': statusOperacional,
    'km_saida': kmSaida,
    'horario_saida_confirmada': horarioSaidaConfirmada,
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
      prioridade: map['prioridade']?.toString() ?? 'normal',
      observacoesCentral: map['observacoes_central'] as String?,
      unidadeDestino: map['unidade_destino'] as String?,
      dataConsulta: map['data_consulta'] as String?,
      horarioConsulta: map['horario_consulta'] as String?,
      destinoPrincipal: map['destino_principal'] as String?,
      statusOperacional: map['status_operacional'] as String?,
      kmSaida: (map['km_saida'] as num?)?.toDouble(),
      horarioSaidaConfirmada: map['horario_saida_confirmada'] as String?,
    );
  }

  ViagemModel copyWith({
    String? status,
    String? statusOperacional,
    double? kmSaida,
    String? horarioSaidaConfirmada,
  }) {
    return ViagemModel(
      sync: sync,
      motoristaId: motoristaId,
      veiculoId: veiculoId,
      origem: origem,
      destino: destino,
      dataHoraSaida: dataHoraSaida,
      dataHoraRetorno: dataHoraRetorno,
      status: status ?? this.status,
      finalidade: finalidade,
      rotaGeojson: rotaGeojson,
      observacoes: observacoes,
      prioridade: prioridade,
      observacoesCentral: observacoesCentral,
      unidadeDestino: unidadeDestino,
      dataConsulta: dataConsulta,
      horarioConsulta: horarioConsulta,
      destinoPrincipal: destinoPrincipal,
      statusOperacional: statusOperacional ?? this.statusOperacional,
      kmSaida: kmSaida ?? this.kmSaida,
      horarioSaidaConfirmada:
          horarioSaidaConfirmada ?? this.horarioSaidaConfirmada,
    );
  }
}
