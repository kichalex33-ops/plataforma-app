class ViagemStatus {
  static const rascunho = 'rascunho';
  static const agendada = 'agendada';
  static const emAndamento = 'em_andamento';
  static const concluida = 'concluida';
  static const cancelada = 'cancelada';
  static const aguardando = 'aguardando';
  static const preparacao = 'preparacao';
  static const saidaConfirmada = 'saida_confirmada';
  static const emTransitoIda = 'em_transito_ida';
  static const emEspera = 'em_espera';
  static const reembarqueRetorno = 'reembarque_retorno';
  static const emTransitoVolta = 'em_transito_volta';
  static const finalizacao = 'finalizacao';
  static const pendenteSincronizacao = 'pendente_sincronizacao';
  static const sincronizada = 'sincronizada';
  static const erroSincronizacao = 'erro_sincronizacao';

  static const values = [
    rascunho,
    agendada,
    emAndamento,
    concluida,
    cancelada,
    aguardando,
    preparacao,
    saidaConfirmada,
    emTransitoIda,
    emEspera,
    reembarqueRetorno,
    emTransitoVolta,
    finalizacao,
    pendenteSincronizacao,
    sincronizada,
    erroSincronizacao,
  ];

  static String label(String status) {
    return switch (status) {
      rascunho => 'Rascunho',
      agendada => 'Agendada',
      emAndamento => 'Em andamento',
      concluida => 'Concluida',
      cancelada => 'Cancelada',
      aguardando => 'Aguardando',
      preparacao => 'Preparacao',
      saidaConfirmada => 'Saida confirmada',
      emTransitoIda => 'Em transito - ida',
      emEspera => 'Em espera',
      reembarqueRetorno => 'Reembarque retorno',
      emTransitoVolta => 'Em transito - volta',
      finalizacao => 'Finalizacao',
      pendenteSincronizacao => 'Pendente sincronizacao',
      sincronizada => 'Sincronizada',
      erroSincronizacao => 'Erro sincronizacao',
      _ => status,
    };
  }

  static bool isOperacional(String status) {
    return [
      aguardando,
      preparacao,
      saidaConfirmada,
      emTransitoIda,
      emEspera,
      reembarqueRetorno,
      emTransitoVolta,
      finalizacao,
    ].contains(status);
  }
}
