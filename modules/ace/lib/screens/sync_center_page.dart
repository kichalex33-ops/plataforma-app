import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../models/sync_queue_item_model.dart';
import '../repositories/sync_queue_repository.dart';
import '../services/sync_manager.dart';
import '../services/sync_service.dart';
import '../widgets/sync_status_badge.dart';

class SyncCenterPage extends StatefulWidget {
  const SyncCenterPage({super.key});

  @override
  State<SyncCenterPage> createState() => _SyncCenterPageState();
}

class _SyncCenterPageState extends State<SyncCenterPage> {
  final queueRepository = SyncQueueRepository();

  Map<String, int> resumo = {
    'pending': 0,
    'processing': 0,
    'synced': 0,
    'failed': 0,
    'conflict': 0,
  };
  List<SyncQueueItemModel> recentes = [];
  String servidorUrl = '';
  String? ultimaSincronizacao;
  String statusServidor = 'Nao testado';
  bool servidorOnline = false;
  bool carregando = true;
  bool sincronizando = false;
  bool testando = false;

  @override
  void initState() {
    super.initState();
    carregar();
  }

  Future<void> carregar() async {
    final url = await SyncService.carregarServidorUrl();
    final ultima = await SyncService.carregarUltimaSincronizacao();
    final status = await queueRepository.contarPorStatus();
    final lista = await queueRepository.listarRecentes();

    if (!mounted) return;
    setState(() {
      servidorUrl = url;
      ultimaSincronizacao = ultima;
      resumo = status;
      recentes = lista;
      carregando = false;
    });
  }

  Future<void> testarServidor() async {
    setState(() => testando = true);
    final resultado = await SyncService.testarConexaoDetalhada(servidorUrl);

    if (!mounted) return;
    setState(() {
      servidorOnline = resultado.conectado;
      statusServidor = resultado.conectado ? 'online' : 'offline';
      testando = false;
    });
  }

  Future<void> sincronizarAgora() async {
    if (sincronizando) return;
    setState(() => sincronizando = true);

    final servico = await SyncService.configurado();
    await servico.sincronizarPendentes();
    await SyncManager().processQueue();
    await testarServidor();
    await carregar();

    if (!mounted) return;
    setState(() => sincronizando = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sincronizacao processada.')),
    );
  }

  Future<void> retryFailed() async {
    await queueRepository.retryFailed();
    await sincronizarAgora();
  }

  int valor(String status) => resumo[status] ?? 0;

  String formatarData(String? iso) {
    if (iso == null || iso.isEmpty) return 'Nunca';
    final data = DateTime.tryParse(iso);
    if (data == null) return iso;
    return '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')} '
        '${data.hour.toString().padLeft(2, '0')}:'
        '${data.minute.toString().padLeft(2, '0')}';
  }

  Widget indicador(String titulo, int valor, Color cor, IconData icone) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icone, color: cor),
              const SizedBox(height: AppSpacing.sm),
              Text(
                valor.toString(),
                style: TextStyle(
                  color: cor,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                titulo,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (carregando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Central de Sincronizacao'),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: carregar,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      servidorOnline ? Icons.cloud_done : Icons.cloud_off,
                      color: Colors.white,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Servidor $statusServidor',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: testando ? null : testarServidor,
                      icon: Icon(
                        testando ? Icons.sync : Icons.wifi_tethering,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Testar',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  servidorUrl,
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Ultima sincronizacao: ${formatarData(ultimaSincronizacao)}',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              indicador(
                'pending',
                valor('pending'),
                AppColors.vencendo,
                Icons.cloud_upload,
              ),
              const SizedBox(width: AppSpacing.sm),
              indicador(
                'synced',
                valor('synced'),
                AppColors.emDia,
                Icons.cloud_done,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              indicador(
                'failed',
                valor('failed'),
                AppColors.atrasado,
                Icons.cloud_off,
              ),
              const SizedBox(width: AppSpacing.sm),
              indicador(
                'conflict',
                valor('conflict'),
                const Color(0xFF7E57C2),
                Icons.compare_arrows,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 54),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: sincronizando ? null : sincronizarAgora,
            icon: Icon(sincronizando ? Icons.sync : Icons.cloud_sync),
            label: Text(sincronizando ? 'Sincronizando...' : 'Sincronizar agora'),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 54),
            ),
            onPressed: valor('failed') == 0 || sincronizando ? null : retryFailed,
            icon: const Icon(Icons.restart_alt),
            label: const Text('Retry failed'),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Ultimas operacoes',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          if (recentes.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Text('Nenhuma operacao na fila ainda.'),
              ),
            ),
          for (final item in recentes)
            Card(
              child: ListTile(
                leading: const Icon(Icons.sync_alt, color: AppColors.primary),
                title: Text('${item.entityType} / ${item.operation}'),
                subtitle: Text(
                  '${item.entityId}\nTentativas: ${item.retryCount}'
                  '${item.errorMessage == null ? '' : '\nErro: ${item.errorMessage}'}',
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
                isThreeLine: true,
                trailing: SyncStatusBadge(status: item.status),
              ),
            ),
        ],
      ),
    );
  }
}
