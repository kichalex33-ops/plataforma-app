import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../database/database_helper.dart';
import '../models/bti_model.dart';
import '../models/bti_point_model.dart';
import '../services/gps_service.dart';

class BTIPage extends StatefulWidget {
  const BTIPage({super.key});

  @override
  State<BTIPage> createState() => _BTIPageState();
}

class _BTIPageState extends State<BTIPage> {
  final localController = TextEditingController();
  final volumeController = TextEditingController();
  final observacoesController = TextEditingController();

  List<BTIModel> aplicacoes = [];
  List<BTIPointModel> pontosBTI = [];
  BTIPointModel? pontoSelecionado;
  Map<String, String> config = {};
  String tipoCriadouro = 'Boca de lobo';
  bool salvando = false;

  @override
  void initState() {
    super.initState();
    carregarDados();
  }

  @override
  void dispose() {
    localController.dispose();
    volumeController.dispose();
    observacoesController.dispose();
    super.dispose();
  }

  Future<void> carregarDados() async {
    final lista = await DatabaseHelper.instance.listarBTI();
    final pontos = await DatabaseHelper.instance.listarPontosBTI();
    final configuracao = await DatabaseHelper.instance.carregarConfiguracao();

    if (!mounted) return;

    setState(() {
      aplicacoes = lista;
      pontosBTI = pontos;
      config = configuracao;
    });
  }

  String formatarDataHora(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/'
        '${data.year} '
        '${data.hour.toString().padLeft(2, '0')}:'
        '${data.minute.toString().padLeft(2, '0')}';
  }

  double get volumeLitros {
    return double.tryParse(volumeController.text.trim().replaceAll(',', '.')) ??
        0;
  }

  double get dosagemCalculada {
    // Fórmula temporária: 1g para cada 50L. Quando a planilha oficial for
    // confirmada, substituímos este ponto por ela sem alterar a tela.
    if (volumeLitros <= 0) return 0;
    return volumeLitros / 50;
  }

  bool mesQuente(DateTime data) {
    return data.month >= 10 || data.month <= 4;
  }

  int intervaloDias(DateTime data) {
    return mesQuente(data) ? 15 : 30;
  }

  String periodicidadeOperacional(DateTime data) {
    return mesQuente(data)
        ? 'Calor - reaplicar em 15 dias'
        : 'Frio - reaplicar em 30 dias';
  }

  DateTime? converterData(String dataTexto) {
    try {
      final partes = dataTexto.split(' ');
      final data = partes[0].split('/');
      final hora = partes.length > 1 ? partes[1].split(':') : ['0', '0'];

      return DateTime(
        int.parse(data[2]),
        int.parse(data[1]),
        int.parse(data[0]),
        int.parse(hora[0]),
        int.parse(hora[1]),
      );
    } catch (_) {
      return null;
    }
  }

  BTIModel? ultimaAplicacaoDoPonto(BTIPointModel ponto) {
    final vinculadas = aplicacoes.where((item) => item.pontoBtiId == ponto.id);
    if (vinculadas.isEmpty) return null;

    final lista = vinculadas.toList()
      ..sort((a, b) {
        final dataA = converterData(a.dataAplicacao) ?? DateTime(1900);
        final dataB = converterData(b.dataAplicacao) ?? DateTime(1900);
        return dataB.compareTo(dataA);
      });

    return lista.first;
  }

  DateTime? proximaAplicacao(BTIModel? aplicacao) {
    if (aplicacao == null) return null;
    final data = converterData(aplicacao.dataAplicacao);
    if (data == null) return null;

    return data.add(Duration(days: intervaloDias(data)));
  }

  String formatarDataCurta(DateTime? data) {
    if (data == null) return 'Sem previsão';
    return '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/'
        '${data.year}';
  }

  Color corPonto(BTIPointModel ponto) {
    final ultima = ultimaAplicacaoDoPonto(ponto);
    final proxima = proximaAplicacao(ultima);

    if (ultima == null || proxima == null) return AppColors.textMuted;

    final hoje = DateTime.now();
    final hojeDia = DateTime(hoje.year, hoje.month, hoje.day);
    final proximaDia = DateTime(proxima.year, proxima.month, proxima.day);

    if (hojeDia.isAfter(proximaDia)) return AppColors.atrasado;
    if (proximaDia.difference(hojeDia).inDays <= 3) return AppColors.vencendo;
    return AppColors.emDia;
  }

  Future<void> salvarAplicacao() async {
    if (localController.text.trim().isEmpty || volumeLitros <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe local e volume estimado.')),
      );
      return;
    }

    setState(() {
      salvando = true;
    });

    try {
      final posicao = await GPSService.obterLocalizacaoObrigatoria();
      final agora = DateTime.now();

      await DatabaseHelper.instance.inserirBTI(
        BTIModel(
          pontoBtiId: pontoSelecionado?.id,
          local: localController.text.trim(),
          tipoCriadouro: tipoCriadouro,
          municipio: config['municipio'] ?? '',
          agente: config['agente'] ?? '',
          dataAplicacao: formatarDataHora(agora),
          volumeLitros: volumeLitros,
          dosagemGramas: dosagemCalculada,
          periodicidade: periodicidadeOperacional(agora),
          observacoes: observacoesController.text.trim(),
          latitude: posicao.latitude,
          longitude: posicao.longitude,
        ),
      );

      localController.clear();
      volumeController.clear();
      observacoesController.clear();

      await carregarDados();

      if (mounted) {
        setState(() {
          pontoSelecionado = null;
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aplicação de BTI registrada.')),
      );
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
          salvando = false;
        });
      }
    }
  }

  Widget construirCabecalho() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.bti,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: const Row(
        children: [
          Icon(Icons.water_drop, color: Colors.white, size: 34),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Aplicações de BTI',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Registro offline com GPS obrigatório',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget construirFormulario() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            if (pontosBTI.isNotEmpty) ...[
              DropdownButtonFormField<int>(
                initialValue: pontoSelecionado?.id,
                decoration: const InputDecoration(
                  labelText: 'Ponto BTI importado',
                  prefixIcon: Icon(Icons.water_drop),
                ),
                items: pontosBTI.map((ponto) {
                  return DropdownMenuItem(
                    value: ponto.id,
                    child: Text(ponto.nome),
                  );
                }).toList(),
                onChanged: (id) {
                  final ponto = pontosBTI.where((item) => item.id == id).first;
                  setState(() {
                    pontoSelecionado = ponto;
                    localController.text = ponto.nome;
                  });
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              if (pontoSelecionado != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Referência: ${pontoSelecionado!.latitude.toStringAsFixed(6)}, ${pontoSelecionado!.longitude.toStringAsFixed(6)}',
                    style: const TextStyle(color: AppColors.textMuted),
                  ),
                ),
              const SizedBox(height: AppSpacing.md),
            ],
            TextField(
              controller: localController,
              decoration: const InputDecoration(
                labelText: 'Local de aplicação',
                prefixIcon: Icon(Icons.place),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String>(
              initialValue: tipoCriadouro,
              decoration: const InputDecoration(
                labelText: 'Tipo de criadouro',
                prefixIcon: Icon(Icons.category),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Boca de lobo',
                  child: Text('Boca de lobo'),
                ),
                DropdownMenuItem(value: 'Vala', child: Text('Vala')),
                DropdownMenuItem(value: 'Poço', child: Text('Poço')),
                DropdownMenuItem(value: 'Canaleta', child: Text('Canaleta')),
                DropdownMenuItem(value: 'Outro', child: Text('Outro')),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  tipoCriadouro = value;
                });
              },
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: volumeController,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Volume estimado em litros',
                prefixIcon: Icon(Icons.water),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              ),
              child: Row(
                children: [
                  const Icon(Icons.event_repeat, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      periodicidadeOperacional(DateTime.now()),
                      style: const TextStyle(
                        color: AppColors.textStrong,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              ),
              child: Text(
                'Dosagem calculada: ${dosagemCalculada.toStringAsFixed(2)} g',
                style: const TextStyle(
                  color: AppColors.textStrong,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: observacoesController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Observações'),
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.bti,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 60),
              ),
              onPressed: salvando ? null : salvarAplicacao,
              icon: Icon(salvando ? Icons.my_location : Icons.save),
              label: Text(
                salvando ? 'Capturando GPS...' : 'Salvar aplicação',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget construirMapaBTI() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.map, color: AppColors.bti),
                SizedBox(width: AppSpacing.sm),
                Text(
                  'Mapa BTI',
                  style: TextStyle(
                    color: AppColors.textStrong,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Calor: reaplicação a cada 15 dias. Frio: reaplicação mensal.',
              style: TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 230,
              child: _BTIMapView(
                pontos: pontosBTI,
                corPonto: corPonto,
                onSelecionar: (ponto) {
                  setState(() {
                    pontoSelecionado = ponto;
                    localController.text = ponto.nome;
                  });
                },
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (pontosBTI.isEmpty)
              const Text(
                'Nenhum ponto BTI importado.',
                style: TextStyle(color: AppColors.textMuted),
              )
            else
              ...pontosBTI.map((ponto) {
                final ultima = ultimaAplicacaoDoPonto(ponto);
                final proxima = proximaAplicacao(ultima);

                return Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: corPonto(ponto).withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.water_drop, color: corPonto(ponto)),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ponto.nome,
                              style: const TextStyle(
                                color: AppColors.textStrong,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              'Última: ${ultima?.dataAplicacao ?? 'sem aplicação'}',
                              style: const TextStyle(
                                color: AppColors.textMuted,
                              ),
                            ),
                            Text(
                              'Próxima: ${formatarDataCurta(proxima)}',
                              style: const TextStyle(
                                color: AppColors.textMuted,
                              ),
                            ),
                            Text(
                              '${ponto.latitude.toStringAsFixed(6)}, ${ponto.longitude.toStringAsFixed(6)}',
                              style: const TextStyle(
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget construirHistorico() {
    if (aplicacoes.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Text('Nenhuma aplicação de BTI registrada.'),
        ),
      );
    }

    return Column(
      children: aplicacoes.map((bti) {
        return Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: const Border(
              left: BorderSide(color: AppColors.bti, width: 5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                bti.local,
                style: const TextStyle(
                  color: AppColors.textStrong,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                bti.dataAplicacao,
                style: const TextStyle(color: AppColors.textMuted),
              ),
              const SizedBox(height: AppSpacing.sm),
              _LinhaBTI(icon: Icons.category, texto: bti.tipoCriadouro),
              _LinhaBTI(
                icon: Icons.water,
                texto: '${bti.volumeLitros.toStringAsFixed(1)} L',
              ),
              _LinhaBTI(
                icon: Icons.science,
                texto: '${bti.dosagemGramas.toStringAsFixed(2)} g',
              ),
              _LinhaBTI(icon: Icons.event_repeat, texto: bti.periodicidade),
              _LinhaBTI(
                icon: Icons.person,
                texto: bti.agente.isEmpty ? 'ACE não informado' : bti.agente,
              ),
              _LinhaBTI(
                icon: Icons.my_location,
                texto:
                    '${bti.latitude.toStringAsFixed(6)}, ${bti.longitude.toStringAsFixed(6)}',
              ),
              if (bti.observacoes.isNotEmpty)
                _LinhaBTI(icon: Icons.notes, texto: bti.observacoes),
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('BTI')),
      body: RefreshIndicator(
        onRefresh: carregarDados,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            construirCabecalho(),
            const SizedBox(height: AppSpacing.lg),
            construirMapaBTI(),
            const SizedBox(height: AppSpacing.lg),
            construirFormulario(),
            const SizedBox(height: AppSpacing.xl),
            const Text(
              'Histórico de BTI',
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

class _LinhaBTI extends StatelessWidget {
  final IconData icon;
  final String texto;

  const _LinhaBTI({required this.icon, required this.texto});

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

class _BTIMapView extends StatelessWidget {
  final List<BTIPointModel> pontos;
  final Color Function(BTIPointModel ponto) corPonto;
  final ValueChanged<BTIPointModel> onSelecionar;

  const _BTIMapView({
    required this.pontos,
    required this.corPonto,
    required this.onSelecionar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFD9ECF1),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _BTIMapPainter())),
          for (final ponto in pontos)
            Positioned(
              left: _x(ponto, context),
              top: _y(ponto, context),
              child: GestureDetector(
                onTap: () => onSelecionar(ponto),
                child: Icon(
                  Icons.location_on,
                  color: corPonto(ponto),
                  size: 34,
                ),
              ),
            ),
          Positioned(
            right: AppSpacing.sm,
            top: AppSpacing.sm,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _LegendaMapa(cor: AppColors.emDia, texto: 'Em dia'),
                  _LegendaMapa(cor: AppColors.vencendo, texto: 'Vencendo'),
                  _LegendaMapa(cor: AppColors.atrasado, texto: 'Atrasado'),
                  _LegendaMapa(cor: AppColors.textMuted, texto: 'Sem registro'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _x(BTIPointModel ponto, BuildContext context) {
    if (pontos.length <= 1) return 92;
    final longs = pontos.map((item) => item.longitude).toList();
    final min = longs.reduce((a, b) => a < b ? a : b);
    final max = longs.reduce((a, b) => a > b ? a : b);
    if ((max - min).abs() < 0.000001) return 92;
    final normalized = (ponto.longitude - min) / (max - min);
    return 24 + normalized * 180;
  }

  double _y(BTIPointModel ponto, BuildContext context) {
    if (pontos.length <= 1) return 92;
    final lats = pontos.map((item) => item.latitude).toList();
    final min = lats.reduce((a, b) => a < b ? a : b);
    final max = lats.reduce((a, b) => a > b ? a : b);
    if ((max - min).abs() < 0.000001) return 92;
    final normalized = (ponto.latitude - min) / (max - min);
    return 24 + (1 - normalized) * 150;
  }
}

class _LegendaMapa extends StatelessWidget {
  final Color cor;
  final String texto;

  const _LegendaMapa({required this.cor, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 9, color: cor),
          const SizedBox(width: 6),
          Text(texto, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}

class _BTIMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final areaPaint = Paint()
      ..color = AppColors.bti.withValues(alpha: 0.11)
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = AppColors.bti.withValues(alpha: 0.28)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final roadPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.82)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final area = Path()
      ..moveTo(size.width * 0.12, size.height * 0.20)
      ..lineTo(size.width * 0.48, size.height * 0.12)
      ..lineTo(size.width * 0.82, size.height * 0.34)
      ..lineTo(size.width * 0.70, size.height * 0.78)
      ..lineTo(size.width * 0.22, size.height * 0.70)
      ..close();

    canvas.drawPath(area, areaPaint);
    canvas.drawPath(area, borderPaint);

    final road = Path()
      ..moveTo(-20, size.height * 0.62)
      ..quadraticBezierTo(
        size.width * 0.35,
        size.height * 0.38,
        size.width + 20,
        size.height * 0.48,
      );
    final roadTwo = Path()
      ..moveTo(size.width * 0.25, -20)
      ..quadraticBezierTo(
        size.width * 0.45,
        size.height * 0.45,
        size.width * 0.30,
        size.height + 20,
      );

    canvas.drawPath(road, roadPaint);
    canvas.drawPath(roadTwo, roadPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
