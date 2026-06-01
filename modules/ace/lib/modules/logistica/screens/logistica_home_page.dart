import 'package:flutter/material.dart';

import '../../../core/app_info.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../screens/auditoria_page.dart';
import '../../../screens/login_page.dart';
import '../../../screens/server_config_page.dart';
import '../../../screens/sync_center_page.dart';
import '../../../services/theme_mode_service.dart';
import '../../dashboard/screens/plataforma_dashboard_page.dart';
import '../../mapas_territoriais/screens/mapas_territoriais_page.dart';
import '../../pacientes/screens/pacientes_page.dart';
import '../../rastreamento/screens/rastreamento_viagem_page.dart';
import '../../transportes/screens/transportes_page.dart';

class LogisticaHomePage extends StatefulWidget {
  final String? usuario;
  final String? municipio;
  final ThemeModeService themeModeService;

  const LogisticaHomePage({
    super.key,
    required this.themeModeService,
    this.usuario,
    this.municipio,
  });

  @override
  State<LogisticaHomePage> createState() => _LogisticaHomePageState();
}

class _LogisticaHomePageState extends State<LogisticaHomePage> {
  int currentIndex = 0;

  late final pages = <Widget>[
    const PlataformaDashboardPage(embed: true),
    const TransportesPage(embed: true),
    const PacientesPage(embed: true),
    const RastreamentoViagemPage(embed: true),
    const SyncCenterPage(),
  ];

  void abrir(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  void sair() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => LoginPage(
          onEntrar: (context, agente, municipio) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => LogisticaHomePage(
                  usuario: agente,
                  municipio: municipio,
                  themeModeService: widget.themeModeService,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _LogisticaDrawer(
        usuario: widget.usuario,
        municipio: widget.municipio,
        themeModeService: widget.themeModeService,
        onOpen: abrir,
        onLogout: sair,
      ),
      appBar: AppBar(
        title: const Text(AppInfo.nome),
        actions: [
          IconButton(
            tooltip: 'Servidor',
            onPressed: () => abrir(const ServerConfigPage()),
            icon: const Icon(Icons.dns),
          ),
          IconButton(
            tooltip: 'Sair',
            onPressed: sair,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: IndexedStack(index: currentIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          setState(() => currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Painel',
          ),
          NavigationDestination(
            icon: Icon(Icons.route_outlined),
            selectedIcon: Icon(Icons.route),
            label: 'Viagens',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Pacientes',
          ),
          NavigationDestination(
            icon: Icon(Icons.gps_fixed_outlined),
            selectedIcon: Icon(Icons.gps_fixed),
            label: 'Rastreio',
          ),
          NavigationDestination(
            icon: Icon(Icons.cloud_sync_outlined),
            selectedIcon: Icon(Icons.cloud_sync),
            label: 'Sync',
          ),
        ],
      ),
    );
  }
}

class _LogisticaDrawer extends StatelessWidget {
  final String? usuario;
  final String? municipio;
  final ThemeModeService themeModeService;
  final ValueChanged<Widget> onOpen;
  final VoidCallback onLogout;

  const _LogisticaDrawer({
    required this.usuario,
    required this.municipio,
    required this.themeModeService,
    required this.onOpen,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              color: AppColors.primary,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(Icons.local_shipping, color: AppColors.primary),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Text(
                    AppInfo.nome,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    municipio ?? 'Municipio local',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  Text(
                    usuario ?? 'Operador local',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  _item(
                    context,
                    Icons.directions_bus,
                    'Transportes e viagens',
                    const TransportesPage(),
                  ),
                  _item(
                    context,
                    Icons.people,
                    'Pacientes transportados',
                    const PacientesPage(),
                  ),
                  _item(
                    context,
                    Icons.gps_fixed,
                    'Rastreio GPS em tempo real',
                    const RastreamentoViagemPage(),
                  ),
                  _item(context, Icons.map, 'Mapa de rota', const MapasTerritoriaisPage()),
                  const Divider(),
                  _item(
                    context,
                    Icons.dns,
                    'Servidor',
                    const ServerConfigPage(),
                  ),
                  _item(
                    context,
                    Icons.cloud_sync,
                    'Central de sync',
                    const SyncCenterPage(),
                  ),
                  _item(
                    context,
                    Icons.manage_search,
                    'Auditoria',
                    const AuditoriaPage(),
                  ),
                  _ThemeModeTile(service: themeModeService),
                  ListTile(
                    leading: const Icon(Icons.logout, color: AppColors.primary),
                    title: const Text('Sair'),
                    onTap: onLogout,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _item(BuildContext context, IconData icon, String title, Widget page) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        onOpen(page);
      },
    );
  }
}

class _ThemeModeTile extends StatelessWidget {
  final ThemeModeService service;

  const _ThemeModeTile({required this.service});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: service,
      builder: (context, _) {
        return ListTile(
          leading: const Icon(Icons.contrast, color: AppColors.primary),
          title: const Text('Aparencia'),
          subtitle: Text(service.label),
          trailing: PopupMenuButton<ThemeMode>(
            initialValue: service.themeMode,
            onSelected: service.alterar,
            itemBuilder: (context) => const [
              PopupMenuItem(value: ThemeMode.system, child: Text('Automatico')),
              PopupMenuItem(value: ThemeMode.light, child: Text('Claro')),
              PopupMenuItem(value: ThemeMode.dark, child: Text('Escuro')),
            ],
          ),
        );
      },
    );
  }
}
