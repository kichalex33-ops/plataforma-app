class Trip {
  final String id;
  final String destination;
  final DateTime scheduledTime;
  final double progress;
  final DateTime? now;

  const Trip({
    required this.id,
    required this.destination,
    required this.scheduledTime,
    required this.progress,
    this.now,
  });

  bool get isLate => (now ?? DateTime.now()).isAfter(scheduledTime);

  factory Trip.fromJson(Map<String, dynamic> json, {DateTime? now}) {
    return Trip(
      id: json['id']?.toString() ?? '',
      destination:
          json['destino_nome']?.toString() ??
          json['destination']?.toString() ??
          json['destino']?.toString() ??
          'Destino nao informado',
      scheduledTime: _parseDate(json['horario_previsto']),
      progress: _parseProgress(json['progresso']),
      now: now,
    );
  }

  static DateTime _parseDate(Object? value) {
    if (value is DateTime) return value;
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }

  static double _parseProgress(Object? value) {
    final parsed = switch (value) {
      num number => number.toDouble(),
      String text => double.tryParse(text.replaceAll(',', '.')) ?? 0,
      _ => 0.0,
    };
    return parsed.clamp(0.0, 1.0);
  }
}
