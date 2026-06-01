import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../controllers/farmacia_controller.dart';

class FarmaciaPage extends StatefulWidget {
  final bool embed;

  const FarmaciaPage({super.key, this.embed = false});

  @override
  State<FarmaciaPage> createState() => _FarmaciaPageState();
}

class _FarmaciaPageState extends State<FarmaciaPage> {
  late final FarmaciaController controller;

  @override
  void initState() {
    super.initState();
    controller = FarmaciaController()..carregar();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _novoMedicamento() async {
    final nome = TextEditingController();
    final principio = TextEditingController();
    final apresentacao = TextEditingController();
    final salvou = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Novo medicamento'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nome,
              decoration: const InputDecoration(labelText: 'Nome'),
            ),
            TextField(
              controller: principio,
              decoration: const InputDecoration(labelText: 'Principio ativo'),
            ),
            TextField(
              controller: apresentacao,
              decoration: const InputDecoration(labelText: 'Apresentacao'),
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
    await controller.criarMedicamento(
      nome: nome.text.trim(),
      principioAtivo: principio.text.trim(),
      apresentacao: apresentacao.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.embed ? null : AppBar(title: const Text('Farmacia')),
      floatingActionButton: FloatingActionButton(
        onPressed: _novoMedicamento,
        child: const Icon(Icons.add),
      ),
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          if (controller.carregando) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Row(
                children: [
                  _Resumo(
                    label: 'Medicamentos',
                    value: controller.resumo['medicamentos'] ?? 0,
                  ),
                  _Resumo(
                    label: 'Estoque',
                    value: controller.resumo['estoque'] ?? 0,
                  ),
                  _Resumo(
                    label: 'Alertas',
                    value: controller.resumo['alertas'] ?? 0,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              if (controller.medicamentos.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 64),
                  child: Center(
                    child: Text(
                      'Nenhum medicamento cadastrado',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  ),
                )
              else
                ...controller.medicamentos.map(
                  (medicamento) => Card(
                    child: ListTile(
                      leading: const Icon(
                        Icons.medication,
                        color: AppColors.primary,
                      ),
                      title: Text(medicamento.nome),
                      subtitle: Text(
                        [
                          if (medicamento.principioAtivo?.isNotEmpty == true)
                            medicamento.principioAtivo,
                          if (medicamento.apresentacao?.isNotEmpty == true)
                            medicamento.apresentacao,
                        ].whereType<String>().join(' | '),
                      ),
                      trailing: const Icon(Icons.cloud_upload, size: 18),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Resumo extends StatelessWidget {
  final String label;
  final int value;

  const _Resumo({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text(
                value.toString(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}
