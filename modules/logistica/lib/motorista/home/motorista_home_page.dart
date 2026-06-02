import 'package:flutter/material.dart';

import '../../auth/motorista_login_page.dart';
import '../../auth/motorista_model.dart';
import '../../auth/motorista_session.dart';
import '../../core/app_info.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../motorista/eventos/eventos_pendentes_page.dart';
import '../../motorista/fase6/fase6_status_page.dart';
import '../../motorista/operacional/logistica_fluxo_viagem_pages.dart';
import '../../motorista/simulacao/corrida_simulada_service.dart';
import '../../motorista/sync/driver_sync_panel.dart';
import '../../motorista/sync/driver_sync_service.dart';
import '../../services/theme_mode_service.dart';
import '../../widgets/dashboard_card.dart';
import '../../widgets/quick_action_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/sync_status_card.dart';

class MotoristaHomePage extends StatefulWidget {
  final MotoristaModel? motorista;
  final ThemeModeService? themeModeService;
  final MotoristaSession session;

  MotoristaHomePage({
    super.key,
    this.motorista,
    this.themeModeService,
    MotoristaSession? session,
  }) : session = session ?? MotoristaSession();

  @override
  State<MotoristaHomePage> createState() => _MotoristaHomePageState();
}

class _MotoristaHomePageState extends State<MotoristaHomePage> {
  DriverSyncStatus _statusSync = const DriverSyncStatus(online: false);
  final CorridaSimuladaService _simulacaoService = CorridaSimuladaService();

  void _mostrarIndisponivel(BuildContext context, String recurso) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$recurso será conectado nas próximas etapas.')),
    );
  }

  MotoristaModel get _motoristaAtual {
    return widget.motorista ??
        const MotoristaModel(
          id: 'motorista-local',
          nome: 'Motorista local',
          municipio: 'Município local',
        );
  }

  Future<void> _sair(BuildContext context) async {
    await widget.session.limpar();
    if (!context.mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => MotoristaLoginPage(
          themeModeService: widget.themeModeService,
          onEntrar: (loginContext, novoMotorista) {
            Navigator.pushReplacement(
              loginContext,
              MaterialPageRoute(
                builder: (_) => MotoristaHomePage(
                  motorista: novoMotorista,
                  themeModeService: widget.themeModeService,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _iniciarSimulacao(MotoristaModel motorista) async {
    await _simulacaoService.iniciar(motorista);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Simulação de corrida iniciada por 5 minutos.'),
      ),
    );
  }

  @override
  void dispose() {
    _simulacaoService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final motoristaAtual = _motoristaAtual;
    final nomeMotorista = motoristaAtual.nome.trim().isNotEmpty
        ? motoristaAtual.nome.trim()
        : 'Motorista local';
    final nomeMunicipio = motoristaAtual.municipio.trim().isNotEmpty
        ? motoristaAtual.municipio.trim()
        : 'Município local';

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppInfo.nome),
        actions: [
          if (widget.themeModeService != null)
            _ThemeModeAction(service: widget.themeModeService!),
          IconButton(
            tooltip: 'Sair',
            onPressed: () => _sair(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.primaryDark,
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Logística',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '$nomeMotorista | $nomeMunicipio',
                  style: const TextStyle(color: Color(0xFFD9F0E4)),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(
            title: 'Resumo operacional',
            subtitle: 'Status atual do motorista e das viagens atribuídas.',
          ),
          DashboardCard(
            icon: Icons.badge,
            title: 'Motorista logado',
            value: nomeMotorista,
            subtitle: nomeMunicipio,
          ),
          const SizedBox(height: AppSpacing.sm),
          const DashboardCard(
            icon: Icons.route,
            title: 'Viagem atual',
            value: 'Nenhuma em andamento',
            subtitle: 'Use minhas viagens para iniciar ou continuar.',
          ),
          const SizedBox(height: AppSpacing.sm),
          const DashboardCard(
            icon: Icons.event_available,
            title: 'Próximas viagens',
            value: 'Aguardando atribuições',
            subtitle: 'Viagens sao criadas pelo painel web.',
          ),
          const SizedBox(height: AppSpacing.lg),
          SyncStatusCard(
            online: _statusSync.online,
            title: 'Sincronizacao',
            description: _statusSync.resumoSync,
            lastSync: _statusSync.ultimoSync,
            child: DriverSyncPanel(
              onStatusChanged: (status) {
                if (!mounted) return;
                setState(() => _statusSync = status);
              },
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(
            title: 'Acoes rapidas',
            subtitle: 'Atalhos reais do fluxo operacional do motorista.',
          ),
          QuickActionCard(
            icon: Icons.route,
            title: 'Ver minhas viagens',
            subtitle: 'Fluxo operacional completo da viagem sanitária.',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const LogisticaViagensAtribuidasPage(),
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          QuickActionCard(
            icon: Icons.play_arrow,
            title: 'Continuar viagem',
            subtitle: 'Retomar a execução operacional em andamento.',
            onTap: () => _mostrarIndisponivel(context, 'Continuar viagem'),
          ),
          const SizedBox(height: AppSpacing.sm),
          QuickActionCard(
            icon: Icons.pending_actions,
            title: 'Eventos pendentes',
            subtitle: 'Conferir registros offline aguardando envio.',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EventosPendentesPage()),
              );
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          QuickActionCard(
            icon: Icons.hub,
            title: 'Fase 6 - Integracoes',
            subtitle: 'Webhook, WhatsApp, SUS e frota em modo preparado.',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const Fase6StatusPage()),
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          AnimatedBuilder(
            animation: _simulacaoService,
            builder: (context, _) {
              final status = _simulacaoService.status;
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.navigation,
                            color: status.rodando
                                ? Colors.green.shade800
                                : AppColors.primary,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Simulação de corrida',
                                  style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  status.resumo,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      FilledButton.icon(
                        onPressed: status.rodando
                            ? null
                            : () => _iniciarSimulacao(motoristaAtual),
                        icon: const Icon(Icons.play_circle),
                        label: const Text('Simular corrida 5 min'),
                      ),
                      if (status.rodando) ...[
                        const SizedBox(height: AppSpacing.sm),
                        OutlinedButton.icon(
                          onPressed: _simulacaoService.cancelar,
                          icon: const Icon(Icons.stop_circle),
                          label: const Text('Cancelar simulação'),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ThemeModeAction extends StatelessWidget {
  final ThemeModeService service;

  const _ThemeModeAction({required this.service});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: service,
      builder: (context, _) {
        return PopupMenuButton<ThemeMode>(
          tooltip: 'Tema',
          icon: Icon(
            service.themeMode == ThemeMode.dark
                ? Icons.dark_mode
                : Icons.light_mode,
          ),
          initialValue: service.themeMode,
          onSelected: service.alterar,
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: ThemeMode.light,
              child: ListTile(
                leading: Icon(Icons.light_mode),
                title: Text('Modo claro'),
              ),
            ),
            PopupMenuItem(
              value: ThemeMode.dark,
              child: ListTile(
                leading: Icon(Icons.dark_mode),
                title: Text('Modo escuro'),
              ),
            ),
            PopupMenuItem(
              value: ThemeMode.system,
              child: ListTile(
                leading: Icon(Icons.settings_suggest),
                title: Text('Sistema'),
              ),
            ),
          ],
        );
      },
    );
  }
}
