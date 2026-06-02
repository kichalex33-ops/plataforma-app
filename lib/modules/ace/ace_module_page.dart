import 'package:controle_ace/core/theme/app_colors.dart' as ace_colors;
import 'package:controle_ace/core/theme/app_theme.dart' as ace_theme;
import 'package:controle_ace/database/database_platform.dart' as ace_db;
import 'package:controle_ace/modules/mapa/mapa_real_page.dart';
import 'package:controle_ace/screens/areas_prioritarias_page.dart';
import 'package:controle_ace/screens/bti_page.dart';
import 'package:controle_ace/screens/lira_lia_page.dart';
import 'package:controle_ace/screens/ovitrampas_page.dart';
import 'package:controle_ace/screens/pe_page.dart';
import 'package:controle_ace/screens/quarteiroes_page.dart';
import 'package:controle_ace/screens/relatorios_page.dart';
import 'package:controle_ace/screens/sync_center_page.dart';
import 'package:controle_ace/screens/territorio_supervisor_page.dart';
import 'package:controle_ace/screens/visitas_domiciliares_page.dart';
import 'package:flutter/material.dart';

class AceModulePage extends StatefulWidget {
  const AceModulePage({super.key});

  @override
  State<AceModulePage> createState() => _AceModulePageState();
}

class _AceModulePageState extends State<AceModulePage> {
  late final Future<void> _bootstrap = ace_db.configurarBancoPorPlataforma();
  int _index = 0;

  static const _pages = <Widget>[
    PEPage(),
    VisitasDomiciliaresPage(),
    QuarteiroesPage(),
    MapaRealPage(),
    RelatoriosPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _bootstrap,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('ACE')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Erro ao abrir ACE: ${snapshot.error}'),
              ),
            ),
          );
        }

        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Theme(
          data: ace_theme.AppTheme.theme,
          child: Scaffold(
            drawer: const _AceDrawer(),
            appBar: AppBar(title: const Text('ACE')),
            body: IndexedStack(index: _index, children: _pages),
            bottomNavigationBar: NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (index) => setState(() => _index = index),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.location_city_outlined),
                  selectedIcon: Icon(Icons.location_city),
                  label: 'PE',
                ),
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: 'Visitas',
                ),
                NavigationDestination(
                  icon: Icon(Icons.grid_view_outlined),
                  selectedIcon: Icon(Icons.grid_view),
                  label: 'Quadras',
                ),
                NavigationDestination(
                  icon: Icon(Icons.map_outlined),
                  selectedIcon: Icon(Icons.map),
                  label: 'Mapa',
                ),
                NavigationDestination(
                  icon: Icon(Icons.bar_chart_outlined),
                  selectedIcon: Icon(Icons.bar_chart),
                  label: 'Relatórios',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AceDrawer extends StatelessWidget {
  const _AceDrawer();

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              color: ace_colors.AppColors.primary,
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.home_work,
                      color: ace_colors.AppColors.primary,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'ACE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Módulo preservado',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            _item(context, Icons.location_city, 'Pontos estratégicos', const PEPage()),
            _item(context, Icons.home, 'Visitas domiciliares', const VisitasDomiciliaresPage()),
            _item(context, Icons.grid_view, 'Quarteirões', const QuarteiroesPage()),
            _item(context, Icons.map, 'Mapa territorial', const MapaRealPage()),
            _item(context, Icons.science, 'BTI', const BTIPage()),
            _item(context, Icons.pest_control, 'Ovitrampas', const OvitrampasPage()),
            _item(context, Icons.analytics, 'LIRA/LIA', const LiraLiaPage()),
            _item(context, Icons.warning, 'Áreas prioritárias', const AreasPrioritariasPage()),
            _item(context, Icons.supervisor_account, 'Supervisor', const TerritorioSupervisorPage()),
            _item(context, Icons.bar_chart, 'Relatórios', const RelatoriosPage()),
            _item(context, Icons.cloud_sync, 'Central de sync', const SyncCenterPage()),
          ],
        ),
      ),
    );
  }

  Widget _item(BuildContext context, IconData icon, String title, Widget page) {
    return ListTile(
      leading: Icon(icon, color: ace_colors.AppColors.primary),
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        Navigator.push(context, MaterialPageRoute(builder: (_) => page));
      },
    );
  }
}
