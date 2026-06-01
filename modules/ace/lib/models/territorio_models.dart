class SyncFields {
  final String id;
  final String? deviceId;
  final int version;
  final String createdAt;
  final String updatedAt;
  final String syncStatus;

  const SyncFields({
    required this.id,
    this.deviceId,
    this.version = 1,
    required this.createdAt,
    required this.updatedAt,
    this.syncStatus = 'pending',
  });
}

class LocalidadeModel {
  final SyncFields sync;
  final String municipioId;
  final String nome;
  final String tipo;
  final String observacoes;

  const LocalidadeModel({
    required this.sync,
    required this.municipioId,
    required this.nome,
    required this.tipo,
    required this.observacoes,
  });

  Map<String, dynamic> toMap() => {
    'id': sync.id,
    'municipio_id': municipioId,
    'nome': nome,
    'tipo': tipo,
    'observacoes': observacoes,
    'device_id': sync.deviceId,
    'version': sync.version,
    'created_at': sync.createdAt,
    'updated_at': sync.updatedAt,
    'sync_status': sync.syncStatus,
  };

  factory LocalidadeModel.fromMap(Map<String, dynamic> map) {
    return LocalidadeModel(
      sync: _syncFromMap(map),
      municipioId: map['municipio_id']?.toString() ?? '',
      nome: map['nome']?.toString() ?? '',
      tipo: map['tipo']?.toString() ?? '',
      observacoes: map['observacoes']?.toString() ?? '',
    );
  }
}

class SetorOperacionalModel {
  final SyncFields sync;
  final String municipioId;
  final String localidadeId;
  final String codigo;
  final String nome;
  final String descricao;
  final String supervisorId;
  final String status;

  const SetorOperacionalModel({
    required this.sync,
    required this.municipioId,
    required this.localidadeId,
    required this.codigo,
    required this.nome,
    required this.descricao,
    required this.supervisorId,
    required this.status,
  });

  Map<String, dynamic> toMap() => {
    'id': sync.id,
    'municipio_id': municipioId,
    'localidade_id': localidadeId,
    'codigo': codigo,
    'nome': nome,
    'descricao': descricao,
    'supervisor_id': supervisorId,
    'status': status,
    'device_id': sync.deviceId,
    'version': sync.version,
    'created_at': sync.createdAt,
    'updated_at': sync.updatedAt,
    'sync_status': sync.syncStatus,
  };

  factory SetorOperacionalModel.fromMap(Map<String, dynamic> map) {
    return SetorOperacionalModel(
      sync: _syncFromMap(map),
      municipioId: map['municipio_id']?.toString() ?? '',
      localidadeId: map['localidade_id']?.toString() ?? '',
      codigo: map['codigo']?.toString() ?? '',
      nome: map['nome']?.toString() ?? '',
      descricao: map['descricao']?.toString() ?? '',
      supervisorId: map['supervisor_id']?.toString() ?? '',
      status: map['status']?.toString() ?? 'planejado',
    );
  }
}

class QuarteiraoOperacionalModel {
  final SyncFields sync;
  final String setorId;
  final String municipioId;
  final String localidadeId;
  final String codigo;
  final int ordemExecucao;
  final String status;
  final int totalImoveisPrevistos;
  final int totalVisitados;
  final int totalFechados;
  final int totalRecusas;
  final int totalFocos;
  final int totalPendencias;
  final String? geometriaGeojson;
  final double? centroLatitude;
  final double? centroLongitude;

  const QuarteiraoOperacionalModel({
    required this.sync,
    required this.setorId,
    required this.municipioId,
    required this.localidadeId,
    required this.codigo,
    required this.ordemExecucao,
    required this.status,
    required this.totalImoveisPrevistos,
    required this.totalVisitados,
    required this.totalFechados,
    required this.totalRecusas,
    required this.totalFocos,
    required this.totalPendencias,
    this.geometriaGeojson,
    this.centroLatitude,
    this.centroLongitude,
  });

  Map<String, dynamic> toMap() => {
    'id': sync.id,
    'setor_id': setorId,
    'municipio_id': municipioId,
    'localidade_id': localidadeId,
    'codigo': codigo,
    'ordem_execucao': ordemExecucao,
    'status': status,
    'total_imoveis_previstos': totalImoveisPrevistos,
    'total_visitados': totalVisitados,
    'total_fechados': totalFechados,
    'total_recusas': totalRecusas,
    'total_focos': totalFocos,
    'total_pendencias': totalPendencias,
    'geometria_geojson': geometriaGeojson,
    'centro_latitude': centroLatitude,
    'centro_longitude': centroLongitude,
    'device_id': sync.deviceId,
    'version': sync.version,
    'created_at': sync.createdAt,
    'updated_at': sync.updatedAt,
    'sync_status': sync.syncStatus,
  };

  factory QuarteiraoOperacionalModel.fromMap(Map<String, dynamic> map) {
    return QuarteiraoOperacionalModel(
      sync: _syncFromMap(map),
      setorId: map['setor_id']?.toString() ?? '',
      municipioId: map['municipio_id']?.toString() ?? '',
      localidadeId: map['localidade_id']?.toString() ?? '',
      codigo: map['codigo']?.toString() ?? '',
      ordemExecucao: map['ordem_execucao'] as int? ?? 0,
      status: map['status']?.toString() ?? 'nao_iniciado',
      totalImoveisPrevistos: map['total_imoveis_previstos'] as int? ?? 0,
      totalVisitados: map['total_visitados'] as int? ?? 0,
      totalFechados: map['total_fechados'] as int? ?? 0,
      totalRecusas: map['total_recusas'] as int? ?? 0,
      totalFocos: map['total_focos'] as int? ?? 0,
      totalPendencias: map['total_pendencias'] as int? ?? 0,
      geometriaGeojson: map['geometria_geojson'] as String?,
      centroLatitude: (map['centro_latitude'] as num?)?.toDouble(),
      centroLongitude: (map['centro_longitude'] as num?)?.toDouble(),
    );
  }
}

class AtribuicaoSetorModel {
  final SyncFields sync;
  final String setorId;
  final String aceId;
  final String supervisorId;
  final String dataInicio;
  final String? dataFim;
  final String status;
  final String observacoes;

  const AtribuicaoSetorModel({
    required this.sync,
    required this.setorId,
    required this.aceId,
    required this.supervisorId,
    required this.dataInicio,
    this.dataFim,
    required this.status,
    required this.observacoes,
  });

  Map<String, dynamic> toMap() => {
    'id': sync.id,
    'setor_id': setorId,
    'ace_id': aceId,
    'supervisor_id': supervisorId,
    'data_inicio': dataInicio,
    'data_fim': dataFim,
    'status': status,
    'observacoes': observacoes,
    'device_id': sync.deviceId,
    'version': sync.version,
    'created_at': sync.createdAt,
    'updated_at': sync.updatedAt,
    'sync_status': sync.syncStatus,
  };

  factory AtribuicaoSetorModel.fromMap(Map<String, dynamic> map) {
    return AtribuicaoSetorModel(
      sync: _syncFromMap(map),
      setorId: map['setor_id']?.toString() ?? '',
      aceId: map['ace_id']?.toString() ?? '',
      supervisorId: map['supervisor_id']?.toString() ?? '',
      dataInicio: map['data_inicio']?.toString() ?? '',
      dataFim: map['data_fim'] as String?,
      status: map['status']?.toString() ?? 'ativa',
      observacoes: map['observacoes']?.toString() ?? '',
    );
  }
}

class ProgressoQuarteiraoModel {
  final SyncFields sync;
  final String quarteiraoId;
  final String aceId;
  final String status;
  final String? iniciadoEm;
  final String? concluidoEm;
  final int totalVisitados;
  final int totalPendencias;
  final String observacoes;

  const ProgressoQuarteiraoModel({
    required this.sync,
    required this.quarteiraoId,
    required this.aceId,
    required this.status,
    this.iniciadoEm,
    this.concluidoEm,
    required this.totalVisitados,
    required this.totalPendencias,
    required this.observacoes,
  });

  Map<String, dynamic> toMap() => {
    'id': sync.id,
    'quarteirao_id': quarteiraoId,
    'ace_id': aceId,
    'status': status,
    'iniciado_em': iniciadoEm,
    'concluido_em': concluidoEm,
    'total_visitados': totalVisitados,
    'total_pendencias': totalPendencias,
    'observacoes': observacoes,
    'device_id': sync.deviceId,
    'version': sync.version,
    'created_at': sync.createdAt,
    'updated_at': sync.updatedAt,
    'sync_status': sync.syncStatus,
  };

  factory ProgressoQuarteiraoModel.fromMap(Map<String, dynamic> map) {
    return ProgressoQuarteiraoModel(
      sync: _syncFromMap(map),
      quarteiraoId: map['quarteirao_id']?.toString() ?? '',
      aceId: map['ace_id']?.toString() ?? '',
      status: map['status']?.toString() ?? 'em_andamento',
      iniciadoEm: map['iniciado_em'] as String?,
      concluidoEm: map['concluido_em'] as String?,
      totalVisitados: map['total_visitados'] as int? ?? 0,
      totalPendencias: map['total_pendencias'] as int? ?? 0,
      observacoes: map['observacoes']?.toString() ?? '',
    );
  }
}

SyncFields _syncFromMap(Map<String, dynamic> map) {
  return SyncFields(
    id: map['id']?.toString() ?? '',
    deviceId: map['device_id'] as String?,
    version: map['version'] as int? ?? 1,
    createdAt: map['created_at']?.toString() ?? '',
    updatedAt: map['updated_at']?.toString() ?? '',
    syncStatus: map['sync_status']?.toString() ?? 'pending',
  );
}
