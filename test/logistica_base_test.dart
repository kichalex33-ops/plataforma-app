import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:plataforma_logistica_driver/core/logistica/logistica_calculator.dart';
import 'package:plataforma_logistica_driver/core/logistica/logistica_enums.dart';
import 'package:plataforma_logistica_driver/core/logistica/logistica_models.dart';
import 'package:plataforma_logistica_driver/core/logistica/logistica_offline_queue.dart';
import 'package:plataforma_logistica_driver/core/logistica/logistica_validators.dart';

void main() {
  group('validacoes de KM', () {
    test('KM final menor que inicial deve falhar', () {
      expect(
        () => LogisticaValidators.validarKmFinal(kmInicial: 200, kmFinal: 150),
        throwsA(isA<LogisticaValidationException>()),
      );
    });

    test('KM final muito divergente marca pendente de revisao', () {
      final result = LogisticaValidators.validarKmFinal(
        kmInicial: 100,
        kmFinal: 250,
        kmEsperado: 50,
      );

      expect(result.valido, isTrue);
      expect(result.pendenteRevisao, isTrue);
    });
  });

  group('calculadora logistica', () {
    test('calcula km rodado', () {
      expect(LogisticaCalculator.kmRodado(kmInicial: 1000, kmFinal: 1125), 125);
    });

    test('calcula valor por litro', () {
      expect(LogisticaCalculator.valorPorLitro(valor: 250, litros: 50), 5);
    });

    test('calcula custo por paciente', () {
      expect(
        LogisticaCalculator.custoPorPaciente(
          totalDespesas: 300,
          pacientesTransportados: 6,
        ),
        50,
      );
    });
  });

  group('status e pacientes', () {
    test('status da viagem serializa para snake case', () {
      expect(StatusViagem.saidaConfirmada.dbValue, 'saida_confirmada');
      expect(StatusViagem.pendenteRevisao.dbValue, 'pendente_revisao');
    });

    test('conta ausentes e desistentes', () {
      final now = DateTime(2026, 6, 2);
      final passageiros = [
        _passageiro('1', StatusPacienteIda.embarcado, now),
        _passageiro('2', StatusPacienteIda.ausente, now),
        _passageiro('3', StatusPacienteIda.desistiu, now),
      ];

      expect(LogisticaCalculator.ausentesOuDesistentes(passageiros), 2);
    });

    test('inicio de retorno falha com paciente pendente', () {
      final now = DateTime(2026, 6, 2);
      final passageiros = [_passageiro('1', StatusPacienteIda.embarcado, now)];

      expect(
        () => LogisticaValidators.validarInicioRetorno(passageiros),
        throwsA(isA<LogisticaValidationException>()),
      );
    });
  });

  group('abastecimento e ocorrencia', () {
    test('abastecimento com litros zero deve falhar', () {
      expect(
        () => LogisticaValidators.validarAbastecimento(litros: 0, valor: 10),
        throwsA(isA<LogisticaValidationException>()),
      );
    });

    test('ocorrencia sem data deve falhar', () {
      expect(
        () => LogisticaValidators.validarOcorrencia(
          tipo: TipoOcorrencia.atraso,
          dataHora: null,
        ),
        throwsA(isA<LogisticaValidationException>()),
      );
    });
  });

  group('fila offline', () {
    test('cria item pendente de sincronizacao', () {
      final queue = LogisticaOfflineQueue();
      final item = queue.criarItem(
        tipoEvento: TipoEventoSync.pacienteAusente,
        payload: {'viagem_id': 'via-1', 'paciente_id': 'pac-1'},
        now: DateTime(2026, 6, 2),
      );

      expect(item.tipoEvento, TipoEventoSync.pacienteAusente);
      expect(item.statusSync, StatusSync.pendente);
      expect(jsonDecode(item.payloadJson)['paciente_id'], 'pac-1');
    });

    test('registra tentativa com erro', () {
      final queue = LogisticaOfflineQueue();
      final item = queue.criarItem(
        tipoEvento: TipoEventoSync.viagemConcluida,
        payload: {'viagem_id': 'via-1'},
        now: DateTime(2026, 6, 2),
      );

      final retry = queue.marcarTentativa(
        item,
        now: DateTime(2026, 6, 2, 10),
        erro: 'sem conexao',
      );

      expect(retry.tentativas, 1);
      expect(retry.statusSync, StatusSync.erro);
      expect(retry.erro, 'sem conexao');
    });
  });
}

LogisticaPassageiroViagem _passageiro(
  String id,
  StatusPacienteIda status,
  DateTime now,
) {
  return LogisticaPassageiroViagem(
    idLocal: id,
    createdAt: now,
    updatedAt: now,
    viagemIdLocal: 'via-1',
    pacienteIdLocal: 'pac-$id',
    statusIda: status,
  );
}
