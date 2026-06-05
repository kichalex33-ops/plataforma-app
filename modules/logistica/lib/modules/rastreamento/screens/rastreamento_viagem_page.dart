import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../repositories/rastreamento_repository.dart';

class RastreamentoViagemPage extends StatefulWidget {
  final bool embed;

  const RastreamentoViagemPage({super.key, this.embed = false});

  @override
  State<RastreamentoViagemPage> createState() => _RastreamentoViagemPageState();
}

class _RastreamentoViagemPageState extends State<RastreamentoViagemPage> {
  static const viagemSimuladaId = 'simulado-logistica-001';
  static const rotaNome = 'UBS Centro -> Hospital de Clinicas de POA';

  final repository = RastreamentoRepository();
  Timer? timer;
  int posicaoAtual = 0;
  bool emViagem = true;

  final pontos = const [
    _PontoRota(
      nome: 'UBS Centro',
      latitude: -29.58770,
      longitude: -51.37520,
      status: 'Embarque iniciado',
      detalhe: 'Conferencia de passageiros e documentos',
      minuto: 0,
      velocidade: 0,
    ),
    _PontoRota(
      nome: 'RS-124',
      latitude: -29.64742,
      longitude: -51.31684,
      status: 'Saída do município confirmada',
      detalhe: 'GPS simulado ativo, fila local pendente de sync',
      minuto: 14,
      velocidade: 58,
    ),
    _PontoRota(
      nome: 'BR-386',
      latitude: -29.73121,
      longitude: -51.23531,
      status: 'Trajeto em rodovia',
      detalhe: 'Controle acompanha velocidade e ETA',
      minuto: 28,
      velocidade: 76,
    ),
    _PontoRota(
      nome: 'Eldorado do Sul',
      latitude: -30.08302,
      longitude: -51.61692,
      status: 'Parada tecnica registrada',
      detalhe: 'Passageira com prioridade conferida pelo motorista',
      minuto: 46,
      velocidade: 12,
    ),
    _PontoRota(
      nome: 'Ponte do Guaiba',
      latitude: -30.01264,
      longitude: -51.24508,
      status: 'Entrada monitorada em POA',
      detalhe: 'Central recebeu ponto GPS e atualizou painel',
      minuto: 61,
      velocidade: 42,
    ),
    _PontoRota(
      nome: 'Av. Castelo Branco',
      latitude: -30.02170,
      longitude: -51.22522,
      status: 'Aproximacao do destino',
      detalhe: 'Aviso automatico para recepcao hospitalar',
      minuto: 70,
      velocidade: 34,
    ),
    _PontoRota(
      nome: 'Hospital de Clinicas',
      latitude: -30.03949,
      longitude: -51.20728,
      status: 'Passageiros entregues',
      detalhe: 'Chegada, desembarque e comprovante local',
      minuto: 78,
      velocidade: 0,
    ),
  ];

  final passageiros = const [
    _Passageiro(
      nome: 'Maria L. Santos',
      idade: 67,
      assento: '01',
      embarque: 'UBS Centro',
      destino: 'Hospital de Clinicas',
      necessidade: 'Cadeira de rodas',
      status: 'Embarcada',
    ),
    _Passageiro(
      nome: 'Joao P. Oliveira',
      idade: 52,
      assento: '02',
      embarque: 'UBS Centro',
      destino: 'Hospital de Clinicas',
      necessidade: 'Exame de imagem',
      status: 'Embarcado',
    ),
    _Passageiro(
      nome: 'Ana R. Souza',
      idade: 39,
      assento: '03',
      embarque: 'UBS Centro',
      destino: 'Hospital de Clinicas',
      necessidade: 'Acompanhante autorizada',
      status: 'Embarcada',
    ),
    _Passageiro(
      nome: 'Carlos M. Pereira',
      idade: 74,
      assento: '04',
      embarque: 'Posto Sao Jose',
      destino: 'Hospital de Clinicas',
      necessidade: 'Prioridade de mobilidade',
      status: 'Confirmado',
    ),
  ];

  @override
  void initState() {
    super.initState();
    unawaited(registrarPontoAtual());
    timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || !emViagem) return;
      setState(() {
        if (posicaoAtual < pontos.length - 1) {
          posicaoAtual++;
        } else {
          emViagem = false;
        }
      });
      unawaited(registrarPontoAtual());
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void reiniciar() {
    setState(() {
      posicaoAtual = 0;
      emViagem = true;
    });
    unawaited(registrarPontoAtual());
  }

  Future<void> registrarPontoAtual() async {
    final ponto = pontos[posicaoAtual];
    await repository.registrarPonto(
      municipioId: 'local',
      viagemId: viagemSimuladaId,
      latitude: ponto.latitude,
      longitude: ponto.longitude,
      velocidade: ponto.velocidade.toDouble(),
      origemDado: 'simulado',
    );
  }

  @override
  Widget build(BuildContext context) {
    final ponto = pontos[posicaoAtual];
    final progresso = (posicaoAtual + 1) / pontos.length;
    final minutosRestantes = math.max(0, pontos.last.minuto - ponto.minuto);

    return Scaffold(
      appBar: widget.embed
          ? null
          : AppBar(title: const Text('Logística - Rastreio GPS')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _StatusViagemCard(
            ponto: ponto,
            progresso: progresso,
            emViagem: emViagem,
            minutosRestantes: minutosRestantes,
            onReiniciar: reiniciar,
          ),
          const SizedBox(height: AppSpacing.md),
          _MapaRealCard(pontos: pontos, posicaoAtual: posicaoAtual),
          const SizedBox(height: AppSpacing.md),
          _OperacaoAoVivoCard(ponto: ponto, emViagem: emViagem),
          const SizedBox(height: AppSpacing.md),
          _PassageirosCard(passageiros: passageiros),
          const SizedBox(height: AppSpacing.md),
          _ControleCard(pontos: pontos, posicaoAtual: posicaoAtual),
        ],
      ),
    );
  }
}

class _StatusViagemCard extends StatelessWidget {
  final _PontoRota ponto;
  final double progresso;
  final bool emViagem;
  final int minutosRestantes;
  final VoidCallback onReiniciar;

  const _StatusViagemCard({
    required this.ponto,
    required this.progresso,
    required this.emViagem,
    required this.minutosRestantes,
    required this.onReiniciar,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.directions_bus, color: AppColors.primary),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Viagem Logística 001',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                ),
                Chip(
                  label: Text(emViagem ? 'em_andamento' : 'concluida'),
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  tooltip: 'Reiniciar simulado',
                  onPressed: onReiniciar,
                  icon: const Icon(Icons.replay),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'SIMULACAO OPERACIONAL - GPS simulado salvo localmente',
              style: TextStyle(
                color: AppColors.atrasado,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            LinearProgressIndicator(value: progresso, minHeight: 8),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoPill(icon: Icons.place, text: ponto.nome),
                _InfoPill(icon: Icons.speed, text: '${ponto.velocidade} km/h'),
                _InfoPill(
                  icon: Icons.timer,
                  text: 'ETA ${minutosRestantes}min',
                ),
                const _InfoPill(icon: Icons.sync, text: 'sync pending'),
                const _InfoPill(
                  icon: Icons.gps_fixed,
                  text: 'origem: simulado',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${ponto.status}: ${ponto.detalhe}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Motorista: Roberto Lima | Veiculo: VAN SAUDE-04 | Rota: ${_RastreamentoViagemPageState.rotaNome}',
              style: const TextStyle(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapaRealCard extends StatelessWidget {
  final List<_PontoRota> pontos;
  final int posicaoAtual;

  const _MapaRealCard({required this.pontos, required this.posicaoAtual});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: const [
                Icon(Icons.map, color: AppColors.primary),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Mapa real da rota',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                ),
                Text(
                  'offline + coordenadas reais',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 320,
            child: CustomPaint(
              painter: _MapaRotaPainter(
                pontos: pontos,
                posicaoAtual: posicaoAtual,
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ],
      ),
    );
  }
}

class _OperacaoAoVivoCard extends StatelessWidget {
  final _PontoRota ponto;
  final bool emViagem;

  const _OperacaoAoVivoCard({required this.ponto, required this.emViagem});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Experiencia motorista, app e controle',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: AppSpacing.sm),
            _FluxoTile(
              icon: Icons.badge,
              title: 'Motorista',
              text:
                  'Ve no celular a lista de passageiros, confirma embarque, recebe alerta de destino e envia GPS simulado a cada etapa.',
              destaque: emViagem
                  ? 'Acao atual: ${ponto.status}'
                  : 'Viagem encerrada',
            ),
            const Divider(),
            _FluxoTile(
              icon: Icons.phone_android,
              title: 'App Logística',
              text:
                  'Grava viagem, passageiros, eventos e pontos GPS no SQLite antes de tentar sincronizar.',
              destaque:
                  'Local: ${ponto.latitude.toStringAsFixed(5)}, ${ponto.longitude.toStringAsFixed(5)}',
            ),
            const Divider(),
            _FluxoTile(
              icon: Icons.monitor_heart,
              title: 'Central de controle',
              text:
                  'Acompanha ETA, status do deslocamento, passageiros embarcados e pontos pendentes de envio ao servidor.',
              destaque: 'Servidor preparado: http://10.0.0.4:3000',
            ),
          ],
        ),
      ),
    );
  }
}

class _FluxoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  final String destaque;

  const _FluxoTile({
    required this.icon,
    required this.title,
    required this.text,
    required this.destaque,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text),
          const SizedBox(height: 4),
          Text(destaque, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _PassageirosCard extends StatelessWidget {
  final List<_Passageiro> passageiros;

  const _PassageirosCard({required this.passageiros});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Manifesto de passageiros',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            const Text(
              'Cada passageiro pertence a esta viagem simulada.',
              style: TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: AppSpacing.sm),
            ...passageiros.map(
              (item) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(child: Text(item.assento)),
                title: Text(
                  '${item.nome} (${item.idade})',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  '${item.embarque} -> ${item.destino}\n${item.necessidade}',
                ),
                trailing: Chip(
                  label: Text(item.status),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ControleCard extends StatelessWidget {
  final List<_PontoRota> pontos;
  final int posicaoAtual;

  const _ControleCard({required this.pontos, required this.posicaoAtual});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Linha do tempo do controle',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (var i = 0; i < pontos.length; i++)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  i <= posicaoAtual
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: i <= posicaoAtual
                      ? AppColors.emDia
                      : AppColors.textMuted,
                ),
                title: Text(pontos[i].nome),
                subtitle: Text(
                  '${pontos[i].status} | T+${pontos[i].minuto}min | ${pontos[i].detalhe}',
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoPill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _MapaRotaPainter extends CustomPainter {
  final List<_PontoRota> pontos;
  final int posicaoAtual;

  _MapaRotaPainter({required this.pontos, required this.posicaoAtual});

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = _Bounds.fromPontos(pontos);
    final background = Paint()..color = const Color(0xFFF4F7F2);
    canvas.drawRect(Offset.zero & size, background);

    _drawWater(canvas, size);
    _drawRoads(canvas, size, bounds);
    _drawLabels(canvas, size, bounds);
    _drawRoute(canvas, size, bounds);
    _drawScale(canvas, size);
  }

  void _drawWater(Canvas canvas, Size size) {
    final water = Paint()..color = const Color(0xFFBFDCEC);
    final path = Path()
      ..moveTo(size.width * 0.12, 0)
      ..cubicTo(
        size.width * 0.03,
        size.height * 0.22,
        size.width * 0.16,
        size.height * 0.45,
        size.width * 0.08,
        size.height,
      )
      ..lineTo(0, size.height)
      ..lineTo(0, 0)
      ..close();
    canvas.drawPath(path, water);

    final guaiba = TextPainter(
      text: const TextSpan(
        text: 'Lago Guaiba',
        style: TextStyle(color: Color(0xFF356C87), fontSize: 12),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    guaiba.paint(canvas, Offset(size.width * 0.03, size.height * 0.55));
  }

  void _drawRoads(Canvas canvas, Size size, _Bounds bounds) {
    final roadPaint = Paint()
      ..color = const Color(0xFFD3D8CF)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final mainRoadPaint = Paint()
      ..color = const Color(0xFFE0B55D)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke;

    final roads = [
      [_Geo(-29.64, -51.36), _Geo(-29.73, -51.24), _Geo(-30.02, -51.23)],
      [_Geo(-30.08, -51.62), _Geo(-30.01, -51.25), _Geo(-30.04, -51.21)],
      [_Geo(-29.59, -51.38), _Geo(-29.70, -51.32), _Geo(-30.04, -51.21)],
    ];

    for (var i = 0; i < roads.length; i++) {
      final path = Path();
      for (var j = 0; j < roads[i].length; j++) {
        final point = bounds.project(roads[i][j].lat, roads[i][j].lng, size);
        if (j == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      canvas.drawPath(path, i == 0 ? mainRoadPaint : roadPaint);
    }
  }

  void _drawLabels(Canvas canvas, Size size, _Bounds bounds) {
    final labels = const [
      _GeoLabel('Município origem', -29.62, -51.36),
      _GeoLabel('Eldorado do Sul', -30.08, -51.60),
      _GeoLabel('Porto Alegre', -30.03, -51.22),
      _GeoLabel('Centro historico', -30.03, -51.23),
    ];

    for (final label in labels) {
      final offset = bounds.project(label.lat, label.lng, size);
      final tp = TextPainter(
        text: TextSpan(
          text: label.text,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 120);
      tp.paint(canvas, offset + const Offset(8, -8));
    }
  }

  void _drawRoute(Canvas canvas, Size size, _Bounds bounds) {
    final route = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final completed = Paint()
      ..color = AppColors.emDia
      ..strokeWidth = 7
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final offsets = pontos
        .map((ponto) => bounds.project(ponto.latitude, ponto.longitude, size))
        .toList();

    final path = Path()..moveTo(offsets.first.dx, offsets.first.dy);
    for (final point in offsets.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(path, route);

    final donePath = Path()..moveTo(offsets.first.dx, offsets.first.dy);
    for (var i = 1; i <= posicaoAtual; i++) {
      donePath.lineTo(offsets[i].dx, offsets[i].dy);
    }
    canvas.drawPath(donePath, completed);

    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    for (var i = 0; i < offsets.length; i++) {
      final active = i == posicaoAtual;
      final reached = i <= posicaoAtual;
      canvas.drawCircle(
        offsets[i],
        active ? 13 : 9,
        Paint()
          ..color = reached ? AppColors.emDia : Colors.white
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        offsets[i],
        active ? 13 : 9,
        Paint()
          ..color = AppColors.primary
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      );

      textPainter.text = TextSpan(
        text: pontos[i].nome,
        style: const TextStyle(
          color: AppColors.textStrong,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      );
      textPainter.layout(maxWidth: 80);
      textPainter.paint(canvas, offsets[i] + const Offset(10, 10));
    }

    final vehicle = offsets[posicaoAtual];
    const icon = Icons.directions_bus;
    textPainter.text = TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontFamily: icon.fontFamily,
        package: icon.fontPackage,
        color: AppColors.atrasado,
        fontSize: 34,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, vehicle + const Offset(-17, -42));
  }

  void _drawScale(Canvas canvas, Size size) {
    final label = TextPainter(
      text: const TextSpan(
        text: 'Rota georreferenciada UBS -> Hospital | visualizacao simulada',
        style: TextStyle(color: AppColors.textMuted, fontSize: 11),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width - 24);
    label.paint(canvas, Offset(12, size.height - 26));
  }

  @override
  bool shouldRepaint(covariant _MapaRotaPainter oldDelegate) {
    return oldDelegate.posicaoAtual != posicaoAtual;
  }
}

class _Bounds {
  final double minLat;
  final double maxLat;
  final double minLng;
  final double maxLng;

  const _Bounds({
    required this.minLat,
    required this.maxLat,
    required this.minLng,
    required this.maxLng,
  });

  factory _Bounds.fromPontos(List<_PontoRota> pontos) {
    final latitudes = pontos.map((ponto) => ponto.latitude);
    final longitudes = pontos.map((ponto) => ponto.longitude);
    return _Bounds(
      minLat: latitudes.reduce(math.min) - 0.05,
      maxLat: latitudes.reduce(math.max) + 0.05,
      minLng: longitudes.reduce(math.min) - 0.05,
      maxLng: longitudes.reduce(math.max) + 0.05,
    );
  }

  Offset project(double lat, double lng, Size size) {
    final x = ((lng - minLng) / (maxLng - minLng)) * (size.width - 40) + 20;
    final y = ((maxLat - lat) / (maxLat - minLat)) * (size.height - 48) + 20;
    return Offset(x, y);
  }
}

class _PontoRota {
  final String nome;
  final double latitude;
  final double longitude;
  final String status;
  final String detalhe;
  final int minuto;
  final int velocidade;

  const _PontoRota({
    required this.nome,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.detalhe,
    required this.minuto,
    required this.velocidade,
  });
}

class _Passageiro {
  final String nome;
  final int idade;
  final String assento;
  final String embarque;
  final String destino;
  final String necessidade;
  final String status;

  const _Passageiro({
    required this.nome,
    required this.idade,
    required this.assento,
    required this.embarque,
    required this.destino,
    required this.necessidade,
    required this.status,
  });
}

class _Geo {
  final double lat;
  final double lng;

  const _Geo(this.lat, this.lng);
}

class _GeoLabel {
  final String text;
  final double lat;
  final double lng;

  const _GeoLabel(this.text, this.lat, this.lng);
}
