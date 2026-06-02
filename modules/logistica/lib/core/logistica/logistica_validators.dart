import 'logistica_enums.dart';
import 'logistica_models.dart';

class LogisticaValidationException implements Exception {
  final String message;

  const LogisticaValidationException(this.message);

  @override
  String toString() => message;
}

class KmValidationResult {
  final bool valido;
  final bool pendenteRevisao;
  final String? motivo;

  const KmValidationResult({
    required this.valido,
    this.pendenteRevisao = false,
    this.motivo,
  });
}

class LogisticaValidators {
  static KmValidationResult validarKmFinal({
    required double kmInicial,
    required double kmFinal,
    double? kmEsperado,
    double toleranciaPercentual = 0.6,
  }) {
    if (kmFinal < kmInicial) {
      throw const LogisticaValidationException(
        'KM final nao pode ser menor que KM inicial.',
      );
    }

    if (kmEsperado != null && kmEsperado > 0) {
      final rodado = kmFinal - kmInicial;
      final limite = kmEsperado * (1 + toleranciaPercentual);
      if (rodado > limite) {
        return KmValidationResult(
          valido: true,
          pendenteRevisao: true,
          motivo: 'KM rodado acima do esperado.',
        );
      }
    }

    return const KmValidationResult(valido: true);
  }

  static void validarInicioViagem({
    required double? kmSaida,
    required bool checklistPreUsoConcluido,
  }) {
    if (kmSaida == null || kmSaida <= 0) {
      throw const LogisticaValidationException(
        'Informe o KM de saida para iniciar a viagem.',
      );
    }
    if (!checklistPreUsoConcluido) {
      throw const LogisticaValidationException(
        'Conclua o checklist pre-uso para iniciar a viagem.',
      );
    }
  }

  static void validarInicioRetorno(
    List<LogisticaPassageiroViagem> passageiros,
  ) {
    final pendentes = passageiros.where((item) => !item.voltouOuJustificou);
    if (pendentes.isNotEmpty) {
      throw const LogisticaValidationException(
        'Todos os pacientes devem estar embarcados ou justificados.',
      );
    }
  }

  static void validarConclusaoViagem({required double? kmFinal}) {
    if (kmFinal == null || kmFinal <= 0) {
      throw const LogisticaValidationException(
        'Informe o KM final para concluir a viagem.',
      );
    }
  }

  static void validarAbastecimento({
    required double litros,
    required double valor,
  }) {
    if (litros <= 0) {
      throw const LogisticaValidationException(
        'Abastecimento deve ter litros maior que zero.',
      );
    }
    if (valor < 0) {
      throw const LogisticaValidationException(
        'Abastecimento nao pode ter valor negativo.',
      );
    }
  }

  static void validarOcorrencia({
    required TipoOcorrencia? tipo,
    required DateTime? dataHora,
  }) {
    if (tipo == null) {
      throw const LogisticaValidationException('Ocorrencia deve ter tipo.');
    }
    if (dataHora == null) {
      throw const LogisticaValidationException(
        'Ocorrencia deve ter data e hora.',
      );
    }
  }
}
