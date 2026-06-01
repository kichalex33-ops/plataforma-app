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

  factory RastreamentoPontoModel.fromMap(Map<String, dynamic> map) {
    return RastreamentoPontoModel(
      sync: SyncMetadata.fromMap(map),
      viagemId: map['viagem_id']?.toString() ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0,
      velocidade: (map['velocidade'] as num?)?.toDouble(),
      timestamp: map['timestamp']?.toString() ?? '',
      origemDado: map['origem_dado']?.toString() ?? 'local',
    );
  }
}
