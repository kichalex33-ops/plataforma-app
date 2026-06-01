class PECycle {
  final int numero;
  final int semanaInicio;
  final int semanaFim;
  final DateTime inicio;
  final DateTime fim;

  const PECycle({
    required this.numero,
    required this.semanaInicio,
    required this.semanaFim,
    required this.inicio,
    required this.fim,
  });

  String get titulo => 'Ciclo PE ${numero.toString().padLeft(2, '0')}';

  String get periodo {
    return '${_formatarData(inicio)} a ${_formatarData(fim)}';
  }

  String get semanas {
    return 'SE $semanaInicio-$semanaFim';
  }

  bool contem(DateTime data) {
    final dia = DateTime(data.year, data.month, data.day);
    return !dia.isBefore(inicio) && !dia.isAfter(fim);
  }

  static String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}';
  }
}

class GeneralCycle {
  final int numero;
  final int semanaInicio;
  final int semanaFim;
  final DateTime inicio;
  final DateTime fim;

  const GeneralCycle({
    required this.numero,
    required this.semanaInicio,
    required this.semanaFim,
    required this.inicio,
    required this.fim,
  });

  String get titulo => 'Ciclo ${numero.toString().padLeft(2, '0')}';

  String get periodo {
    return '${_formatarData(inicio)} a ${_formatarData(fim)}';
  }

  String get semanas {
    return 'SE $semanaInicio-$semanaFim';
  }

  bool contem(DateTime data) {
    final dia = DateTime(data.year, data.month, data.day);
    return !dia.isBefore(inicio) && !dia.isAfter(fim);
  }

  static String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}';
  }
}

class OperationalReminder {
  final String titulo;
  final String periodo;
  final String descricao;
  final DateTime? prazo;

  const OperationalReminder({
    required this.titulo,
    required this.periodo,
    required this.descricao,
    this.prazo,
  });
}

class EpidemiologicalCalendar {
  static final ciclosPE2026 = <PECycle>[
    PECycle(
      numero: 1,
      semanaInicio: 1,
      semanaFim: 2,
      inicio: DateTime(2026, 1, 1),
      fim: DateTime(2026, 1, 15),
    ),
    PECycle(
      numero: 2,
      semanaInicio: 2,
      semanaFim: 4,
      inicio: DateTime(2026, 1, 16),
      fim: DateTime(2026, 1, 31),
    ),
    PECycle(
      numero: 3,
      semanaInicio: 5,
      semanaFim: 7,
      inicio: DateTime(2026, 2, 1),
      fim: DateTime(2026, 2, 15),
    ),
    PECycle(
      numero: 4,
      semanaInicio: 7,
      semanaFim: 8,
      inicio: DateTime(2026, 2, 16),
      fim: DateTime(2026, 2, 28),
    ),
    PECycle(
      numero: 5,
      semanaInicio: 9,
      semanaFim: 11,
      inicio: DateTime(2026, 3, 1),
      fim: DateTime(2026, 3, 15),
    ),
    PECycle(
      numero: 6,
      semanaInicio: 11,
      semanaFim: 13,
      inicio: DateTime(2026, 3, 16),
      fim: DateTime(2026, 3, 31),
    ),
    PECycle(
      numero: 7,
      semanaInicio: 13,
      semanaFim: 15,
      inicio: DateTime(2026, 4, 1),
      fim: DateTime(2026, 4, 15),
    ),
    PECycle(
      numero: 8,
      semanaInicio: 15,
      semanaFim: 17,
      inicio: DateTime(2026, 4, 16),
      fim: DateTime(2026, 4, 30),
    ),
    PECycle(
      numero: 9,
      semanaInicio: 17,
      semanaFim: 19,
      inicio: DateTime(2026, 5, 1),
      fim: DateTime(2026, 5, 15),
    ),
    PECycle(
      numero: 10,
      semanaInicio: 19,
      semanaFim: 22,
      inicio: DateTime(2026, 5, 16),
      fim: DateTime(2026, 5, 31),
    ),
    PECycle(
      numero: 11,
      semanaInicio: 22,
      semanaFim: 24,
      inicio: DateTime(2026, 6, 1),
      fim: DateTime(2026, 6, 15),
    ),
    PECycle(
      numero: 12,
      semanaInicio: 24,
      semanaFim: 26,
      inicio: DateTime(2026, 6, 16),
      fim: DateTime(2026, 6, 30),
    ),
    PECycle(
      numero: 13,
      semanaInicio: 26,
      semanaFim: 28,
      inicio: DateTime(2026, 7, 1),
      fim: DateTime(2026, 7, 15),
    ),
    PECycle(
      numero: 14,
      semanaInicio: 28,
      semanaFim: 30,
      inicio: DateTime(2026, 7, 16),
      fim: DateTime(2026, 7, 31),
    ),
    PECycle(
      numero: 15,
      semanaInicio: 30,
      semanaFim: 32,
      inicio: DateTime(2026, 8, 1),
      fim: DateTime(2026, 8, 15),
    ),
    PECycle(
      numero: 16,
      semanaInicio: 33,
      semanaFim: 35,
      inicio: DateTime(2026, 8, 16),
      fim: DateTime(2026, 8, 31),
    ),
    PECycle(
      numero: 17,
      semanaInicio: 35,
      semanaFim: 37,
      inicio: DateTime(2026, 9, 1),
      fim: DateTime(2026, 9, 15),
    ),
    PECycle(
      numero: 18,
      semanaInicio: 37,
      semanaFim: 39,
      inicio: DateTime(2026, 9, 16),
      fim: DateTime(2026, 9, 30),
    ),
    PECycle(
      numero: 19,
      semanaInicio: 39,
      semanaFim: 41,
      inicio: DateTime(2026, 10, 1),
      fim: DateTime(2026, 10, 15),
    ),
    PECycle(
      numero: 20,
      semanaInicio: 41,
      semanaFim: 43,
      inicio: DateTime(2026, 10, 16),
      fim: DateTime(2026, 10, 31),
    ),
    PECycle(
      numero: 21,
      semanaInicio: 44,
      semanaFim: 46,
      inicio: DateTime(2026, 11, 1),
      fim: DateTime(2026, 11, 15),
    ),
    PECycle(
      numero: 22,
      semanaInicio: 46,
      semanaFim: 48,
      inicio: DateTime(2026, 11, 16),
      fim: DateTime(2026, 11, 30),
    ),
    PECycle(
      numero: 23,
      semanaInicio: 48,
      semanaFim: 50,
      inicio: DateTime(2026, 12, 1),
      fim: DateTime(2026, 12, 15),
    ),
    PECycle(
      numero: 24,
      semanaInicio: 50,
      semanaFim: 52,
      inicio: DateTime(2026, 12, 16),
      fim: DateTime(2026, 12, 31),
    ),
  ];

  static PECycle? cicloPEAtual({DateTime? data}) {
    final referencia = data ?? DateTime.now();

    if (referencia.year != 2026) {
      return null;
    }

    for (final ciclo in ciclosPE2026) {
      if (ciclo.contem(referencia)) {
        return ciclo;
      }
    }

    return null;
  }

  static final ciclosMunicipiosInfestados2026 = <GeneralCycle>[
    GeneralCycle(
      numero: 1,
      semanaInicio: 1,
      semanaFim: 8,
      inicio: DateTime(2026, 1, 1),
      fim: DateTime(2026, 2, 28),
    ),
    GeneralCycle(
      numero: 2,
      semanaInicio: 9,
      semanaFim: 17,
      inicio: DateTime(2026, 3, 1),
      fim: DateTime(2026, 4, 30),
    ),
    GeneralCycle(
      numero: 3,
      semanaInicio: 17,
      semanaFim: 26,
      inicio: DateTime(2026, 5, 1),
      fim: DateTime(2026, 6, 30),
    ),
    GeneralCycle(
      numero: 4,
      semanaInicio: 26,
      semanaFim: 35,
      inicio: DateTime(2026, 7, 1),
      fim: DateTime(2026, 8, 31),
    ),
    GeneralCycle(
      numero: 5,
      semanaInicio: 35,
      semanaFim: 43,
      inicio: DateTime(2026, 9, 1),
      fim: DateTime(2026, 10, 31),
    ),
    GeneralCycle(
      numero: 6,
      semanaInicio: 44,
      semanaFim: 52,
      inicio: DateTime(2026, 11, 1),
      fim: DateTime(2026, 12, 31),
    ),
  ];

  static GeneralCycle? cicloMunicipioAtual({DateTime? data}) {
    final referencia = data ?? DateTime.now();

    if (referencia.year != 2026) {
      return null;
    }

    for (final ciclo in ciclosMunicipiosInfestados2026) {
      if (ciclo.contem(referencia)) {
        return ciclo;
      }
    }

    return null;
  }

  static final lembretesLiraaLia2026 = <OperationalReminder>[
    OperationalReminder(
      titulo: 'LIRAa/LIA - 1º ciclo',
      periodo: '11/01/2026 a 31/01/2026',
      descricao: 'Período previsto no Ofício Circular Nº 07/2026/SVSA/MS.',
      prazo: DateTime(2026, 1, 31),
    ),
    OperationalReminder(
      titulo: 'LIRAa/LIA - prazo excepcional',
      periodo: 'até 28/02/2026',
      descricao:
          'Municípios que não realizaram o 1º ciclo no período previsto podem executar impreterivelmente até esta data.',
      prazo: DateTime(2026, 2, 28),
    ),
    OperationalReminder(
      titulo: 'Entrega de resultados à CRS',
      periodo: 'até 10/03/2026',
      descricao:
          'Entrega dos resultados do 1º ciclo realizado fora do período previsto, acompanhada de justificativa.',
      prazo: DateTime(2026, 3, 10),
    ),
    OperationalReminder(
      titulo: 'Municípios com ovitrampas',
      periodo: '1º ou 2º ciclo de 2026',
      descricao:
          'Municípios com monitoramento contínuo por ovitrampas devem realizar pelo menos um ciclo de LIRAa/LIA em 2026.',
    ),
    OperationalReminder(
      titulo: 'Municípios sem ovitrampas',
      periodo: '4 ciclos em 2026',
      descricao:
          'Devem realizar os quatro ciclos de LIRAa/LIA conforme calendário do Ofício Circular Nº 07/2026/SVSA/MS.',
    ),
  ];
}
