import 'dart:async';

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../database/database_helper.dart';
import '../models/pe_model.dart';
import '../services/sync_service.dart';

class PEFormPage extends StatefulWidget {
  const PEFormPage({super.key});

  @override
  State<PEFormPage> createState() => _PEFormPageState();
}

class _PEFormPageState extends State<PEFormPage> {
  final nomeController = TextEditingController();
  final enderecoController = TextEditingController();

  String tipoSelecionado = 'Ferro-velho';

  Future<void> salvarPE() async {
    if (nomeController.text.trim().isEmpty ||
        enderecoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha nome e endereço do PE.')),
      );
      return;
    }

    final pe = PEModel(
      nome: nomeController.text.trim(),
      endereco: enderecoController.text.trim(),
      tipo: tipoSelecionado,
      status: 'Atrasado',
    );

    final peId = await DatabaseHelper.instance.inserirPE(pe);

    unawaited(
      sincronizarPE(
        PEModel(
          id: peId,
          nome: pe.nome,
          endereco: pe.endereco,
          tipo: pe.tipo,
          status: pe.status,
          ultimaVisita: pe.ultimaVisita,
          latitude: pe.latitude,
          longitude: pe.longitude,
        ),
      ),
    );

    if (!mounted) return;

    Navigator.pop(context, true);
  }

  Future<void> sincronizarPE(PEModel pe) async {
    final id = pe.id;
    if (id == null) return;

    try {
      final sync = await SyncService.configurado();
      await sync.enviarPE(pe);
      await DatabaseHelper.instance.marcarSincronizado(
        tabela: 'pontos_estrategicos',
        id: id,
        sincronizadoEm: DateTime.now().toIso8601String(),
      );
    } catch (error) {
      await DatabaseHelper.instance.marcarErroSincronizacao(
        tabela: 'pontos_estrategicos',
        id: id,
        erro: error.toString(),
      );
      debugPrint('PE salvo offline. Sincronizacao pendente: $error');
    }
  }

  @override
  void dispose() {
    nomeController.dispose();
    enderecoController.dispose();
    super.dispose();
  }

  Widget construirCabecalho() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: const Row(
        children: [
          Icon(Icons.add_location_alt, color: Colors.white, size: 34),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Novo Ponto Estratégico',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Cadastro local offline',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget construirDadosPE() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            TextField(
              controller: nomeController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Nome do PE',
                prefixIcon: Icon(Icons.business),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: enderecoController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Endereço',
                prefixIcon: Icon(Icons.place),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            DropdownButtonFormField<String>(
              initialValue: tipoSelecionado,
              decoration: const InputDecoration(
                labelText: 'Tipo de ponto',
                prefixIcon: Icon(Icons.category),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Ferro-velho',
                  child: Text('Ferro-velho'),
                ),
                DropdownMenuItem(
                  value: 'Borracharia',
                  child: Text('Borracharia'),
                ),
                DropdownMenuItem(value: 'Oficina', child: Text('Oficina')),
                DropdownMenuItem(value: 'Depósito', child: Text('Depósito')),
                DropdownMenuItem(value: 'Cemitério', child: Text('Cemitério')),
                DropdownMenuItem(value: 'Outro', child: Text('Outro')),
              ],
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  tipoSelecionado = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget construirPreparacaoGPS() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.14)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.my_location, color: AppColors.primary),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GPS preparado',
                  style: TextStyle(
                    color: AppColors.textStrong,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Latitude e longitude já existem no banco. Na próxima fase o app vai capturar a localização automaticamente.',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Novo PE')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          construirCabecalho(),
          const SizedBox(height: AppSpacing.lg),
          construirDadosPE(),
          const SizedBox(height: AppSpacing.lg),
          construirPreparacaoGPS(),
          const SizedBox(height: AppSpacing.xl),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 60),
            ),
            onPressed: salvarPE,
            icon: const Icon(Icons.save),
            label: const Text('Salvar PE', style: TextStyle(fontSize: 18)),
          ),
        ],
      ),
    );
  }
}
