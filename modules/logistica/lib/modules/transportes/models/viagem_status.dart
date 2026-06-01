class ViagemStatus {
  static const rascunho = 'rascunho';
  static const agendada = 'agendada';
  static const emAndamento = 'em_andamento';
  static const concluida = 'concluida';
  static const cancelada = 'cancelada';

  static const values = [rascunho, agendada, emAndamento, concluida, cancelada];

  static String label(String status) {
    return switch (status) {
      rascunho => 'Rascunho',
      agendada => 'Agendada',
      emAndamento => 'Em andamento',
      concluida => 'Concluida',
      cancelada => 'Cancelada',
      _ => status,
    };
  }
}
