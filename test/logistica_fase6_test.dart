import 'package:flutter_test/flutter_test.dart';
import 'package:plataforma_logistica_driver/core/logistica/integracoes/logistica_external_integration.dart';
import 'package:plataforma_logistica_driver/core/logistica/integracoes/logistica_sus_compatibility.dart';
import 'package:plataforma_logistica_driver/core/logistica/manutencao/logistica_manutencao_frota.dart';

void main() {
  group('webhook seguradora e assistencia', () {
    test('cria envio simulado aguardando envio e registra log', () {
      final gateway = LogisticaWebhookSimulationGateway();
      final queue = LogisticaExternalDispatchQueue(gateway: gateway);

      final item = queue.enqueue(
        destino: LogisticaExternalDestination.seguradora,
        tipoEvento: 'pane_mecanica',
        payload: {'viagem_id': 'via-1', 'placa': 'ABC1D23'},
        createdAt: DateTime(2026, 6, 2, 9),
      );

      expect(item.status, LogisticaExternalDispatchStatus.aguardandoEnvio);
      expect(item.destination, LogisticaExternalDestination.seguradora);
      expect(queue.logs.single.message, contains('aguardando envio'));
    });

    test('reenvia falha simulada e depois marca como enviado', () async {
      final gateway = LogisticaWebhookSimulationGateway(
        failuresBeforeSuccess: 1,
      );
      final queue = LogisticaExternalDispatchQueue(gateway: gateway);
      final item = queue.enqueue(
        destino: LogisticaExternalDestination.assistenciaTecnica,
        tipoEvento: 'guincho',
        payload: {'viagem_id': 'via-2'},
        createdAt: DateTime(2026, 6, 2, 9),
      );

      final first = await queue.processNext(now: DateTime(2026, 6, 2, 9, 1));
      final second = await queue.processNext(now: DateTime(2026, 6, 2, 9, 2));

      expect(first.id, item.id);
      expect(first.status, LogisticaExternalDispatchStatus.erro);
      expect(first.attempts, 1);
      expect(second.status, LogisticaExternalDispatchStatus.enviado);
      expect(second.attempts, 2);
    });
  });

  group('whatsapp operacional simulado', () {
    test('registra mensagem interna sem disparo real', () {
      final service = LogisticaWhatsappSimulationService();

      final message = service.registrarMensagem(
        casoUso: LogisticaWhatsappUseCase.alertaGestor,
        destinatario: '+5551999999999',
        mensagem: 'Ocorrencia registrada na viagem via-1.',
        now: DateTime(2026, 6, 2, 10),
      );

      expect(message.simulado, isTrue);
      expect(message.disparoRealExecutado, isFalse);
      expect(service.logs.single.message, contains('simulado'));
    });
  });

  group('compatibilidade SUS', () {
    test('valida campos obrigatorios de auditoria', () {
      final record = LogisticaSusAuditRecord(
        cns: '898001160000001',
        cpf: '12345678901',
        paciente: 'Maria Teste',
        unidadeSaude: 'Hospital Municipal',
        procedimentoConsulta: 'Consulta cardiologia',
        data: DateTime(2026, 6, 2),
        destino: 'Hospital Municipal',
        comprovante: 'sus-1.jpg',
        presenca: true,
        acompanhante: 'Joao Teste',
      );

      expect(LogisticaSusCompatibility.validate(record), isEmpty);
      expect(record.toPayload()['cns'], '898001160000001');
    });

    test('aponta pendencias quando campo obrigatorio esta ausente', () {
      final record = LogisticaSusAuditRecord(
        cns: '',
        cpf: '12345678901',
        paciente: 'Maria Teste',
        unidadeSaude: '',
        procedimentoConsulta: 'Consulta',
        data: DateTime(2026, 6, 2),
        destino: 'Hospital',
        comprovante: null,
        presenca: true,
        acompanhante: null,
      );

      final pendencias = LogisticaSusCompatibility.validate(record);

      expect(pendencias, contains('cns'));
      expect(pendencias, contains('unidadeSaude'));
      expect(pendencias, contains('comprovante'));
    });
  });

  group('manutencao preventiva da frota', () {
    test('bloqueia veiculo com documento vencido', () {
      final policy = LogisticaFleetMaintenancePolicy();
      final status = policy.evaluate(
        LogisticaFleetMaintenanceSnapshot(
          veiculoId: 'vei-1',
          placa: 'ABC1D23',
          kmAtual: 52000,
          proximaRevisaoKm: 60000,
          proximaTrocaOleoKm: 55000,
          vencimentoDocumento: DateTime(2026, 5, 30),
          vencimentoSeguro: DateTime(2026, 12, 31),
          vencimentoCnhMotorista: DateTime(2026, 12, 31),
          pneusRevisaoPendente: false,
        ),
        now: DateTime(2026, 6, 2),
      );

      expect(status.bloqueioOperacional, isTrue);
      expect(status.alertas, contains('documento_vencido'));
    });

    test('gera alerta preventivo por revisao aproximando', () {
      final policy = LogisticaFleetMaintenancePolicy();
      final status = policy.evaluate(
        LogisticaFleetMaintenanceSnapshot(
          veiculoId: 'vei-2',
          placa: 'DEF4G56',
          kmAtual: 59550,
          proximaRevisaoKm: 60000,
          proximaTrocaOleoKm: 65000,
          vencimentoDocumento: DateTime(2026, 12, 31),
          vencimentoSeguro: DateTime(2026, 12, 31),
          vencimentoCnhMotorista: DateTime(2026, 12, 31),
          pneusRevisaoPendente: false,
        ),
        now: DateTime(2026, 6, 2),
      );

      expect(status.bloqueioOperacional, isFalse);
      expect(status.alertas, contains('revisao_proxima'));
    });
  });
}
