import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../controllers/pacientes_controller.dart';

class PacientesPage extends StatefulWidget {
  final bool embed;

  const PacientesPage({super.key, this.embed = false});

  @override
  State<PacientesPage> createState() => _PacientesPageState();
}

class _PacientesPageState extends State<PacientesPage> {
  late final PacientesController controller;

  @override
  void initState() {
    super.initState();
    controller = PacientesController()..carregar();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _novoPaciente() async {
    final nome = TextEditingController();
    final telefone = TextEditingController();
    final endereco = TextEditingController();
    final necessidades = TextEditingController();
    final salvou = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Novo paciente'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nome,
              decoration: const InputDecoration(labelText: 'Nome'),
            ),
            TextField(
              controller: telefone,
              decoration: const InputDecoration(labelText: 'Telefone'),
            ),
            TextField(
              controller: endereco,
              decoration: const InputDecoration(labelText: 'Endereco'),
            ),
            TextField(
              controller: necessidades,
              decoration: const InputDecoration(
                labelText: 'Necessidades especiais',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    if (salvou != true || nome.text.trim().isEmpty) return;
    await controller.criar(
      nome: nome.text.trim(),
      telefone: telefone.text.trim(),
      endereco: endereco.text.trim(),
      necessidadesEspeciais: necessidades.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.embed ? null : AppBar(title: const Text('Pacientes')),
      floatingActionButton: FloatingActionButton(
        onPressed: _novoPaciente,
        child: const Icon(Icons.person_add),
      ),
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          if (controller.carregando) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.pacientes.isEmpty) {
            return const Center(
              child: Text(
                'Nenhum paciente cadastrado',
                style: TextStyle(color: AppColors.textMuted),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: controller.pacientes.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final paciente = controller.pacientes[index];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.people, color: AppColors.primary),
                  title: Text(paciente.nome),
                  subtitle: Text(
                    [
                      if (paciente.telefone?.isNotEmpty == true)
                        paciente.telefone,
                      if (paciente.endereco?.isNotEmpty == true)
                        paciente.endereco,
                      if (paciente.necessidadesEspeciais?.isNotEmpty == true)
                        paciente.necessidadesEspeciais,
                    ].whereType<String>().join(' | '),
                  ),
                  trailing: const Icon(Icons.cloud_upload, size: 18),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
