import 'dart:convert';

class ViagemPreparacaoModel {
  final String id;
  final String municipioId;
  final String viagemId;
  final String motoristaId;
  final String? veiculoId;
  final double? kmInicial;
  final bool checklistConcluido;
  final Map<String, bool> checklist;
  final String horarioPreparacao;
  final String? horarioSaida;
  final String status;
  final String syncStatus;

  const ViagemPreparacaoModel({
    required this.id,
    required this.municipioId,
    required this.viagemId,
    required this.motoristaId,
    this.veiculoId,
    this.kmInicial,
    this.checklistConcluido = false,
    this.checklist = const {},
    required this.horarioPreparacao,
    this.horarioSaida,
    this.status = 'preparacao',
    this.syncStatus = 'pending',
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'municipio_id': municipioId,
    'viagem_id': viagemId,
    'motorista_id': motoristaId,
    'veiculo_id': veiculoId,
    'km_inicial': kmInicial,
    'checklist_concluido': checklistConcluido ? 1 : 0,
    'checklist_payload_json': jsonEncode(checklist),
    'horario_preparacao': horarioPreparacao,
    'horario_saida': horarioSaida,
    'status': status,
    'sync_status': syncStatus,
  };

  factory ViagemPreparacaoModel.fromMap(Map<String, dynamic> map) {
    final checklistJson = map['checklist_payload_json']?.toString() ?? '{}';
    final decoded = jsonDecode(checklistJson);
    return ViagemPreparacaoModel(
      id: map['id']?.toString() ?? '',
      municipioId: map['municipio_id']?.toString() ?? 'local',
      viagemId: map['viagem_id']?.toString() ?? '',
      motoristaId: map['motorista_id']?.toString() ?? '',
      veiculoId: map['veiculo_id'] as String?,
      kmInicial: (map['km_inicial'] as num?)?.toDouble(),
      checklistConcluido: (map['checklist_concluido'] as num? ?? 0) != 0,
      checklist: decoded is Map
          ? decoded.map((key, value) => MapEntry(key.toString(), value == true))
          : const {},
      horarioPreparacao: map['horario_preparacao']?.toString() ?? '',
      horarioSaida: map['horario_saida'] as String?,
      status: map['status']?.toString() ?? 'preparacao',
      syncStatus: map['sync_status']?.toString() ?? 'pending',
    );
  }

  ViagemPreparacaoModel copyWith({
    double? kmInicial,
    bool? checklistConcluido,
    Map<String, bool>? checklist,
    String? horarioSaida,
    String? status,
  }) {
    return ViagemPreparacaoModel(
      id: id,
      municipioId: municipioId,
      viagemId: viagemId,
      motoristaId: motoristaId,
      veiculoId: veiculoId,
      kmInicial: kmInicial ?? this.kmInicial,
      checklistConcluido: checklistConcluido ?? this.checklistConcluido,
      checklist: checklist ?? this.checklist,
      horarioPreparacao: horarioPreparacao,
      horarioSaida: horarioSaida ?? this.horarioSaida,
      status: status ?? this.status,
      syncStatus: syncStatus,
    );
  }
}
