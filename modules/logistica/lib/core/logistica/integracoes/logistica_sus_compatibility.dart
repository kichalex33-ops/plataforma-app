class LogisticaSusAuditRecord {
  final String cns;
  final String cpf;
  final String paciente;
  final String unidadeSaude;
  final String procedimentoConsulta;
  final DateTime data;
  final String destino;
  final String? comprovante;
  final bool presenca;
  final String? acompanhante;

  const LogisticaSusAuditRecord({
    required this.cns,
    required this.cpf,
    required this.paciente,
    required this.unidadeSaude,
    required this.procedimentoConsulta,
    required this.data,
    required this.destino,
    required this.comprovante,
    required this.presenca,
    required this.acompanhante,
  });

  Map<String, dynamic> toPayload() {
    return {
      'cns': cns,
      'cpf': cpf,
      'paciente': paciente,
      'unidade_saude': unidadeSaude,
      'procedimento_consulta': procedimentoConsulta,
      'data': data.toIso8601String(),
      'destino': destino,
      'comprovante': comprovante,
      'presenca': presenca,
      'acompanhante': acompanhante,
    };
  }
}

class LogisticaSusCompatibility {
  static List<String> validate(LogisticaSusAuditRecord record) {
    final missing = <String>[];
    if (record.cns.trim().isEmpty) missing.add('cns');
    if (record.cpf.trim().isEmpty) missing.add('cpf');
    if (record.paciente.trim().isEmpty) missing.add('paciente');
    if (record.unidadeSaude.trim().isEmpty) missing.add('unidadeSaude');
    if (record.procedimentoConsulta.trim().isEmpty) {
      missing.add('procedimentoConsulta');
    }
    if (record.destino.trim().isEmpty) missing.add('destino');
    if (record.comprovante == null || record.comprovante!.trim().isEmpty) {
      missing.add('comprovante');
    }
    return missing;
  }
}
