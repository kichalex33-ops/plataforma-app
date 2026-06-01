import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../database/database_helper.dart';
import '../models/ovitrampa_check_model.dart';
import '../models/ovitrampa_model.dart';
import '../services/gps_service.dart';

class OvitrampasPage extends StatefulWidget {
  const OvitrampasPage({super.key});

  @override
  State<OvitrampasPage> createState() => _OvitrampasPageState();
}

class _OvitrampasPageState extends State<OvitrampasPage> {
  final codigoController = TextEditingController();
  final enderecoController = TextEditingController();
  final referenciaController = TextEditingController();
  final ovosController = TextEditingController();
  final observacoesController = TextEditingController();

  List<OvitrampaModel> ovitrampas = [];
  Map<int, List<OvitrampaCheckModel>> checagens = {};
  Map<String, String> config = {};
  OvitrampaModel? selecionada;
  String resultado = 'Negativa';
  bool salvandoInstalacao = false;
  bool salvandoChecagem = false;

  @override
  void initState() {
    super.initState();
    carregarDados();
  }

  @override
  void dispose() {
    codigoController.dispose();
    enderecoController.dispose();
    referenciaController.dispose();
    ovosController.dispose();
    observacoesController.dispose();
    super.dispose();
  }

  Future<void> carregarDados() async {
    final lista = await DatabaseHelper.instance.listarOvitrampas();
    final configuracao = await DatabaseHelper.instance.carregarConfiguracao();
    final historicos = <int, List<OvitrampaCheckModel>>{};

    for (final item in lista) {
      if (item.id != null) {
        historicos[item.id!] = await DatabaseHelper.instance
            .listarChecagensOvitrampa(item.id!);
      }
    }

    if (!mounted) return;

    setState(() {
      ovitrampas = lista;
      checagens = historicos;
      config = configuracao;
      if (selecionada != null) {
        OvitrampaModel? atualizada;
        for (final item in lista) {
          if (item.id == selecionada!.id) {
            atualizada = item;
            break;
          }
        }
        selecionada = atualizada;
      }
    });
  }

  String formatarDataHora(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/'
        '${data.year} '
        '${data.hour.toString().padLeft(2, '0')}:'
        '${data.minute.toString().padLeft(2, '0')}';
  }

  Color corStatus(String status) {
    if (status == 'Positiva') return AppColors.atrasado;
    if (status == 'Negativa') return AppColors.emDia;
    return AppColors.vencendo;
  }

  Future<void> instalarOvitrampa() async {
    if (codigoController.text.trim().isEmpty ||
        enderecoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe código e endereço.')),
      );
      return;
    }

    setState(() {
      salvandoInstalacao = true;
    });

    try {
      final posicao = await GPSService.obterLocalizacaoObrigatoria();
      final agora = DateTime.now();

      await DatabaseHelper.instance.inserirOvitrampa(
        OvitrampaModel(
          codigo: codigoController.text.trim(),
          endereco: enderecoController.text.trim(),
          referencia: referenciaController.text.trim(),
          municipio: config['municipio'] ?? '',
          agenteInstalacao: config['agente'] ?? '',
          instaladaEm: formatarDataHora(agora),
          status: 'Instalada',
          latitude: posicao.latitude,
          longitude: posicao.longitude,
        ),
      );

      codigoController.clear();
      enderecoController.clear();
      referenciaController.clear();

      await carregarDados();

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ovitrampa instalada.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          salvandoInstalacao = false;
        });
      }
    }
  }

  Future<void> registrarChecagem() async {
    if (selecionada?.id == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Selecione uma ovitrampa.')));
      return;
    }

    final ovos = int.tryParse(ovosController.text.trim()) ?? 0;
    if (resultado == 'Positiva' && ovos <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe a quantidade de ovos.')),
      );
      return;
    }

    setState(() {
      salvandoChecagem = true;
    });

    try {
      final posicao = await GPSService.obterLocalizacaoObrigatoria();
      final agora = DateTime.now();

      await DatabaseHelper.instance.inserirChecagemOvitrampa(
        ovitrampaId: selecionada!.id!,
        dataChecagem: formatarDataHora(agora),
        agente: config['agente'] ?? '',
        resultado: resultado,
        quantidadeOvos: resultado == 'Positiva' ? ovos : 0,
        observacoes: observacoesController.text.trim(),
        latitude: posicao.latitude,
        longitude: posicao.longitude,
      );

      ovosController.clear();
      observacoesController.clear();
      resultado = 'Negativa';

      await carregarDados();

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Checagem registrada.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          salvandoChecagem = false;
        });
      }
    }
  }

  Future<void> excluirOvitrampa(OvitrampaModel ovitrampa) async {
    if (ovitrampa.id == null) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir ovitrampa'),
        content: Text('Excluir "${ovitrampa.codigo}" e seu histórico?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await DatabaseHelper.instance.excluirOvitrampa(ovitrampa.id!);
      setState(() {
        if (selecionada?.id == ovitrampa.id) selecionada = null;
      });
      await carregarDados();
    }
  }

  Widget construirCabecalho() {
    final positivas = ovitrampas
        .where((item) => item.status == 'Positiva')
        .length;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.ovitrampas,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Row(
        children: [
          const Icon(Icons.bug_report, color: Colors.white, size: 34),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ovitrampas',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${ovitrampas.length} instaladas • $positivas positivas',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget construirInstalacao() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            TextField(
              controller: codigoController,
              decoration: const InputDecoration(
                labelText: 'Código da ovitrampa',
                prefixIcon: Icon(Icons.qr_code),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: enderecoController,
              decoration: const InputDecoration(
                labelText: 'Endereço',
                prefixIcon: Icon(Icons.place),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: referenciaController,
              decoration: const InputDecoration(
                labelText: 'Referência',
                prefixIcon: Icon(Icons.notes),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.ovitrampas,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 58),
              ),
              onPressed: salvandoInstalacao ? null : instalarOvitrampa,
              icon: Icon(
                salvandoInstalacao ? Icons.my_location : Icons.add_location_alt,
              ),
              label: Text(
                salvandoInstalacao ? 'Capturando GPS...' : 'Instalar ovitrampa',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget construirChecagem() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            DropdownButtonFormField<int>(
              initialValue: selecionada?.id,
              decoration: const InputDecoration(
                labelText: 'Ovitrampa',
                prefixIcon: Icon(Icons.bug_report),
              ),
              items: ovitrampas.where((item) => item.id != null).map((item) {
                return DropdownMenuItem(
                  value: item.id!,
                  child: Text('${item.codigo} - ${item.endereco}'),
                );
              }).toList(),
              onChanged: (id) {
                if (id == null) return;
                setState(() {
                  for (final item in ovitrampas) {
                    if (item.id == id) {
                      selecionada = item;
                      break;
                    }
                  }
                });
              },
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String>(
              initialValue: resultado,
              decoration: const InputDecoration(
                labelText: 'Resultado',
                prefixIcon: Icon(Icons.fact_check),
              ),
              items: const [
                DropdownMenuItem(value: 'Negativa', child: Text('Negativa')),
                DropdownMenuItem(value: 'Positiva', child: Text('Positiva')),
                DropdownMenuItem(value: 'Pendente', child: Text('Pendente')),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  resultado = value;
                  if (value != 'Positiva') ovosController.clear();
                });
              },
            ),
            if (resultado == 'Positiva') ...[
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: ovosController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Quantidade de ovos',
                  prefixIcon: Icon(Icons.science),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: observacoesController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Observações'),
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 58),
              ),
              onPressed: salvandoChecagem ? null : registrarChecagem,
              icon: Icon(salvandoChecagem ? Icons.my_location : Icons.save),
              label: Text(
                salvandoChecagem ? 'Capturando GPS...' : 'Registrar checagem',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget construirLista() {
    if (ovitrampas.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Text('Nenhuma ovitrampa instalada.'),
        ),
      );
    }

    return Column(
      children: ovitrampas.map((item) {
        final historico = checagens[item.id] ?? [];

        return Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border(
              left: BorderSide(color: corStatus(item.status), width: 5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.codigo,
                      style: const TextStyle(
                        color: AppColors.textStrong,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Excluir',
                    onPressed: () => excluirOvitrampa(item),
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                  ),
                ],
              ),
              _LinhaOvi(icon: Icons.place, texto: item.endereco),
              _LinhaOvi(
                icon: Icons.info,
                texto: item.referencia.isEmpty
                    ? 'Sem referência'
                    : item.referencia,
              ),
              _LinhaOvi(
                icon: Icons.person,
                texto: item.agenteInstalacao.isEmpty
                    ? 'ACE não informado'
                    : item.agenteInstalacao,
              ),
              _LinhaOvi(
                icon: Icons.my_location,
                texto:
                    '${item.latitude.toStringAsFixed(6)}, ${item.longitude.toStringAsFixed(6)}',
              ),
              _ChipStatus(status: item.status, cor: corStatus(item.status)),
              if (historico.isNotEmpty) ...[
                const Divider(height: AppSpacing.xxl),
                ...historico.take(3).map((check) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${check.dataChecagem} • ${check.resultado}',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          check.resultado == 'Positiva'
                              ? 'Ovos: ${check.quantidadeOvos}'
                              : 'Sem ovos registrados',
                          style: const TextStyle(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ovitrampas')),
      body: RefreshIndicator(
        onRefresh: carregarDados,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            construirCabecalho(),
            const SizedBox(height: AppSpacing.lg),
            construirInstalacao(),
            const SizedBox(height: AppSpacing.lg),
            construirChecagem(),
            const SizedBox(height: AppSpacing.xl),
            const Text(
              'Histórico de ovitrampas',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.md),
            construirLista(),
          ],
        ),
      ),
    );
  }
}

class _LinhaOvi extends StatelessWidget {
  final IconData icon;
  final String texto;

  const _LinhaOvi({required this.icon, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipStatus extends StatelessWidget {
  final String status;
  final Color cor;

  const _ChipStatus({required this.status, required this.cor});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Text(
        status,
        style: TextStyle(color: cor, fontSize: 12, fontWeight: FontWeight.w800),
      ),
    );
  }
}
