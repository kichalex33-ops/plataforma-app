import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../database/database_helper.dart';
import '../services/sync_manager.dart';
import '../services/sync_service.dart';

class ServerConfigPage extends StatefulWidget {
  const ServerConfigPage({super.key});

  @override
  State<ServerConfigPage> createState() => _ServerConfigPageState();
}

class _ServerConfigPageState extends State<ServerConfigPage> {
  final servidorController = TextEditingController();
  bool carregando = true;
  bool testando = false;
  bool sincronizando = false;
  String? ultimoTeste;
  List<Map<String, dynamic>> resumoSync = [];
  List<Map<String, dynamic>> errosSync = [];

  @override
  void initState() {
    super.initState();
    carregarServidor();
  }

  @override
  void dispose() {
    servidorController.dispose();
    super.dispose();
  }

  Future<void> carregarServidor() async {
    final url = await SyncService.carregarServidorUrl();
    final resumo = await DatabaseHelper.instance.listarResumoSincronizacao();
    final erros = await DatabaseHelper.instance.listarErrosSincronizacao();

    if (!mounted) return;

    setState(() {
      servidorController.text = url;
      resumoSync = resumo;
      errosSync = erros;
      carregando = false;
    });
  }

  Future<void> salvar() async {
    final url = SyncService.normalizarServidorUrl(servidorController.text);
    await SyncService.salvarServidorUrl(url);

    if (!mounted) return;

    servidorController.text = url;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Endereco do servidor salvo.')),
    );
  }

  Future<void> testarConexao() async {
    setState(() {
      testando = true;
      ultimoTeste = null;
    });

    final url = SyncService.normalizarServidorUrl(servidorController.text);
    final resultado = await SyncService.testarConexaoDetalhada(url);

    if (!mounted) return;

    setState(() {
      testando = false;
      ultimoTeste = resultado.conectado
          ? 'Conectado em ${resultado.servidorUrl}/api/status'
          : 'Falhou em ${resultado.servidorUrl}/api/status\n${resultado.erro}';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          resultado.conectado
              ? 'Servidor conectado com sucesso.'
              : 'Nao foi possivel conectar ao servidor.',
        ),
      ),
    );

    if (resultado.conectado) {
      await SyncService.salvarServidorUrl(url);
      servidorController.text = url;
    }
  }

  Future<void> usarServidorPadrao() async {
    const url = SyncService.servidorPadrao;
    servidorController.text = url;
    await SyncService.salvarServidorUrl(url);

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Servidor padrao aplicado.')));
  }

  Future<void> sincronizarAgora() async {
    setState(() {
      sincronizando = true;
    });

    final url = SyncService.normalizarServidorUrl(servidorController.text);
    await SyncService.salvarServidorUrl(url);
    final resultado = await SyncService(
      servidorUrl: url,
    ).sincronizarPendentes();
    await SyncManager().processQueue();
    final resumo = await DatabaseHelper.instance.listarResumoSincronizacao();
    final erros = await DatabaseHelper.instance.listarErrosSincronizacao();

    if (!mounted) return;

    setState(() {
      sincronizando = false;
      resumoSync = resumo;
      errosSync = erros;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          resultado.erro != null
              ? 'Servidor indisponivel. Dados continuam salvos no aparelho.'
              : 'Enviados: ${resultado.enviados}. Falhas: ${resultado.falhas}.',
        ),
      ),
    );
  }

  int get totalPendentes {
    return resumoSync.fold(
      0,
      (total, item) => total + (item['pendentes'] as int? ?? 0),
    );
  }

  int get totalSincronizados {
    return resumoSync.fold(
      0,
      (total, item) => total + (item['sincronizados'] as int? ?? 0),
    );
  }

  int get totalErros {
    return resumoSync.fold(
      0,
      (total, item) => total + (item['erros'] as int? ?? 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Servidor')),
      body: carregando
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.dns, color: Colors.white, size: 34),
                      SizedBox(height: AppSpacing.md),
                      Text(
                        'Configuracao do servidor',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: AppSpacing.sm),
                      Text(
                        'Informe o endereco do computador ou notebook onde o servidor local esta rodando.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      children: [
                        TextField(
                          controller: servidorController,
                          keyboardType: TextInputType.url,
                          decoration: const InputDecoration(
                            labelText: 'Endereco do servidor',
                            hintText: 'http://192.168.0.35:3000',
                            prefixIcon: Icon(Icons.link),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 54),
                          ),
                          onPressed: usarServidorPadrao,
                          icon: const Icon(Icons.settings_backup_restore),
                          label: const Text('Usar 10.0.0.3:3000'),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Use o IP do notebook na mesma rede do celular. Para este teste: http://10.0.0.3:3000',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 54),
                          ),
                          onPressed: salvar,
                          icon: const Icon(Icons.save),
                          label: const Text('Salvar endereco'),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 54),
                          ),
                          onPressed: testando ? null : testarConexao,
                          icon: Icon(
                            testando ? Icons.sync : Icons.wifi_tethering,
                          ),
                          label: Text(
                            testando ? 'Testando...' : 'Testar conexao',
                          ),
                        ),
                        if (ultimoTeste != null) ...[
                          const SizedBox(height: AppSpacing.md),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(
                                AppSpacing.cardRadius,
                              ),
                            ),
                            child: Text(
                              ultimoTeste!,
                              style: const TextStyle(
                                color: AppColors.textStrong,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.sync, color: AppColors.primary),
                            const SizedBox(width: AppSpacing.sm),
                            const Expanded(
                              child: Text(
                                'Fila de sincronizacao',
                                style: TextStyle(
                                  color: AppColors.textStrong,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            _ResumoChip(
                              texto: '$totalPendentes pendentes',
                              cor: totalPendentes == 0
                                  ? AppColors.emDia
                                  : AppColors.vencendo,
                            ),
                            const SizedBox(width: 6),
                            _ResumoChip(
                              texto: '$totalSincronizados enviados',
                              cor: AppColors.informativo,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        ...resumoSync.map((item) {
                          final total = item['total'] as int? ?? 0;
                          final sincronizados =
                              item['sincronizados'] as int? ?? 0;
                          final pendentes = item['pendentes'] as int? ?? 0;
                          final erros = item['erros'] as int? ?? 0;
                          return _LinhaModuloSync(
                            modulo: item['modulo']?.toString() ?? '',
                            total: total,
                            sincronizados: sincronizados,
                            pendentes: pendentes,
                            erros: erros,
                          );
                        }),
                        const SizedBox(height: AppSpacing.lg),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.informativo,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 54),
                          ),
                          onPressed: sincronizando ? null : sincronizarAgora,
                          icon: Icon(
                            sincronizando ? Icons.sync : Icons.cloud_upload,
                          ),
                          label: Text(
                            sincronizando
                                ? 'Sincronizando...'
                                : 'Sincronizar pendentes',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (errosSync.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.error,
                                color: AppColors.atrasado,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              const Expanded(
                                child: Text(
                                  'Ultimos erros',
                                  style: TextStyle(
                                    color: AppColors.textStrong,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              _ResumoChip(
                                texto: '$totalErros erros',
                                cor: AppColors.atrasado,
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          ...errosSync.map((erro) {
                            return Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.sm,
                              ),
                              child: Text(
                                '${erro['modulo']} #${erro['id']}: ${erro['erro']}',
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 13,
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

class _LinhaModuloSync extends StatelessWidget {
  final String modulo;
  final int total;
  final int sincronizados;
  final int pendentes;
  final int erros;

  const _LinhaModuloSync({
    required this.modulo,
    required this.total,
    required this.sincronizados,
    required this.pendentes,
    required this.erros,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  modulo,
                  style: const TextStyle(
                    color: AppColors.textStrong,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '$total registros',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          _ResumoChip(
            texto: '$sincronizados enviados',
            cor: sincronizados == 0 ? AppColors.textMuted : AppColors.emDia,
          ),
          const SizedBox(width: 6),
          _ResumoChip(
            texto: '$pendentes pend.',
            cor: pendentes == 0 ? AppColors.textMuted : AppColors.vencendo,
          ),
          const SizedBox(width: 6),
          _ResumoChip(
            texto: '$erros erro',
            cor: erros == 0 ? AppColors.textMuted : AppColors.atrasado,
          ),
        ],
      ),
    );
  }
}

class _ResumoChip extends StatelessWidget {
  final String texto;
  final Color cor;

  const _ResumoChip({required this.texto, required this.cor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Text(
        texto,
        style: TextStyle(color: cor, fontSize: 12, fontWeight: FontWeight.w800),
      ),
    );
  }
}
