import 'logistica_enums.dart';

abstract class LogisticaLocalEntity {
  final String idLocal;
  final String? idServidor;
  final DateTime createdAt;
  final DateTime updatedAt;
  final StatusSync statusSync;

  const LogisticaLocalEntity({
    required this.idLocal,
    this.idServidor,
    required this.createdAt,
    required this.updatedAt,
    this.statusSync = StatusSync.local,
  });

  Map<String, dynamic> baseMap() => {
    'id_local': idLocal,
    'id_servidor': idServidor,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'status_sync': statusSync.dbValue,
  };
}

class LogisticaViagem extends LogisticaLocalEntity {
  final String origem;
  final String destinoPrincipal;
  final String? unidadeDestino;
  final DateTime dataConsulta;
  final String? horarioConsulta;
  final String motoristaIdLocal;
  final String veiculoIdLocal;
  final StatusViagem status;
  final String prioridade;
  final String? observacoesCentral;
  final double? kmInicial;
  final double? kmFinal;
  final DateTime? inicioEspera;
  final DateTime? fimEspera;
  final DateTime? saidaEm;
  final DateTime? finalizadaEm;

  const LogisticaViagem({
    required super.idLocal,
    super.idServidor,
    required super.createdAt,
    required super.updatedAt,
    super.statusSync,
    required this.origem,
    required this.destinoPrincipal,
    this.unidadeDestino,
    required this.dataConsulta,
    this.horarioConsulta,
    required this.motoristaIdLocal,
    required this.veiculoIdLocal,
    this.status = StatusViagem.aguardando,
    this.prioridade = 'normal',
    this.observacoesCentral,
    this.kmInicial,
    this.kmFinal,
    this.inicioEspera,
    this.fimEspera,
    this.saidaEm,
    this.finalizadaEm,
  });

  Map<String, dynamic> toMap() => {
    ...baseMap(),
    'origem': origem,
    'destino_principal': destinoPrincipal,
    'unidade_destino': unidadeDestino,
    'data_consulta': dataConsulta.toIso8601String(),
    'horario_consulta': horarioConsulta,
    'motorista_id_local': motoristaIdLocal,
    'veiculo_id_local': veiculoIdLocal,
    'status': status.dbValue,
    'prioridade': prioridade,
    'observacoes_central': observacoesCentral,
    'km_inicial': kmInicial,
    'km_final': kmFinal,
    'inicio_espera': inicioEspera?.toIso8601String(),
    'fim_espera': fimEspera?.toIso8601String(),
    'saida_em': saidaEm?.toIso8601String(),
    'finalizada_em': finalizadaEm?.toIso8601String(),
  };
}

class LogisticaPaciente extends LogisticaLocalEntity {
  final String nome;
  final String? cns;
  final String? cpf;
  final String? telefone;
  final String enderecoEmbarque;
  final TipoAcessibilidade acessibilidade;
  final String? observacoes;

  const LogisticaPaciente({
    required super.idLocal,
    super.idServidor,
    required super.createdAt,
    required super.updatedAt,
    super.statusSync,
    required this.nome,
    this.cns,
    this.cpf,
    this.telefone,
    required this.enderecoEmbarque,
    this.acessibilidade = TipoAcessibilidade.nenhuma,
    this.observacoes,
  });

  Map<String, dynamic> toMap() => {
    ...baseMap(),
    'nome': nome,
    'cns': cns,
    'cpf': cpf,
    'telefone': telefone,
    'endereco_embarque': enderecoEmbarque,
    'acessibilidade': acessibilidade.dbValue,
    'observacoes': observacoes,
  };
}

class LogisticaPassageiroViagem extends LogisticaLocalEntity {
  final String viagemIdLocal;
  final String pacienteIdLocal;
  final bool acompanhante;
  final StatusPacienteIda statusIda;
  final StatusPacienteVolta statusVolta;
  final String? justificativaRetorno;
  final String? observacoesEmbarque;

  const LogisticaPassageiroViagem({
    required super.idLocal,
    super.idServidor,
    required super.createdAt,
    required super.updatedAt,
    super.statusSync,
    required this.viagemIdLocal,
    required this.pacienteIdLocal,
    this.acompanhante = false,
    this.statusIda = StatusPacienteIda.aguardando,
    this.statusVolta = StatusPacienteVolta.aguardando,
    this.justificativaRetorno,
    this.observacoesEmbarque,
  });

  bool get voltouOuJustificou =>
      statusVolta == StatusPacienteVolta.embarcado ||
      statusVolta == StatusPacienteVolta.justificado ||
      statusVolta == StatusPacienteVolta.naoRetornou;

  Map<String, dynamic> toMap() => {
    ...baseMap(),
    'viagem_id_local': viagemIdLocal,
    'paciente_id_local': pacienteIdLocal,
    'acompanhante': acompanhante ? 1 : 0,
    'status_ida': statusIda.dbValue,
    'status_volta': statusVolta.dbValue,
    'justificativa_retorno': justificativaRetorno,
    'observacoes_embarque': observacoesEmbarque,
  };
}

class LogisticaVeiculo extends LogisticaLocalEntity {
  final String placa;
  final String modelo;
  final String tipo;
  final int capacidade;
  final double? kmAtual;

  const LogisticaVeiculo({
    required super.idLocal,
    super.idServidor,
    required super.createdAt,
    required super.updatedAt,
    super.statusSync,
    required this.placa,
    required this.modelo,
    required this.tipo,
    this.capacidade = 0,
    this.kmAtual,
  });

  Map<String, dynamic> toMap() => {
    ...baseMap(),
    'placa': placa,
    'modelo': modelo,
    'tipo': tipo,
    'capacidade': capacidade,
    'km_atual': kmAtual,
  };
}

class LogisticaMotorista extends LogisticaLocalEntity {
  final String nome;
  final String? cpf;
  final String? telefone;
  final String? cnh;

  const LogisticaMotorista({
    required super.idLocal,
    super.idServidor,
    required super.createdAt,
    required super.updatedAt,
    super.statusSync,
    required this.nome,
    this.cpf,
    this.telefone,
    this.cnh,
  });

  Map<String, dynamic> toMap() => {
    ...baseMap(),
    'nome': nome,
    'cpf': cpf,
    'telefone': telefone,
    'cnh': cnh,
  };
}

class LogisticaChecklist extends LogisticaLocalEntity {
  final String viagemIdLocal;
  final String motoristaIdLocal;
  final String tipo;
  final String payloadJson;
  final bool concluido;

  const LogisticaChecklist({
    required super.idLocal,
    super.idServidor,
    required super.createdAt,
    required super.updatedAt,
    super.statusSync,
    required this.viagemIdLocal,
    required this.motoristaIdLocal,
    required this.tipo,
    required this.payloadJson,
    this.concluido = false,
  });

  Map<String, dynamic> toMap() => {
    ...baseMap(),
    'viagem_id_local': viagemIdLocal,
    'motorista_id_local': motoristaIdLocal,
    'tipo': tipo,
    'payload_json': payloadJson,
    'concluido': concluido ? 1 : 0,
  };
}

class LogisticaAbastecimento extends LogisticaLocalEntity {
  final String viagemIdLocal;
  final String veiculoIdLocal;
  final String motoristaIdLocal;
  final String local;
  final String tipo;
  final double litros;
  final double valor;
  final String? fotoCupomPath;
  final String? observacao;

  const LogisticaAbastecimento({
    required super.idLocal,
    super.idServidor,
    required super.createdAt,
    required super.updatedAt,
    super.statusSync,
    required this.viagemIdLocal,
    required this.veiculoIdLocal,
    required this.motoristaIdLocal,
    required this.local,
    this.tipo = 'abastecimento',
    required this.litros,
    required this.valor,
    this.fotoCupomPath,
    this.observacao,
  });

  Map<String, dynamic> toMap() => {
    ...baseMap(),
    'viagem_id_local': viagemIdLocal,
    'veiculo_id_local': veiculoIdLocal,
    'motorista_id_local': motoristaIdLocal,
    'local': local,
    'tipo': tipo,
    'litros': litros,
    'valor': valor,
    'foto_cupom_path': fotoCupomPath,
    'observacao': observacao,
  };
}

class LogisticaOcorrencia extends LogisticaLocalEntity {
  final String viagemIdLocal;
  final String motoristaIdLocal;
  final String? pacienteIdLocal;
  final TipoOcorrencia tipo;
  final String descricao;
  final DateTime dataHora;
  final String? fotoPath;

  const LogisticaOcorrencia({
    required super.idLocal,
    super.idServidor,
    required super.createdAt,
    required super.updatedAt,
    super.statusSync,
    required this.viagemIdLocal,
    required this.motoristaIdLocal,
    this.pacienteIdLocal,
    required this.tipo,
    required this.descricao,
    required this.dataHora,
    this.fotoPath,
  });

  Map<String, dynamic> toMap() => {
    ...baseMap(),
    'viagem_id_local': viagemIdLocal,
    'motorista_id_local': motoristaIdLocal,
    'paciente_id_local': pacienteIdLocal,
    'tipo': tipo.dbValue,
    'descricao': descricao,
    'data_hora': dataHora.toIso8601String(),
    'foto_path': fotoPath,
  };
}

class LogisticaComprovante extends LogisticaLocalEntity {
  final String viagemIdLocal;
  final String passageiroIdLocal;
  final String pacienteIdLocal;
  final String tipo;
  final String fotoPath;

  const LogisticaComprovante({
    required super.idLocal,
    super.idServidor,
    required super.createdAt,
    required super.updatedAt,
    super.statusSync,
    required this.viagemIdLocal,
    required this.passageiroIdLocal,
    required this.pacienteIdLocal,
    required this.tipo,
    required this.fotoPath,
  });

  Map<String, dynamic> toMap() => {
    ...baseMap(),
    'viagem_id_local': viagemIdLocal,
    'passageiro_id_local': passageiroIdLocal,
    'paciente_id_local': pacienteIdLocal,
    'tipo': tipo,
    'foto_path': fotoPath,
  };
}

class LogisticaAvisoCentral extends LogisticaLocalEntity {
  final String titulo;
  final String mensagem;
  final String prioridade;
  final DateTime dataHora;
  final bool lido;

  const LogisticaAvisoCentral({
    required super.idLocal,
    super.idServidor,
    required super.createdAt,
    required super.updatedAt,
    super.statusSync,
    required this.titulo,
    required this.mensagem,
    this.prioridade = 'normal',
    required this.dataHora,
    this.lido = false,
  });

  Map<String, dynamic> toMap() => {
    ...baseMap(),
    'titulo': titulo,
    'mensagem': mensagem,
    'prioridade': prioridade,
    'data_hora': dataHora.toIso8601String(),
    'lido': lido ? 1 : 0,
  };
}

class LogisticaSyncItem extends LogisticaLocalEntity {
  final TipoEventoSync tipoEvento;
  final String payloadJson;
  final int tentativas;
  final DateTime? ultimaTentativa;
  final String? erro;

  const LogisticaSyncItem({
    required super.idLocal,
    super.idServidor,
    required super.createdAt,
    required super.updatedAt,
    super.statusSync = StatusSync.pendente,
    required this.tipoEvento,
    required this.payloadJson,
    this.tentativas = 0,
    this.ultimaTentativa,
    this.erro,
  });

  Map<String, dynamic> toMap() => {
    ...baseMap(),
    'tipo_evento': tipoEvento.dbValue,
    'payload_json': payloadJson,
    'tentativas': tentativas,
    'ultima_tentativa': ultimaTentativa?.toIso8601String(),
    'erro': erro,
  };
}
