enum StatusViagem {
  aguardando,
  preparacao,
  saidaConfirmada,
  emTransitoIda,
  emEspera,
  reembarqueRetorno,
  emTransitoVolta,
  finalizacao,
  concluida,
  pendenteSincronizacao,
  sincronizada,
  erroSincronizacao,
  pendenteRevisao,
}

enum StatusPacienteIda {
  aguardando,
  embarcado,
  desembarcado,
  ausente,
  desistiu,
}

enum StatusPacienteVolta {
  aguardando,
  embarcado,
  desembarcado,
  naoRetornou,
  justificado,
}

enum TipoOcorrencia {
  panico,
  pacienteAusente,
  desistencia,
  paneMecanica,
  pneuFurado,
  acidente,
  pacientePassouMal,
  emergencia,
  atraso,
  abastecimento,
  despesa,
  outro,
}

enum TipoAcessibilidade {
  nenhuma,
  cadeirante,
  muletas,
  mobilidadeReduzida,
  maca,
  acompanhanteObrigatorio,
}

enum StatusSync { local, pendente, enviando, sincronizado, erro }

enum TipoEventoSync {
  viagemIniciada,
  pacienteDesembarcado,
  pacienteAusente,
  pacienteDesistiu,
  comprovanteCapturado,
  abastecimentoRegistrado,
  ocorrenciaRegistrada,
  panicoAcionado,
  retornoIniciado,
  viagemConcluida,
}

extension LogisticaEnumName on Enum {
  String get dbValue {
    final name = this.name;
    final buffer = StringBuffer();
    for (var i = 0; i < name.length; i++) {
      final char = name[i];
      final isUpper = char.toUpperCase() == char && char.toLowerCase() != char;
      if (isUpper && i > 0) buffer.write('_');
      buffer.write(char.toLowerCase());
    }
    return buffer.toString();
  }
}

T enumFromDbValue<T extends Enum>(List<T> values, String? value, T fallback) {
  if (value == null || value.isEmpty) return fallback;
  for (final item in values) {
    if (item.dbValue == value || item.name == value) return item;
  }
  return fallback;
}
