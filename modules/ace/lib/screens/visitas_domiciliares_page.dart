import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../database/database_helper.dart';
import '../models/rg_quarteirao_model.dart';
import '../models/visita_domiciliar_model.dart';
import '../services/gps_service.dart';
import '../services/sync_service.dart';

class VisitasDomiciliaresPage extends StatefulWidget {
  const VisitasDomiciliaresPage({super.key});

  @override
  State<VisitasDomiciliaresPage> createState() =>
      _VisitasDomiciliaresPageState();
}

class _VisitasDomiciliaresPageState extends State<VisitasDomiciliaresPage> {
  final enderecoController = TextEditingController();
  final numeroController = TextEditingController();
  final complementoController = TextEditingController();
  final observacoesController = TextEditingController();
  final tubitosController = TextEditingController();

  List<VisitaDomiciliarModel> visitas = [];
  List<RGQuarteiraoModel> quarteiroes = [];
  Map<String, String> config = {};
  RGQuarteiraoModel? quarteiraoSelecionado;
  DateTime? entradaEm;
  double? entradaLatitude;
  double? entradaLongitude;
  bool visitaIniciada = false;
  bool finalizacaoAberta = false;
  bool capturandoGPS = false;
  bool focoPositivo = false;
  int ultimoTubitoGlobal = 0;
  String situacaoSelecionada = 'Visitado';

  @override
  void initState() {
    super.initState();
    carregarDados();
  }

  @override
  void dispose() {
    enderecoController.dispose();
    numeroController.dispose();
    complementoController.dispose();
    observacoesController.dispose();
    tubitosController.dispose();
    super.dispose();
  }

  Future<void> carregarDados() async {
    final lista = await DatabaseHelper.instance.listarVisitasDomiciliares();
    final rg = await DatabaseHelper.instance.listarRGQuarteiroes();
    final configuracao = await DatabaseHelper.instance.carregarConfiguracao();
    final ultimoTubito = await DatabaseHelper.instance
        .buscarUltimoNumeroTubito();

    if (!mounted) return;

    setState(() {
      visitas = lista;
      quarteiroes = rg;
      config = configuracao;
      ultimoTubitoGlobal = ultimoTubito;
    });
  }

  String formatarDataHora(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/'
        '${data.year} '
        '${data.hour.toString().padLeft(2, '0')}:'
        '${data.minute.toString().padLeft(2, '0')}';
  }

  Future<void> iniciarVisita() async {
    if (enderecoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe o endereço do imóvel.')),
      );
      return;
    }

    setState(() {
      capturandoGPS = true;
    });

    try {
      final posicao = await GPSService.obterLocalizacaoObrigatoria();

      if (!mounted) return;

      setState(() {
        entradaEm = DateTime.now();
        entradaLatitude = posicao.latitude;
        entradaLongitude = posicao.longitude;
        visitaIniciada = true;
        finalizacaoAberta = false;
      });
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
          capturandoGPS = false;
        });
      }
    }
  }

  void abrirFinalizacao() {
    setState(() {
      finalizacaoAberta = true;
    });
  }

  Future<void> salvarVisita() async {
    if (!visitaIniciada || entradaEm == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inicie a visita antes de finalizar.')),
      );
      return;
    }

    final quantidadeTubitos = int.tryParse(tubitosController.text.trim()) ?? 0;
    if (focoPositivo && quantidadeTubitos <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informe a quantidade de tubitos coletados.'),
        ),
      );
      return;
    }

    late final double saidaLatitude;
    late final double saidaLongitude;

    try {
      final posicaoSaida = await GPSService.obterLocalizacaoObrigatoria();
      saidaLatitude = posicaoSaida.latitude;
      saidaLongitude = posicaoSaida.longitude;
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
      return;
    }

    final saidaEm = DateTime.now();
    int? tubitoInicialServidor;

    if (focoPositivo) {
      try {
        final servico = await SyncService.configurado();
        tubitoInicialServidor = await servico.reservarTubitos(
          quantidade: quantidadeTubitos,
          municipio: config['municipio'] ?? '',
          agente: config['agente'] ?? '',
        );
      } catch (_) {
        tubitoInicialServidor = null;
      }
    }

    await DatabaseHelper.instance.inserirVisitaDomiciliar(
      rgQuarteiraoId: quarteiraoSelecionado?.id,
      rgQuarteiraoCodigo: quarteiraoSelecionado?.codigo,
      endereco: enderecoController.text.trim(),
      numero: numeroController.text.trim(),
      complemento: complementoController.text.trim(),
      municipio: config['municipio'] ?? '',
      agente: config['agente'] ?? '',
      entradaEm: formatarDataHora(entradaEm!),
      saidaEm: formatarDataHora(saidaEm),
      situacao: situacaoSelecionada,
      focoPositivo: focoPositivo,
      quantidadeTubitos: quantidadeTubitos,
      observacoes: observacoesController.text.trim(),
      entradaLatitude: entradaLatitude!,
      entradaLongitude: entradaLongitude!,
      saidaLatitude: saidaLatitude,
      saidaLongitude: saidaLongitude,
      tubitoInicial: tubitoInicialServidor,
    );

    enderecoController.clear();
    numeroController.clear();
    complementoController.clear();
    observacoesController.clear();
    tubitosController.clear();

    setState(() {
      entradaEm = null;
      entradaLatitude = null;
      entradaLongitude = null;
      visitaIniciada = false;
      finalizacaoAberta = false;
      focoPositivo = false;
      quarteiraoSelecionado = null;
      situacaoSelecionada = 'Visitado';
    });

    await carregarDados();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Visita domiciliar registrada.')),
    );
  }

  String previewTubitos() {
    final quantidade = int.tryParse(tubitosController.text.trim()) ?? 0;

    if (quantidade <= 0) {
      return 'Último tubito registrado: $ultimoTubitoGlobal.';
    }

    final numeros = List.generate(
      quantidade,
      (index) => (ultimoTubitoGlobal + index + 1).toString(),
    );
    return 'Tubitos: ${numeros.join(', ')}';
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
          Icon(Icons.home_work, color: Colors.white, size: 34),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Visitas domiciliares',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'GPS obrigatório e tubitos universais',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget construirDadosImovel() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            TextField(
              controller: enderecoController,
              enabled: !visitaIniciada,
              decoration: const InputDecoration(
                labelText: 'Endereço do imóvel',
                prefixIcon: Icon(Icons.place),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<int>(
              initialValue: quarteiraoSelecionado?.id,
              decoration: const InputDecoration(
                labelText: 'Quarteirao RG',
                prefixIcon: Icon(Icons.grid_view),
              ),
              items: quarteiroes.where((item) => item.id != null).map((
                quarteirao,
              ) {
                return DropdownMenuItem(
                  value: quarteirao.id!,
                  child: Text(
                    'Q ${quarteirao.codigo} - ponto ${quarteirao.ordem}',
                  ),
                );
              }).toList(),
              onChanged: visitaIniciada
                  ? null
                  : (id) {
                      if (id == null) return;
                      setState(() {
                        for (final quarteirao in quarteiroes) {
                          if (quarteirao.id == id) {
                            quarteiraoSelecionado = quarteirao;
                            break;
                          }
                        }
                      });
                    },
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: numeroController,
                    enabled: !visitaIniciada,
                    decoration: const InputDecoration(labelText: 'Número'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: TextField(
                    controller: complementoController,
                    enabled: !visitaIniciada,
                    decoration: const InputDecoration(labelText: 'Complemento'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget construirControleVisita() {
    if (!visitaIniciada) {
      return ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.emDia,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 60),
        ),
        onPressed: capturandoGPS ? null : iniciarVisita,
        icon: Icon(capturandoGPS ? Icons.my_location : Icons.play_arrow),
        label: Text(
          capturandoGPS ? 'Capturando GPS...' : 'Iniciar visita domiciliar',
          style: const TextStyle(fontSize: 18),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Visita em andamento',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text('Entrada: ${formatarDataHora(entradaEm!)}'),
            Text(
              'GPS entrada: ${entradaLatitude?.toStringAsFixed(6)}, ${entradaLongitude?.toStringAsFixed(6)}',
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
              ),
              onPressed: abrirFinalizacao,
              icon: const Icon(Icons.stop_circle),
              label: const Text(
                'Finalizar visita',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget construirFinalizacao() {
    if (!finalizacaoAberta) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              initialValue: situacaoSelecionada,
              decoration: const InputDecoration(labelText: 'Situação'),
              items: const [
                DropdownMenuItem(value: 'Visitado', child: Text('Visitado')),
                DropdownMenuItem(value: 'Fechado', child: Text('Fechado')),
                DropdownMenuItem(value: 'Recusado', child: Text('Recusado')),
                DropdownMenuItem(value: 'Pendente', child: Text('Pendente')),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  situacaoSelecionada = value;
                });
              },
            ),
            const SizedBox(height: AppSpacing.md),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Foco positivo encontrado'),
              subtitle: const Text('Usa a numeração universal de tubitos.'),
              value: focoPositivo,
              activeThumbColor: AppColors.atrasado,
              onChanged: (value) {
                setState(() {
                  focoPositivo = value;
                  if (!value) tubitosController.clear();
                });
              },
            ),
            if (focoPositivo) ...[
              TextField(
                controller: tubitosController,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Quantidade de tubitos',
                  prefixIcon: Icon(Icons.science),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  previewTubitos(),
                  style: const TextStyle(color: AppColors.textMuted),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: observacoesController,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Observações'),
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 60),
              ),
              onPressed: salvarVisita,
              icon: const Icon(Icons.save),
              label: const Text(
                'Salvar visita domiciliar',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget construirHistorico() {
    if (visitas.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Text('Nenhuma visita domiciliar registrada.'),
        ),
      );
    }

    return Column(
      children: visitas.map((visita) {
        final tubitos = visita.tubitos.join(', ');

        return Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border(
              left: BorderSide(
                color: visita.focoPositivo
                    ? AppColors.atrasado
                    : AppColors.emDia,
                width: 5,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${visita.endereco}, ${visita.numero}',
                style: const TextStyle(
                  color: AppColors.textStrong,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                visita.saidaEm,
                style: const TextStyle(color: AppColors.textMuted),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (visita.rgQuarteiraoCodigo.isNotEmpty)
                _LinhaHistorico(
                  icon: Icons.grid_view,
                  texto: 'Quarteirao RG: ${visita.rgQuarteiraoCodigo}',
                ),
              _LinhaHistorico(icon: Icons.person, texto: visita.agente),
              _LinhaHistorico(icon: Icons.assignment, texto: visita.situacao),
              _LinhaHistorico(
                icon: Icons.my_location,
                texto:
                    'Entrada GPS: ${visita.entradaLatitude.toStringAsFixed(6)}, ${visita.entradaLongitude.toStringAsFixed(6)}',
              ),
              _LinhaHistorico(
                icon: Icons.pin_drop,
                texto:
                    'Saída GPS: ${visita.saidaLatitude.toStringAsFixed(6)}, ${visita.saidaLongitude.toStringAsFixed(6)}',
              ),
              _LinhaHistorico(
                icon: Icons.science,
                texto: visita.focoPositivo
                    ? 'Foco positivo - tubitos: $tubitos'
                    : 'Sem foco positivo',
              ),
              if (visita.observacoes.isNotEmpty)
                _LinhaHistorico(icon: Icons.notes, texto: visita.observacoes),
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Visitas Domiciliares')),
      body: RefreshIndicator(
        onRefresh: carregarDados,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            construirCabecalho(),
            const SizedBox(height: AppSpacing.lg),
            construirDadosImovel(),
            const SizedBox(height: AppSpacing.lg),
            construirControleVisita(),
            const SizedBox(height: AppSpacing.lg),
            construirFinalizacao(),
            const SizedBox(height: AppSpacing.xl),
            const Text(
              'Histórico domiciliar',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.md),
            construirHistorico(),
          ],
        ),
      ),
    );
  }
}

class _LinhaHistorico extends StatelessWidget {
  final IconData icon;
  final String texto;

  const _LinhaHistorico({required this.icon, required this.texto});

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
              texto.isEmpty ? 'Não informado' : texto,
              style: const TextStyle(color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}
