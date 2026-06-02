class LogisticaFleetMaintenanceSnapshot {
  final String veiculoId;
  final String placa;
  final double kmAtual;
  final double proximaRevisaoKm;
  final double proximaTrocaOleoKm;
  final DateTime vencimentoDocumento;
  final DateTime vencimentoSeguro;
  final DateTime vencimentoCnhMotorista;
  final bool pneusRevisaoPendente;

  const LogisticaFleetMaintenanceSnapshot({
    required this.veiculoId,
    required this.placa,
    required this.kmAtual,
    required this.proximaRevisaoKm,
    required this.proximaTrocaOleoKm,
    required this.vencimentoDocumento,
    required this.vencimentoSeguro,
    required this.vencimentoCnhMotorista,
    required this.pneusRevisaoPendente,
  });
}

class LogisticaFleetMaintenanceStatus {
  final String veiculoId;
  final String placa;
  final bool bloqueioOperacional;
  final List<String> alertas;

  const LogisticaFleetMaintenanceStatus({
    required this.veiculoId,
    required this.placa,
    required this.bloqueioOperacional,
    required this.alertas,
  });
}

class LogisticaFleetMaintenancePolicy {
  final double alertaRevisaoKm;
  final double alertaOleoKm;
  final int alertaVencimentoDias;

  const LogisticaFleetMaintenancePolicy({
    this.alertaRevisaoKm = 500,
    this.alertaOleoKm = 300,
    this.alertaVencimentoDias = 30,
  });

  LogisticaFleetMaintenanceStatus evaluate(
    LogisticaFleetMaintenanceSnapshot snapshot, {
    DateTime? now,
  }) {
    final reference = now ?? DateTime.now();
    final alertas = <String>[];
    var bloqueio = false;

    void bloquear(String alerta) {
      alertas.add(alerta);
      bloqueio = true;
    }

    void alertar(String alerta) {
      alertas.add(alerta);
    }

    if (snapshot.kmAtual >= snapshot.proximaRevisaoKm) {
      bloquear('revisao_vencida');
    } else if (snapshot.proximaRevisaoKm - snapshot.kmAtual <=
        alertaRevisaoKm) {
      alertar('revisao_proxima');
    }

    if (snapshot.kmAtual >= snapshot.proximaTrocaOleoKm) {
      bloquear('troca_oleo_vencida');
    } else if (snapshot.proximaTrocaOleoKm - snapshot.kmAtual <= alertaOleoKm) {
      alertar('troca_oleo_proxima');
    }

    if (_isExpired(snapshot.vencimentoDocumento, reference)) {
      bloquear('documento_vencido');
    } else if (_isNear(snapshot.vencimentoDocumento, reference)) {
      alertar('documento_proximo_vencimento');
    }

    if (_isExpired(snapshot.vencimentoSeguro, reference)) {
      bloquear('seguro_vencido');
    } else if (_isNear(snapshot.vencimentoSeguro, reference)) {
      alertar('seguro_proximo_vencimento');
    }

    if (_isExpired(snapshot.vencimentoCnhMotorista, reference)) {
      bloquear('cnh_vencida');
    } else if (_isNear(snapshot.vencimentoCnhMotorista, reference)) {
      alertar('cnh_proxima_vencimento');
    }

    if (snapshot.pneusRevisaoPendente) {
      alertar('pneus_revisao_pendente');
    }

    return LogisticaFleetMaintenanceStatus(
      veiculoId: snapshot.veiculoId,
      placa: snapshot.placa,
      bloqueioOperacional: bloqueio,
      alertas: List.unmodifiable(alertas),
    );
  }

  bool _isExpired(DateTime date, DateTime now) {
    return date.isBefore(DateTime(now.year, now.month, now.day));
  }

  bool _isNear(DateTime date, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final limit = today.add(Duration(days: alertaVencimentoDias));
    return !date.isBefore(today) && !date.isAfter(limit);
  }
}
