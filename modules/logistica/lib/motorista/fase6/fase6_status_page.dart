import 'package:flutter/material.dart';

import '../../core/logistica/integracoes/logistica_external_integration.dart';
import '../../core/logistica/integracoes/logistica_sus_compatibility.dart';
import '../../core/logistica/manutencao/logistica_manutencao_frota.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../widgets/dashboard_card.dart';
import '../../widgets/section_header.dart';

class Fase6StatusPage extends StatelessWidget {
  const Fase6StatusPage({super.key});

  @override
  Widget build(BuildContext context) {
    final queue = LogisticaExternalDispatchQueue(
      gateway: LogisticaWebhookSimulationGateway(),
    )..enqueue(
        destino: LogisticaExternalDestination.seguradora,
        tipoEvento: 'ocorrencia_preparada',
        payload: {'modo': 'simulado', 'origem': 'fase_6'},
        createdAt: DateTime(2026, 6, 2, 8),
      );

    final whatsapp = LogisticaWhatsappSimulationService()
      ..registrarMensagem(
        casoUso: LogisticaWhatsappUseCase.alertaGestor,
        destinatario: 'gestor-demo',
        mensagem: 'Ocorrencia logistica preparada para notificacao futura.',
        now: DateTime(2026, 6, 2, 8, 5),
      );

    final susPendencias = LogisticaSusCompatibility.validate(
      LogisticaSusAuditRecord(
        cns: '898001160000001',
        cpf: '12345678901',
        paciente: 'Paciente demo',
        unidadeSaude: 'Unidade demo',
        procedimentoConsulta: 'Consulta demo',
        data: DateTime(2026, 6, 2),
        destino: 'Hospital demo',
        comprovante: 'comprovante-demo.jpg',
        presenca: true,
        acompanhante: 'Acompanhante demo',
      ),
    );

    final frota = const LogisticaFleetMaintenancePolicy().evaluate(
      LogisticaFleetMaintenanceSnapshot(
        veiculoId: 'vei-demo',
        placa: 'DEMO6A0',
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

    return Scaffold(
      appBar: AppBar(title: const Text('Fase 6 - Logistica')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.primaryDark,
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Integracoes futuras preparadas',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: AppSpacing.xs),
                Text(
                  'Simulacoes locais para teste controlado, sem APIs reais.',
                  style: TextStyle(color: Color(0xFFD9F0E4)),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(
            title: 'Camadas preparadas',
            subtitle: 'Estruturas tecnicas incluidas no APK desta versao.',
          ),
          DashboardCard(
            icon: Icons.webhook,
            title: 'Webhook externo',
            value: queue.items.first.status.name,
            subtitle: 'Seguradora, guincho e assistencia em modo simulado.',
          ),
          const SizedBox(height: AppSpacing.sm),
          DashboardCard(
            icon: Icons.chat,
            title: 'WhatsApp operacional',
            value: whatsapp.messages.first.simulado ? 'Simulado' : 'Real',
            subtitle: 'Log interno sem disparo real de mensagem.',
          ),
          const SizedBox(height: AppSpacing.sm),
          DashboardCard(
            icon: Icons.local_hospital,
            title: 'Compatibilidade SUS',
            value: susPendencias.isEmpty ? 'Completa' : 'Com pendencias',
            subtitle: 'Campos de auditoria preparados para transporte.',
          ),
          const SizedBox(height: AppSpacing.sm),
          DashboardCard(
            icon: Icons.car_repair,
            title: 'Manutencao preventiva',
            value: frota.bloqueioOperacional ? 'Bloqueado' : 'Liberado',
            subtitle: frota.alertas.isEmpty
                ? 'Sem alertas.'
                : 'Alertas: ${frota.alertas.join(', ')}',
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(
            title: 'Regras de seguranca',
            subtitle: 'O que permanece bloqueado ate autorizacao formal.',
          ),
          const _RuleTile('Sem API real de seguradora nesta fase.'),
          const _RuleTile('Sem envio real de WhatsApp nesta fase.'),
          const _RuleTile('Sem integracao oficial SUS nesta fase.'),
          const _RuleTile('WebSocket depende de VPS ou infraestrutura adequada.'),
        ],
      ),
    );
  }
}

class _RuleTile extends StatelessWidget {
  final String text;

  const _RuleTile(this.text);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.verified_user, color: AppColors.primary),
        title: Text(text),
      ),
    );
  }
}
