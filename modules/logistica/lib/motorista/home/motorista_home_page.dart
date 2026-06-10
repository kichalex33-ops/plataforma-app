import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/motorista_login_page.dart';
import '../../auth/motorista_model.dart';
import '../../auth/motorista_session.dart';
import '../../core/api/driver_api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../motorista/eventos/eventos_pendentes_page.dart';
import '../../motorista/fase6/fase6_status_page.dart';
import '../../models/trip_model.dart';
import 'current_trip_controller.dart';
import '../../motorista/operacional/logistica_fluxo_viagem_pages.dart';
import '../../motorista/sync/driver_sync_panel.dart';
import '../../motorista/sync/driver_sync_service.dart';
import '../../services/theme_mode_service.dart';
import '../../widgets/dashboard_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/sync_status_card.dart';

class MotoristaHomePage extends StatefulWidget {
  final MotoristaModel? motorista;
  final ThemeModeService? themeModeService;
  final MotoristaSession session;
  final VoidCallback? onSair;

  MotoristaHomePage({
    super.key,
    this.motorista,
    this.themeModeService,
    this.onSair,
    MotoristaSession? session,
  }) : session = session ?? MotoristaSession();

  @override
  State<MotoristaHomePage> createState() => _MotoristaHomePageState();
}

class _MotoristaHomePageState extends State<MotoristaHomePage> {
  DriverSyncStatus _statusSync = const DriverSyncStatus(online: false);
  late final CurrentTripController _currentTripController;
  final DriverApiClient _apiClient = DriverApiClient();
  final Set<String> _avisosMostrados = {};

  @override
  void initState() {
    super.initState();
    _currentTripController = CurrentTripController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _currentTripController.load(_motoristaAtual.id);
      _carregarAvisosImportantes();
    });
  }

  Future<void> _carregarAvisosImportantes() async {
    final avisos = await _apiClient.buscarAvisosCentral(_motoristaAtual.id);
    if (!mounted || avisos.isEmpty) return;

    for (final aviso in avisos) {
      final id = aviso['id']?.toString() ?? aviso.hashCode.toString();
      if (_avisosMostrados.contains(id)) continue;
      _avisosMostrados.add(id);
      await _mostrarAvisoMensagem(aviso);
      if (!mounted) return;
    }
  }

  Future<void> _mostrarAvisoMensagem(Map<String, dynamic> data) async {
    final titulo = data['titulo']?.toString().trim().isNotEmpty == true
        ? data['titulo'].toString()
        : 'Aviso importante';
    final texto = (data['texto'] ?? data['mensagem'] ?? data['descricao'] ?? '')
        .toString()
        .trim();
    final enviadoEm = DateTime.now();
    final horario =
        '${enviadoEm.hour.toString().padLeft(2, '0')}:${enviadoEm.minute.toString().padLeft(2, '0')}';

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.campaign, color: Color(0xFF003366)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                titulo,
                style: const TextStyle(color: Color(0xFF003366)),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              texto.isEmpty
                  ? 'A central enviou uma orientacao operacional.'
                  : texto,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            Text(
              'Enviado as: $horario',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF003366),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'ENTENDIDO / LIDO',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarIndisponivel(BuildContext context, String recurso) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$recurso sera conectado nas proximas etapas.')),
    );
  }

  MotoristaModel get _motoristaAtual {
    return widget.motorista ??
        const MotoristaModel(
          id: 'motorista-local',
          nome: 'Motorista local',
          municipio: 'Municipio local',
        );
  }

  Future<void> _sair(BuildContext context) async {
    await widget.session.limpar();
    if (!context.mounted) return;
    if (widget.onSair != null) {
      widget.onSair!();
      return;
    }

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

  void _enviarSos() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Alerta SOS registrado. A central sera notificada.'),
        backgroundColor: Color(0xFFD32F2F),
      ),
    );
  }

  @override
  void dispose() {
    _currentTripController.dispose();
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
        : 'Municipio local';

    return ChangeNotifierProvider<CurrentTripController>.value(
      value: _currentTripController,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Motorista'),
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
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.md,
          ),
          child: _SosButton(onLongPress: _enviarSos),
        ),
        body: ListView(
          padding: EdgeInsets.zero,
          children: [
            _DriverHeader(
              nome: nomeMotorista,
              veiculo: 'Plataforma Logistica',
              online: _statusSync.online,
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  _SignalStatusCard(
                    online: _statusSync.online,
                    pending: _statusSync.pendentes,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Consumer<CurrentTripController>(
                    builder: (context, controller, _) {
                      return ActiveTripCard(
                        trip: controller.trip,
                        loading: controller.loading,
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _ActionGrid(
                    onViagens: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const LogisticaViagensAtribuidasPage(),
                        ),
                      );
                    },
                    onContinuar: () =>
                        _mostrarIndisponivel(context, 'Continuar viagem'),
                    onEventos: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EventosPendentesPage(),
                        ),
                      );
                    },
                    onIntegracoes: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const Fase6StatusPage(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const SectionHeader(
                    title: 'Resumo operacional',
                    subtitle: 'Dados do motorista e da operacao local.',
                  ),
                  DashboardCard(
                    icon: Icons.badge,
                    title: 'Motorista logado',
                    value: nomeMotorista,
                    subtitle: nomeMunicipio,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const DashboardCard(
                    icon: Icons.event_available,
                    title: 'Proximas viagens',
                    value: 'Aguardando atribuicoes',
                    subtitle: 'Viagens sao criadas pelo painel web.',
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SyncStatusCard(
                    online: _statusSync.online,
                    title: 'Sincronizacao',
                    description: _statusSync.resumoSync,
                    lastSync: _statusSync.ultimoSync,
                    pending: _statusSync.pendentes,
                    child: DriverSyncPanel(
                      onStatusChanged: (status) {
                        if (!mounted) return;
                        setState(() => _statusSync = status);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DriverHeader extends StatelessWidget {
  final String nome;
  final String veiculo;
  final bool online;

  const _DriverHeader({
    required this.nome,
    required this.veiculo,
    required this.online,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      decoration: const BoxDecoration(
        color: Color(0xFF003366),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 26,
            backgroundColor: Colors.white24,
            child: Icon(Icons.person, color: Colors.white, size: 30),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ola, $nome',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(veiculo, style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          Icon(
            online ? Icons.wifi : Icons.wifi_off,
            color: online ? Colors.greenAccent : Colors.redAccent,
          ),
        ],
      ),
    );
  }
}

class _SignalStatusCard extends StatelessWidget {
  final bool online;
  final int pending;

  const _SignalStatusCard({required this.online, required this.pending});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatItem(
              icon: Icons.speed,
              value: '0 km/h',
              label: 'Velocidade',
              color: AppColors.primaryDark,
            ),
            _StatItem(
              icon: Icons.location_on,
              value: online ? 'Ativo' : 'Offline',
              label: 'GPS',
              color: online ? Colors.green.shade700 : Colors.red.shade700,
            ),
            _StatItem(
              icon: Icons.sync,
              value: pending.toString(),
              label: 'Pendentes',
              color: pending > 0 ? Colors.orange.shade800 : AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class ActiveTripCard extends StatelessWidget {
  final Trip? trip;
  final bool loading;

  const ActiveTripCard({super.key, this.trip, this.loading = false});

  @override
  Widget build(BuildContext context) {
    final currentTrip = trip;
    final isLate = currentTrip?.isLate ?? false;
    final cardColor = isLate
        ? const Color(0xFFFF8C00)
        : const Color(0xFF007BFF);
    final secondaryColor = isLate
        ? const Color(0xFFE67E22)
        : const Color(0xFF0056B3);
    final progress = currentTrip?.progress ?? 0.0;
    final title = currentTrip?.destination ?? 'Nenhuma viagem em andamento';
    final subtitle = loading
        ? 'Buscando viagem ativa...'
        : currentTrip == null
        ? 'Abra Minhas viagens para iniciar ou continuar uma rota.'
        : isLate
        ? 'Verifique o transito'
        : 'No horario';
    final footerStatus = currentTrip == null ? 'Aguardando saida' : subtitle;
    final showSubtitleUnderTitle = loading || currentTrip == null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [cardColor, secondaryColor]),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          if (isLate)
            BoxShadow(
              color: Colors.orange.withValues(alpha: 0.4),
              blurRadius: 15,
              spreadRadius: 2,
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'VIAGEM ATIVA',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (isLate)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'ATRASADO',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (showSubtitleUnderTitle) ...[
            const SizedBox(height: 6),
            Text(subtitle, style: const TextStyle(color: Colors.white70)),
          ],
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white24,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${(progress * 100).toInt()}% concluido',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  footerStatus,
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionGrid extends StatelessWidget {
  final VoidCallback onViagens;
  final VoidCallback onContinuar;
  final VoidCallback onEventos;
  final VoidCallback onIntegracoes;

  const _ActionGrid({
    required this.onViagens,
    required this.onContinuar,
    required this.onEventos,
    required this.onIntegracoes,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: AppSpacing.md,
      mainAxisSpacing: AppSpacing.md,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.16,
      children: [
        _LargeActionButton(
          icon: Icons.route,
          label: 'Minhas viagens',
          color: Colors.green.shade700,
          onTap: onViagens,
        ),
        _LargeActionButton(
          icon: Icons.play_circle_fill,
          label: 'Iniciar rota',
          color: Colors.blue.shade700,
          onTap: onContinuar,
        ),
        _LargeActionButton(
          icon: Icons.pending_actions,
          label: 'Pendentes',
          color: Colors.orange.shade800,
          onTap: onEventos,
        ),
        _LargeActionButton(
          icon: Icons.hub,
          label: 'Integracoes',
          color: Colors.purple.shade700,
          onTap: onIntegracoes,
        ),
      ],
    );
  }
}

class _LargeActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _LargeActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 42),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textStrong,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SosButton extends StatelessWidget {
  final VoidCallback onLongPress;

  const _SosButton({required this.onLongPress});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: const Color(0xFFD32F2F),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD32F2F).withValues(alpha: 0.24),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning, color: Colors.white),
            SizedBox(width: 10),
            Text(
              'SEGURE PARA SOS',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
          ],
        ),
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
