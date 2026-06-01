import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../database/database_helper.dart';
import '../../models/bti_point_model.dart';
import '../../models/territorio_models.dart';
import '../../repositories/localidade_repository.dart';
import '../../repositories/quarteirao_repository.dart';
import '../../repositories/setor_repository.dart';
import '../../services/gps_service.dart';

class MapaRealPage extends StatefulWidget {
  const MapaRealPage({super.key});

  @override
  State<MapaRealPage> createState() => _MapaRealPageState();
}

class _MapaRealPageState extends State<MapaRealPage> {
  static const tileSize = 256.0;

  final buscaController = TextEditingController();
  final pontos = <_MapaPonto>[];
  final camadasAtivas = <String, bool>{
    _Camada.pe: true,
    _Camada.rg: true,
    _Camada.bti: true,
    _Camada.ovitrampa: true,
    _Camada.foco: true,
    _Camada.area: true,
    _Camada.quarteiraoOperacional: true,
  };

  List<LocalidadeModel> localidades = [];
  List<SetorOperacionalModel> setores = [];
  String? filtroLocalidadeId;
  String? filtroSetorId;
  double centroLat = -29.5406;
  double centroLng = -51.4848;
  int zoom = 13;
  int zoomInicioGesto = 13;
  bool carregando = true;
  bool localizando = false;
  bool painelAberto = true;
  String filtroTempo = 'Todos';
  _MapaPonto? minhaPosicao;

  List<_MapaPonto> get pontosVisiveis {
    final agora = DateTime.now();

    final busca = buscaController.text.trim().toLowerCase();
    final filtrados = pontos.where((ponto) {
      if (camadasAtivas[ponto.camada] != true) return false;
      if (filtroLocalidadeId != null &&
          ponto.localidadeId != null &&
          ponto.localidadeId != filtroLocalidadeId) {
        return false;
      }
      if (filtroSetorId != null &&
          ponto.setorId != null &&
          ponto.setorId != filtroSetorId) {
        return false;
      }
      if (busca.isNotEmpty &&
          !ponto.titulo.toLowerCase().contains(busca) &&
          !ponto.subtitulo.toLowerCase().contains(busca) &&
          !ponto.detalhes.join(' ').toLowerCase().contains(busca)) {
        return false;
      }
      if (filtroTempo == 'Todos') return true;

      final data = ponto.dataReferencia;
      if (data == null) return false;

      if (filtroTempo == 'Hoje') {
        return data.year == agora.year &&
            data.month == agora.month &&
            data.day == agora.day;
      }

      if (filtroTempo == '7 dias') {
        return agora.difference(data).inDays <= 7;
      }

      if (filtroTempo == '30 dias') {
        return agora.difference(data).inDays <= 30;
      }

      return true;
    }).toList();

    if (minhaPosicao != null) {
      return [...filtrados, minhaPosicao!];
    }

    return filtrados;
  }

  @override
  void dispose() {
    buscaController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    carregarPontos();
  }

  Future<void> carregarPontos() async {
    final db = DatabaseHelper.instance;
    final pes = await db.listarPEs();
    final rg = await db.listarRGQuarteiroes();
    final pontosBTI = await db.listarPontosBTI();
    final btiAplicacoes = await db.listarBTI();
    final ovitrampas = await db.listarOvitrampas();
    final areas = await db.listarAreasPrioritarias();
    final visitasDomiciliares = await db.listarVisitasDomiciliares();
    final liraLia = await db.listarLiraLiaVisitas();
    final localidadesOperacionais = await LocalidadeRepository().listar();
    final setoresOperacionais = <SetorOperacionalModel>[];
    for (final localidade in localidadesOperacionais) {
      setoresOperacionais.addAll(
        await SetorRepository().listarPorLocalidade(localidade.sync.id),
      );
    }
    final quarteiroesOperacionais = await QuarteiraoRepository().listarTodos(
      localidadeId: filtroLocalidadeId,
      setorId: filtroSetorId,
    );

    final carregados = <_MapaPonto>[];

    for (final pe in pes) {
      if (pe.latitude == null || pe.longitude == null) continue;
      carregados.add(
        _MapaPonto(
          camada: _Camada.pe,
          titulo: pe.nome,
          subtitulo: '${pe.tipo} - ${pe.status}',
          detalhes: [
            'Endereco: ${pe.endereco}',
            'Status: ${pe.status}',
            'Ultima visita: ${pe.ultimaVisita ?? 'sem visita'}',
          ],
          latitude: pe.latitude!,
          longitude: pe.longitude!,
          cor: _corPE(pe.status),
          icone: Icons.location_city,
          dataReferencia: _parseData(pe.ultimaVisita),
        ),
      );
    }

    for (final item in rg) {
      carregados.add(
        _MapaPonto(
          camada: _Camada.rg,
          titulo: 'RG ${item.codigo}',
          subtitulo: 'Quarteirao ${item.ordem}',
          detalhes: [
            'Codigo: ${item.codigo}',
            'Ordem: ${item.ordem}',
            'Referencia: ${item.latitude.toStringAsFixed(6)}, ${item.longitude.toStringAsFixed(6)}',
          ],
          latitude: item.latitude,
          longitude: item.longitude,
          cor: AppColors.primary,
          icone: Icons.crop_square,
        ),
      );
    }

    for (final ponto in pontosBTI) {
      final ultima = _ultimaAplicacaoBTI(ponto.id, ponto.nome, btiAplicacoes);
      final status = _statusBTI(ultima);
      carregados.add(
        _MapaPonto(
          camada: _Camada.bti,
          titulo: ponto.nome,
          subtitulo: 'BTI - $status',
          detalhes: [
            'Ponto BTI',
            'Ultima aplicacao: ${ultima?.dataAplicacao ?? 'sem registro'}',
            'Periodicidade: ${_periodicidadeBTI()}',
            'Status: $status',
          ],
          latitude: ponto.latitude,
          longitude: ponto.longitude,
          cor: _corStatusBTI(status),
          icone: Icons.water_drop,
          dataReferencia: _parseData(ultima?.dataAplicacao),
        ),
      );
    }

    for (final item in ovitrampas) {
      carregados.add(
        _MapaPonto(
          camada: _Camada.ovitrampa,
          titulo: item.codigo,
          subtitulo: 'Ovitrampa - ${item.status}',
          detalhes: [
            'Endereco: ${item.endereco}',
            'Status: ${item.status}',
            'Instalada por: ${item.agenteInstalacao}',
            'Ultima checagem: ${item.ultimaChecagem ?? 'sem checagem'}',
          ],
          latitude: item.latitude,
          longitude: item.longitude,
          cor: AppColors.ovitrampas,
          icone: Icons.bug_report,
          dataReferencia: _parseData(item.ultimaChecagem ?? item.instaladaEm),
        ),
      );
    }

    for (final area in areas) {
      carregados.add(
        _MapaPonto(
          camada: _Camada.area,
          titulo: area.nome,
          subtitulo: '${area.tipoRisco} - ${area.grauRisco}',
          detalhes: [
            'Endereco: ${area.endereco}',
            'Prioridade GUT: ${area.prioridadeGUT}',
            'Motivo: ${area.motivoPrioridade}',
            'Status: ${area.status}',
          ],
          latitude: area.latitude,
          longitude: area.longitude,
          cor: AppColors.atrasado,
          icone: Icons.priority_high,
          dataReferencia: _parseData(area.dataRegistro),
        ),
      );
    }

    for (final visita in visitasDomiciliares) {
      if (!visita.focoPositivo) continue;
      carregados.add(
        _MapaPonto(
          camada: _Camada.foco,
          titulo: 'Foco domiciliar',
          subtitulo: '${visita.endereco}, ${visita.numero}',
          detalhes: [
            'ACE: ${visita.agente}',
            'Situacao: ${visita.situacao}',
            'Tubitos: ${visita.tubitos.isEmpty ? '-' : visita.tubitos.join(', ')}',
            'Quarteirao RG: ${visita.rgQuarteiraoCodigo.isEmpty ? '-' : visita.rgQuarteiraoCodigo}',
          ],
          latitude: visita.saidaLatitude,
          longitude: visita.saidaLongitude,
          cor: AppColors.atrasado,
          icone: Icons.warning_amber,
          dataReferencia: _parseData(visita.saidaEm),
        ),
      );
    }

    for (final visita in liraLia) {
      if (visita.focosPositivos <= 0) continue;
      carregados.add(
        _MapaPonto(
          camada: _Camada.foco,
          titulo: '${visita.tipoLevantamento} com foco',
          subtitulo: 'RG ${visita.rgQuarteiraoCodigo}',
          detalhes: [
            'Focos positivos: ${visita.focosPositivos}',
            'Imoveis trabalhados: ${visita.imoveisTrabalhados}',
            'Imoveis fechados: ${visita.imoveisFechados}',
            'ACE: ${visita.agente}',
          ],
          latitude: visita.latitude,
          longitude: visita.longitude,
          cor: AppColors.atrasado,
          icone: Icons.warning_amber,
          dataReferencia: _parseData(visita.dataRegistro),
        ),
      );
    }

    for (final quarteirao in quarteiroesOperacionais) {
      if (quarteirao.centroLatitude == null ||
          quarteirao.centroLongitude == null) {
        continue;
      }
      carregados.add(
        _MapaPonto(
          camada: _Camada.quarteiraoOperacional,
          titulo: 'Quarteirao ${quarteirao.codigo}',
          subtitulo: 'Ordem ${quarteirao.ordemExecucao} - ${quarteirao.status}',
          detalhes: [
            'Imoveis previstos: ${quarteirao.totalImoveisPrevistos}',
            'Visitados: ${quarteirao.totalVisitados}',
            'Fechados: ${quarteirao.totalFechados}',
            'Recusas: ${quarteirao.totalRecusas}',
            'Focos: ${quarteirao.totalFocos}',
            'Pendencias: ${quarteirao.totalPendencias}',
          ],
          latitude: quarteirao.centroLatitude!,
          longitude: quarteirao.centroLongitude!,
          cor: _corQuarteiraoOperacional(quarteirao.status),
          icone: Icons.grid_view,
          dataReferencia: _parseData(quarteirao.sync.updatedAt),
          localidadeId: quarteirao.localidadeId,
          setorId: quarteirao.setorId,
        ),
      );
    }

    if (carregados.isNotEmpty) {
      centroLat =
          carregados.map((item) => item.latitude).reduce((a, b) => a + b) /
          carregados.length;
      centroLng =
          carregados.map((item) => item.longitude).reduce((a, b) => a + b) /
          carregados.length;
    }

    if (!mounted) return;

    setState(() {
      pontos
        ..clear()
        ..addAll(carregados);
      localidades = localidadesOperacionais;
      setores = setoresOperacionais;
      carregando = false;
    });
  }

  static Color _corPE(String status) {
    if (status == 'Em dia') return AppColors.emDia;
    if (status == 'Vencendo') return AppColors.vencendo;
    return AppColors.atrasado;
  }

  DateTime? _parseData(String? valor) {
    if (valor == null || valor.trim().isEmpty) return null;
    final texto = valor.trim();
    final direto = DateTime.tryParse(texto);
    if (direto != null) return direto;

    final partes = texto.split(RegExp(r'[/\s:]'));
    if (partes.length < 3) return null;

    final dia = int.tryParse(partes[0]);
    final mes = int.tryParse(partes[1]);
    final ano = int.tryParse(partes[2]);
    final hora = partes.length > 3 ? int.tryParse(partes[3]) ?? 0 : 0;
    final minuto = partes.length > 4 ? int.tryParse(partes[4]) ?? 0 : 0;

    if (dia == null || mes == null || ano == null) return null;
    return DateTime(ano, mes, dia, hora, minuto);
  }

  dynamic _ultimaAplicacaoBTI(int? pontoId, String nome, List<dynamic> apps) {
    final candidatas = apps.where((item) {
      return item.pontoBtiId == pontoId || item.local == nome;
    }).toList();

    candidatas.sort((a, b) {
      final dataA = _parseData(a.dataAplicacao) ?? DateTime(1900);
      final dataB = _parseData(b.dataAplicacao) ?? DateTime(1900);
      return dataB.compareTo(dataA);
    });

    return candidatas.isEmpty ? null : candidatas.first;
  }

  bool _periodoCalor() {
    final mes = DateTime.now().month;
    return mes >= 10 || mes <= 4;
  }

  String _periodicidadeBTI() {
    return _periodoCalor() ? '15 dias (calor)' : '30 dias (frio)';
  }

  String _statusBTI(dynamic ultima) {
    if (ultima == null) return 'Sem registro';

    final data = _parseData(ultima.dataAplicacao);
    if (data == null) return 'Sem registro';

    final intervalo = _periodoCalor() ? 15 : 30;
    final dias = DateTime.now().difference(data).inDays;

    if (dias <= intervalo) return 'Em dia';
    if (dias <= intervalo + 5) return 'Vencendo';
    return 'Atrasado';
  }

  Color _corStatusBTI(String status) {
    if (status == 'Em dia') return AppColors.emDia;
    if (status == 'Vencendo') return AppColors.vencendo;
    if (status == 'Atrasado') return AppColors.atrasado;
    return AppColors.textMuted;
  }

  Color _corQuarteiraoOperacional(String status) {
    switch (status) {
      case 'concluido':
        return AppColors.emDia;
      case 'em_andamento':
        return AppColors.informativo;
      case 'pendente':
      case 'critico':
        return AppColors.atrasado;
      default:
        return AppColors.textMuted;
    }
  }

  double longitudeParaTileX(double longitude, int zoom) {
    final n = math.pow(2.0, zoom).toDouble();
    return (longitude + 180.0) / 360.0 * n;
  }

  double latitudeParaTileY(double latitude, int zoom) {
    final latRad = latitude * math.pi / 180.0;
    final n = math.pow(2.0, zoom).toDouble();
    return (1.0 -
            math.log(math.tan(latRad) + (1.0 / math.cos(latRad))) / math.pi) /
        2.0 *
        n;
  }

  double tileXParaLongitude(double x, int zoom) {
    final n = math.pow(2.0, zoom).toDouble();
    return x / n * 360.0 - 180.0;
  }

  double tileYParaLatitude(double y, int zoom) {
    final n = math.pow(2.0, zoom).toDouble();
    final valor = math.pi * (1 - 2 * y / n);
    final senoHiperbolico = (math.exp(valor) - math.exp(-valor)) / 2;
    final rad = math.atan(senoHiperbolico);
    return rad * 180.0 / math.pi;
  }

  ({double latitude, double longitude}) telaParaCoordenada(
    Offset posicao,
    Size size,
  ) {
    final centroX = longitudeParaTileX(centroLng, zoom);
    final centroY = latitudeParaTileY(centroLat, zoom);
    final pontoX = centroX + (posicao.dx - size.width / 2) / tileSize;
    final pontoY = centroY + (posicao.dy - size.height / 2) / tileSize;

    return (
      latitude: tileYParaLatitude(pontoY, zoom),
      longitude: tileXParaLongitude(pontoX, zoom),
    );
  }

  Offset pontoParaTela(_MapaPonto ponto, Size size) {
    final centroX = longitudeParaTileX(centroLng, zoom);
    final centroY = latitudeParaTileY(centroLat, zoom);
    final pontoX = longitudeParaTileX(ponto.longitude, zoom);
    final pontoY = latitudeParaTileY(ponto.latitude, zoom);

    return Offset(
      ((pontoX - centroX) * tileSize) + size.width / 2,
      ((pontoY - centroY) * tileSize) + size.height / 2,
    );
  }

  void moverMapaPorDelta(Offset delta) {
    final centroX = longitudeParaTileX(centroLng, zoom);
    final centroY = latitudeParaTileY(centroLat, zoom);
    final novoX = centroX - delta.dx / tileSize;
    final novoY = centroY - delta.dy / tileSize;

    setState(() {
      centroLng = tileXParaLongitude(novoX, zoom);
      centroLat = tileYParaLatitude(novoY, zoom);
    });
  }

  void iniciarGestoMapa(ScaleStartDetails details) {
    zoomInicioGesto = zoom;
  }

  void atualizarGestoMapa(ScaleUpdateDetails details) {
    if (details.focalPointDelta != Offset.zero) {
      moverMapaPorDelta(details.focalPointDelta);
    }

    if (details.pointerCount < 2) return;

    final escala = details.scale;
    if ((escala - 1).abs() < 0.08) return;

    final novoZoom = (zoomInicioGesto + math.log(escala) / math.ln2)
        .round()
        .clamp(11, 18);

    if (novoZoom != zoom) {
      setState(() => zoom = novoZoom);
    }
  }

  void zoomDuploToque() {
    alterarZoom(1);
  }

  Future<void> abrirCadastroPontoBTI({
    required double latitude,
    required double longitude,
  }) async {
    final nomeController = TextEditingController();
    final descricaoController = TextEditingController();

    final salvar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Adicionar ponto BTI'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomeController,
                decoration: const InputDecoration(
                  labelText: 'Nome do ponto',
                  hintText: 'Ex.: Boca de lobo - Rua Central',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: descricaoController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Descricao',
                  hintText: 'Referencia do local, acesso, observacoes...',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.add_location_alt),
              label: const Text('Salvar'),
            ),
          ],
        );
      },
    );

    if (salvar != true) {
      nomeController.dispose();
      descricaoController.dispose();
      return;
    }

    final nome = nomeController.text.trim();
    final descricao = descricaoController.text.trim();
    nomeController.dispose();
    descricaoController.dispose();

    if (nome.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe o nome do ponto BTI.')),
      );
      return;
    }

    await DatabaseHelper.instance.inserirPontoBTI(
      BTIPointModel(
        nome: nome,
        descricao: descricao,
        latitude: latitude,
        longitude: longitude,
      ),
    );

    await carregarPontos();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ponto BTI cadastrado no mapa.')),
    );
  }

  void adicionarBTINoCentro() {
    abrirCadastroPontoBTI(latitude: centroLat, longitude: centroLng);
  }

  void adicionarBTIComToque(LongPressStartDetails details, Size size) {
    final coordenada = telaParaCoordenada(details.localPosition, size);
    abrirCadastroPontoBTI(
      latitude: coordenada.latitude,
      longitude: coordenada.longitude,
    );
  }

  void alterarZoom(int delta) {
    setState(() {
      zoom = (zoom + delta).clamp(11, 18);
    });
  }

  void centralizarTudo() {
    final visiveis = pontosVisiveis;
    if (visiveis.isEmpty) return;

    setState(() {
      centroLat =
          visiveis.map((item) => item.latitude).reduce((a, b) => a + b) /
          visiveis.length;
      centroLng =
          visiveis.map((item) => item.longitude).reduce((a, b) => a + b) /
          visiveis.length;
      zoom = 13;
    });
  }

  Future<void> localizarUsuario() async {
    if (localizando) return;

    setState(() => localizando = true);

    try {
      final posicao = await GPSService.obterLocalizacaoObrigatoria();

      setState(() {
        centroLat = posicao.latitude;
        centroLng = posicao.longitude;
        zoom = 16;
        minhaPosicao = _MapaPonto(
          camada: 'minha_posicao',
          titulo: 'Minha posicao',
          subtitulo: 'ACE em campo',
          detalhes: [
            'GPS capturado agora',
            '${posicao.latitude.toStringAsFixed(6)}, ${posicao.longitude.toStringAsFixed(6)}',
          ],
          latitude: posicao.latitude,
          longitude: posicao.longitude,
          cor: AppColors.informativo,
          icone: Icons.gps_fixed,
          dataReferencia: DateTime.now(),
        );
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) setState(() => localizando = false);
    }
  }

  void abrirDetalhes(_MapaPonto ponto) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: ponto.cor.withValues(alpha: 0.14),
                    child: Icon(ponto.icone, color: ponto.cor),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ponto.titulo,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textStrong,
                          ),
                        ),
                        Text(
                          ponto.subtitulo,
                          style: const TextStyle(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              ...ponto.detalhes.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          item,
                          style: const TextStyle(color: AppColors.textStrong),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: AppSpacing.xl),
              Text(
                '${ponto.latitude.toStringAsFixed(6)}, ${ponto.longitude.toStringAsFixed(6)}',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget construirTiles(Size size) {
    final centroX = longitudeParaTileX(centroLng, zoom);
    final centroY = latitudeParaTileY(centroLat, zoom);
    final baseX = centroX.floor();
    final baseY = centroY.floor();
    final tilesHorizontais = (size.width / tileSize).ceil() + 2;
    final tilesVerticais = (size.height / tileSize).ceil() + 2;
    final inicioX = baseX - tilesHorizontais ~/ 2;
    final inicioY = baseY - tilesVerticais ~/ 2;
    final maxTile = math.pow(2, zoom).toInt();

    final widgets = <Widget>[];

    for (var dx = 0; dx <= tilesHorizontais; dx++) {
      for (var dy = 0; dy <= tilesVerticais; dy++) {
        final tileX = inicioX + dx;
        final tileY = inicioY + dy;
        if (tileY < 0 || tileY >= maxTile) continue;
        final wrappedX = ((tileX % maxTile) + maxTile) % maxTile;
        final left = (tileX - centroX) * tileSize + size.width / 2;
        final top = (tileY - centroY) * tileSize + size.height / 2;

        widgets.add(
          Positioned(
            left: left,
            top: top,
            width: tileSize,
            height: tileSize,
            child: Image.network(
              'https://tile.openstreetmap.org/$zoom/$wrappedX/$tileY.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: const Color(0xFFE8EEF1),
                  child: const Center(
                    child: Icon(Icons.map_outlined, color: Colors.black26),
                  ),
                );
              },
            ),
          ),
        );
      }
    }

    return Stack(children: widgets);
  }

  Widget construirMarcadores(Size size) {
    return Stack(
      children: pontosVisiveis.map((ponto) {
        final posicao = pontoParaTela(ponto, size);
        if (posicao.dx < -96 ||
            posicao.dy < -96 ||
            posicao.dx > size.width + 96 ||
            posicao.dy > size.height + 96) {
          return const SizedBox.shrink();
        }

        return Positioned(
          left: posicao.dx - 56,
          top: posicao.dy - 58,
          child: _MapaMarcador(ponto: ponto, onTap: () => abrirDetalhes(ponto)),
        );
      }).toList(),
    );
  }

  Widget construirPainelCamadas() {
    final definicoes = [
      _CamadaDef(_Camada.pe, 'PEs', Icons.location_city, AppColors.primary),
      _CamadaDef(_Camada.rg, 'RG', Icons.grid_view, AppColors.informativo),
      _CamadaDef(_Camada.bti, 'BTI', Icons.water_drop, AppColors.bti),
      _CamadaDef(
        _Camada.ovitrampa,
        'Ovitrampas',
        Icons.bug_report,
        AppColors.ovitrampas,
      ),
      _CamadaDef(
        _Camada.foco,
        'Focos',
        Icons.warning_amber,
        AppColors.atrasado,
      ),
      _CamadaDef(
        _Camada.area,
        'Areas',
        Icons.priority_high,
        AppColors.atrasado,
      ),
      _CamadaDef(
        _Camada.quarteiraoOperacional,
        'Setores',
        Icons.grid_view,
        AppColors.primary,
      ),
    ];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.layers, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              const Expanded(
                child: Text(
                  'Camadas territoriais',
                  style: TextStyle(
                    color: AppColors.textStrong,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                tooltip: painelAberto ? 'Recolher' : 'Expandir',
                onPressed: () => setState(() => painelAberto = !painelAberto),
                icon: Icon(
                  painelAberto ? Icons.expand_less : Icons.expand_more,
                ),
              ),
            ],
          ),
          if (painelAberto) ...[
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: buscaController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                isDense: true,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: buscaController.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Limpar busca',
                        onPressed: () {
                          buscaController.clear();
                          setState(() {});
                        },
                        icon: const Icon(Icons.close),
                      ),
                hintText: 'Buscar ponto, RG, BTI ou endereco',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final item in ['Todos', 'Hoje', '7 dias', '30 dias'])
                  ChoiceChip(
                    label: Text(item),
                    selected: filtroTempo == item,
                    onSelected: (_) => setState(() => filtroTempo = item),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<String>(
              initialValue: filtroLocalidadeId,
              isDense: true,
              decoration: const InputDecoration(
                labelText: 'Filtrar localidade',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('Todas'),
                ),
                ...localidades.map(
                  (item) => DropdownMenuItem(
                    value: item.sync.id,
                    child: Text(item.nome),
                  ),
                ),
              ],
              onChanged: (value) async {
                setState(() {
                  filtroLocalidadeId = value;
                  filtroSetorId = null;
                  carregando = true;
                });
                await carregarPontos();
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<String>(
              initialValue: filtroSetorId,
              isDense: true,
              decoration: const InputDecoration(
                labelText: 'Filtrar setor',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('Todos'),
                ),
                ...setores
                    .where(
                      (item) =>
                          filtroLocalidadeId == null ||
                          item.localidadeId == filtroLocalidadeId,
                    )
                    .map(
                      (item) => DropdownMenuItem(
                        value: item.sync.id,
                        child: Text('${item.codigo} - ${item.nome}'),
                      ),
                    ),
              ],
              onChanged: (value) async {
                setState(() {
                  filtroSetorId = value;
                  carregando = true;
                });
                await carregarPontos();
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            ...definicoes.map((def) {
              final total = pontos.where((p) => p.camada == def.id).length;
              final ativo = camadasAtivas[def.id] ?? false;

              return SwitchListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                value: ativo,
                onChanged: (value) {
                  setState(() => camadasAtivas[def.id] = value);
                },
                secondary: Icon(def.icone, color: def.cor),
                title: Text('${def.nome} ($total)'),
              );
            }),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa Territorial'),
        actions: [
          IconButton(
            tooltip: 'Adicionar ponto BTI no centro',
            onPressed: adicionarBTINoCentro,
            icon: const Icon(Icons.add_location_alt),
          ),
          IconButton(
            tooltip: 'Centralizar',
            onPressed: centralizarTudo,
            icon: const Icon(Icons.center_focus_strong),
          ),
          IconButton(
            tooltip: 'Atualizar',
            onPressed: carregarPontos,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: carregando
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final size = Size(constraints.maxWidth, constraints.maxHeight);

                return GestureDetector(
                  onScaleStart: iniciarGestoMapa,
                  onScaleUpdate: atualizarGestoMapa,
                  onLongPressStart: (details) =>
                      adicionarBTIComToque(details, size),
                  onDoubleTap: zoomDuploToque,
                  child: Stack(
                    children: [
                      Positioned.fill(child: construirTiles(size)),
                      Positioned.fill(child: construirMarcadores(size)),
                      Positioned(
                        top: AppSpacing.md,
                        left: AppSpacing.md,
                        right: AppSpacing.md,
                        child: construirPainelCamadas(),
                      ),
                      Positioned(
                        right: AppSpacing.md,
                        bottom: AppSpacing.xl,
                        child: Column(
                          children: [
                            _BotaoMapa(
                              icon: Icons.add,
                              onPressed: () => alterarZoom(1),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            _BotaoMapa(
                              icon: Icons.remove,
                              onPressed: () => alterarZoom(-1),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            _BotaoMapa(
                              icon: localizando
                                  ? Icons.gps_fixed
                                  : Icons.my_location,
                              onPressed: localizarUsuario,
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        left: AppSpacing.md,
                        bottom: AppSpacing.md,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(
                              AppSpacing.cardRadius,
                            ),
                          ),
                          child: Text(
                            'OSM zoom $zoom - ${pontosVisiveis.length}/${pontos.length} pontos',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _Camada {
  static const pe = 'pe';
  static const rg = 'rg';
  static const bti = 'bti';
  static const ovitrampa = 'ovitrampa';
  static const foco = 'foco';
  static const area = 'area';
  static const quarteiraoOperacional = 'quarteirao_operacional';
}

class _CamadaDef {
  final String id;
  final String nome;
  final IconData icone;
  final Color cor;

  const _CamadaDef(this.id, this.nome, this.icone, this.cor);
}

class _MapaPonto {
  final String camada;
  final String titulo;
  final String subtitulo;
  final List<String> detalhes;
  final double latitude;
  final double longitude;
  final Color cor;
  final IconData icone;
  final DateTime? dataReferencia;
  final String? localidadeId;
  final String? setorId;

  const _MapaPonto({
    required this.camada,
    required this.titulo,
    required this.subtitulo,
    required this.detalhes,
    required this.latitude,
    required this.longitude,
    required this.cor,
    required this.icone,
    this.dataReferencia,
    this.localidadeId,
    this.setorId,
  });
}

class _MapaMarcador extends StatelessWidget {
  final _MapaPonto ponto;
  final VoidCallback onTap;

  const _MapaMarcador({required this.ponto, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final visual = _visualDoMarcador(ponto);
    final rotulo = _rotuloDoMarcador(ponto);

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 112,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: visual.tamanho,
              height: visual.tamanho,
              decoration: BoxDecoration(
                color: visual.preenchimento,
                shape: visual.formato,
                border: Border.all(
                  color: visual.borda,
                  width: visual.bordaLargura,
                ),
                borderRadius: visual.formato == BoxShape.rectangle
                    ? BorderRadius.circular(visual.raio)
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.30),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (visual.mostrarAnel)
                    Container(
                      width: visual.tamanho - 8,
                      height: visual.tamanho - 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.65),
                          width: 1.4,
                        ),
                      ),
                    ),
                  Icon(
                    ponto.icone,
                    color: visual.iconeCor,
                    size: visual.iconeTamanho,
                  ),
                ],
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -3),
              child: Transform.rotate(
                angle: math.pi / 4,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: visual.preenchimento,
                    border: Border(
                      right: BorderSide(color: visual.borda, width: 1.4),
                      bottom: BorderSide(color: visual.borda, width: 1.4),
                    ),
                  ),
                ),
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -2),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 106),
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.98),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: visual.borda.withValues(alpha: 0.45),
                    width: 1.1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.22),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  rotulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _escurecer(visual.borda),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _rotuloDoMarcador(_MapaPonto ponto) {
    if (ponto.titulo == 'Minha posicao') return 'Voce';
    if (ponto.camada == _Camada.pe) return 'PE';
    if (ponto.camada == _Camada.rg) return ponto.titulo;
    if (ponto.camada == _Camada.bti) return 'BTI';
    if (ponto.camada == _Camada.ovitrampa) return 'Ovitrampa';
    if (ponto.camada == _Camada.foco) return 'Foco positivo';
    if (ponto.camada == _Camada.area) return 'Area critica';
    if (ponto.camada == _Camada.quarteiraoOperacional) {
      return ponto.titulo.replaceFirst('Quarteirao ', 'Q ');
    }
    return ponto.titulo;
  }

  Color _escurecer(Color color) {
    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness * 0.58).clamp(0.18, 0.38).toDouble();
    return hsl.withLightness(lightness).toColor();
  }

  _MarkerVisual _visualDoMarcador(_MapaPonto ponto) {
    if (ponto.titulo == 'Minha posicao') {
      return _MarkerVisual(
        tamanho: 42,
        preenchimento: AppColors.informativo,
        borda: Colors.white,
        iconeCor: Colors.white,
        iconeTamanho: 22,
        formato: BoxShape.circle,
        raio: 999,
        bordaLargura: 3,
        mostrarAnel: true,
      );
    }

    if (ponto.camada == _Camada.foco) {
      return _MarkerVisual(
        tamanho: 42,
        preenchimento: AppColors.atrasado,
        borda: Colors.white,
        iconeCor: Colors.white,
        iconeTamanho: 23,
        formato: BoxShape.rectangle,
        raio: 8,
        bordaLargura: 2,
      );
    }

    if (ponto.camada == _Camada.quarteiraoOperacional ||
        ponto.camada == _Camada.rg) {
      return _MarkerVisual(
        tamanho: 38,
        preenchimento: Colors.white,
        borda: ponto.cor,
        iconeCor: ponto.cor,
        iconeTamanho: 22,
        formato: BoxShape.rectangle,
        raio: 7,
        bordaLargura: 2.2,
      );
    }

    if (ponto.camada == _Camada.bti) {
      return _MarkerVisual(
        tamanho: 36,
        preenchimento: ponto.cor,
        borda: Colors.white,
        iconeCor: Colors.white,
        iconeTamanho: 21,
        formato: BoxShape.circle,
        raio: 999,
        bordaLargura: 2,
      );
    }

    return _MarkerVisual(
      tamanho: 36,
      preenchimento: ponto.cor,
      borda: Colors.white,
      iconeCor: Colors.white,
      iconeTamanho: 20,
      formato: BoxShape.rectangle,
      raio: 8,
      bordaLargura: 2,
    );
  }
}

class _BotaoMapa extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _BotaoMapa({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      elevation: 3,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        child: SizedBox(
          width: 46,
          height: 46,
          child: Icon(icon, color: AppColors.primary),
        ),
      ),
    );
  }
}

class _MarkerVisual {
  final double tamanho;
  final Color preenchimento;
  final Color borda;
  final Color iconeCor;
  final double iconeTamanho;
  final BoxShape formato;
  final double raio;
  final double bordaLargura;
  final bool mostrarAnel;

  const _MarkerVisual({
    required this.tamanho,
    required this.preenchimento,
    required this.borda,
    required this.iconeCor,
    required this.iconeTamanho,
    required this.formato,
    required this.raio,
    required this.bordaLargura,
    this.mostrarAnel = false,
  });
}
