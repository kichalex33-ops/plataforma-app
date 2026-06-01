import '../../sync/models/sync_metadata.dart';

class RastreamentoPontoModel {
  final SyncMetadata sync;
  final String viagemId;
  final double latitude;
  final double longitude;
  final double? velocidade;
  final String timestamp;
  final String origemDado;

  const RastreamentoPontoModel({
    required this.sync,
    required this.viagemId,
    required this.latitude,
    required this.longitude,
    this.velocidade,
    required this.timestamp,
    required this.origemDado,
  });

  Map<String, dynamic> toMap() => {
    ...sync.toMap(),
    'viagem_id': viagemId,
    'latitude': latitude,
    'longitude': longitude,
    'velocidade': velocidade,
    'timestamp': timestamp,
    'origem_dado': origemDado,
  };
}
