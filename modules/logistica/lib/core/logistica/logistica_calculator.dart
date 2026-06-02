import 'logistica_enums.dart';
import 'logistica_models.dart';

class LogisticaCalculator {
  static double kmRodado({required double kmInicial, required double kmFinal}) {
    if (kmFinal < kmInicial) return 0;
    return kmFinal - kmInicial;
  }

  static double valorPorLitro({
    required double valor,
    required double litros,
  }) {
    if (litros <= 0) return 0;
    return valor / litros;
  }

  static double custoPorKm({
    required double totalDespesas,
    required double kmRodado,
  }) {
    if (kmRodado <= 0) return 0;
    return totalDespesas / kmRodado;
  }

  static double custoPorPaciente({
    required double totalDespesas,
    required int pacientesTransportados,
  }) {
    if (pacientesTransportados <= 0) return 0;
    return totalDespesas / pacientesTransportados;
  }

  static double totalDespesas(List<LogisticaAbastecimento> despesas) {
    return despesas.fold(0, (total, item) => total + item.valor);
  }

  static Duration tempoEmEspera(DateTime? inicio, DateTime? fim) {
    if (inicio == null || fim == null || fim.isBefore(inicio)) {
      return Duration.zero;
    }
    return fim.difference(inicio);
  }

  static Duration duracaoTotal(DateTime? inicio, DateTime? fim) {
    if (inicio == null || fim == null || fim.isBefore(inicio)) {
      return Duration.zero;
    }
    return fim.difference(inicio);
  }

  static int pacientesTransportados(List<LogisticaPassageiroViagem> itens) {
    return itens
        .where((item) => item.statusIda == StatusPacienteIda.embarcado)
        .length;
  }

  static int ausentesOuDesistentes(List<LogisticaPassageiroViagem> itens) {
    return itens
        .where(
          (item) =>
              item.statusIda == StatusPacienteIda.ausente ||
              item.statusIda == StatusPacienteIda.desistiu,
        )
        .length;
  }
}
