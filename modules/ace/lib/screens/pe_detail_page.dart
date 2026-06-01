import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../database/database_helper.dart';
import '../models/visita_pe_model.dart';
import '../services/gps_service.dart';
import '../services/sync_service.dart';
import '../utils/epidemiological_calendar.dart';

class PEDetailPage extends StatefulWidget {
  final int peId;
  final String nome;
  final String endereco;

  const PEDetailPage({
    super.key,
    required this.peId,
    required this.nome,
    required this.endereco,
  });

  @override
  State<PEDetailPage> createState() => _PEDetailPageState();
}

class _PEDetailPageState extends State<PEDetailPage> {
  final observacoesController = TextEditingController();
  final tubitosController = TextEditingController();
  final imagePicker = ImagePicker();

  String situacaoSelecionada = 'Visitado';
  String? fotoTemporariaPath;
  bool focoPositivo = false;
  int ultimoTubitoGlobal = 0;
  DateTime? entradaEm;
  double? entradaLatitude;
  double? entradaLongitude;
  bool visitaIniciada = false;
  bool finalizacaoAberta = false;
  bool capturandoGPS = false;

  List<VisitaPEModel> visitas = [];
  Map<String, String> config = {};

  @override
  void initState() {
    super.initState();
    carregarDados();
  }

  @override
  void dispose() {
    observacoesController.dispose();
    tubitosController.dispose();
    super.dispose();
  }

  Future<void> carregarDados() async {
    final lista = await DatabaseHelper.instance.listarVisitasPE(widget.peId);
    final configuracao = await DatabaseHelper.instance.carregarConfiguracao();
    final ultimoTubito = await DatabaseHelper.instance
        .buscarUltimoNumeroTubito();

    if (!mounted) return;

    setState(() {
      visitas = lista;
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

  Future<void> tirarFoto() async {
    final foto = await imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
      maxWidth: 1600,
    );

    if (foto == null) return;

    setState(() {
      fotoTemporariaPath = foto.path;
    });
  }

  Future<void> iniciarVisita() async {
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
        fotoTemporariaPath = null;
        focoPositivo = false;
        situacaoSelecionada = 'Visitado';
        observacoesController.clear();
        tubitosController.clear();
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

  Future<void> registrarVisita() async {
    if (!visitaIniciada || entradaEm == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inicie a visita antes de finalizar.')),
      );
      return;
    }

    if (fotoTemporariaPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tire uma foto do local para registrar a visita.'),
        ),
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
    final entradaFormatada = formatarDataHora(entradaEm!);
    final saidaFormatada = formatarDataHora(saidaEm);
    final fotoSalvaPath = await DatabaseHelper.instance.salvarFotoVisitaPE(
      fotoTemporariaPath!,
    );
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

    final visitaId = await DatabaseHelper.instance.inserirVisitaPE(
      peId: widget.peId,
      dataVisita: saidaFormatada,
      entradaEm: entradaFormatada,
      saidaEm: saidaFormatada,
      municipio: config['municipio'] ?? '',
      agente: config['agente'] ?? '',
      situacao: situacaoSelecionada,
      focoPositivo: focoPositivo,
      quantidadeTubitos: quantidadeTubitos,
      observacoes: observacoesController.text.trim(),
      fotoPath: fotoSalvaPath,
      latitude: saidaLatitude,
      longitude: saidaLongitude,
      entradaLatitude: entradaLatitude,
      entradaLongitude: entradaLongitude,
      saidaLatitude: saidaLatitude,
      saidaLongitude: saidaLongitude,
      tubitoInicial: tubitoInicialServidor,
    );

    unawaited(
      sincronizarVisitaPE({
        'id': visitaId,
        'pe_id': widget.peId,
        'data_visita': saidaFormatada,
        'entrada_em': entradaFormatada,
        'saida_em': saidaFormatada,
        'municipio': config['municipio'] ?? '',
        'agente': config['agente'] ?? '',
        'situacao': situacaoSelecionada,
        'foco_positivo': focoPositivo ? 1 : 0,
        'quantidade_tubitos': focoPositivo ? quantidadeTubitos : 0,
        'observacoes': observacoesController.text.trim(),
        'foto_path': fotoSalvaPath,
        'latitude': saidaLatitude,
        'longitude': saidaLongitude,
        'entrada_latitude': entradaLatitude,
        'entrada_longitude': entradaLongitude,
        'saida_latitude': saidaLatitude,
        'saida_longitude': saidaLongitude,
      }),
    );

    observacoesController.clear();
    tubitosController.clear();

    setState(() {
      fotoTemporariaPath = null;
      focoPositivo = false;
      entradaEm = null;
      entradaLatitude = null;
      entradaLongitude = null;
      visitaIniciada = false;
      finalizacaoAberta = false;
      situacaoSelecionada = 'Visitado';
    });

    await carregarDados();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Visita registrada com sucesso.')),
    );
  }

  Future<void> sincronizarVisitaPE(Map<String, dynamic> visita) async {
    final id = visita['id'] as int?;
    if (id == null) return;

    try {
      final sync = await SyncService.configurado();
      await sync.enviarVisitaPE(visita);
      await DatabaseHelper.instance.marcarSincronizado(
        tabela: 'visitas_pe',
        id: id,
        sincronizadoEm: DateTime.now().toIso8601String(),
      );
    } catch (error) {
      await DatabaseHelper.instance.marcarErroSincronizacao(
        tabela: 'visitas_pe',
        id: id,
        erro: error.toString(),
      );
      debugPrint('Visita PE salva offline. Sincronizacao pendente: $error');
    }
  }

  void abrirFotoSalva(String fotoPath) {
    if (fotoPath.isEmpty || !File(fotoPath).existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto não encontrada no aparelho.')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _FotoVisitaPage(fotoPath: fotoPath),
      ),
    );
  }

  Widget construirResumoPE() {
    final cicloPE = EpidemiologicalCalendar.cicloPEAtual();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.nome,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(widget.endereco, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: AppSpacing.md),
          _InfoLinha(
            icon: Icons.location_city,
            text: config['municipio'] ?? 'Município não informado',
          ),
          _InfoLinha(
            icon: Icons.person,
            text: config['agente'] ?? 'Agente não informado',
          ),
          _InfoLinha(
            icon: Icons.my_location,
            text: 'GPS do PE preparado para próxima fase',
          ),
          if (cicloPE != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _InfoLinha(
              icon: Icons.calendar_month,
              text: '${cicloPE.titulo}: ${cicloPE.periodo}',
            ),
          ],
        ],
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
          capturandoGPS ? 'Capturando GPS...' : 'Iniciar Visita',
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
            const Row(
              children: [
                Icon(Icons.timer, color: AppColors.primary),
                SizedBox(width: AppSpacing.sm),
                Text(
                  'Visita em andamento',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
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
                'Finalizar Visita',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget construirFormularioFinalizacao() {
    if (!finalizacaoAberta) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Finalização da visita',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.lg),
            DropdownButtonFormField<String>(
              initialValue: situacaoSelecionada,
              decoration: const InputDecoration(
                labelText: 'Situação da visita',
              ),
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
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: observacoesController,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Observações'),
            ),
            const SizedBox(height: AppSpacing.lg),
            construirFocoPositivo(),
            const SizedBox(height: AppSpacing.lg),
            construirFotoObrigatoria(),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 60),
              ),
              onPressed: registrarVisita,
              icon: const Icon(Icons.assignment_turned_in),
              label: const Text(
                'Salvar e Finalizar Visita',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget construirFotoObrigatoria() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedButton.icon(
          onPressed: tirarFoto,
          icon: const Icon(Icons.photo_camera),
          label: Text(
            fotoTemporariaPath == null
                ? 'Tirar foto obrigatória'
                : 'Trocar foto',
          ),
        ),
        if (fotoTemporariaPath != null) ...[
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            child: Image.file(
              File(fotoTemporariaPath!),
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ],
    );
  }

  Widget construirFocoPositivo() {
    return Column(
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Foco positivo encontrado'),
          subtitle: const Text('Exige quantidade de tubitos coletados.'),
          value: focoPositivo,
          activeThumbColor: AppColors.atrasado,
          onChanged: (value) {
            setState(() {
              focoPositivo = value;

              if (!focoPositivo) {
                tubitosController.clear();
              }
            });
          },
        ),
        if (focoPositivo) ...[
          const SizedBox(height: AppSpacing.sm),
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
              _previewTubitos(),
              style: const TextStyle(color: AppColors.textMuted),
            ),
          ),
        ],
      ],
    );
  }

  String _previewTubitos() {
    final quantidade = int.tryParse(tubitosController.text.trim()) ?? 0;

    if (quantidade <= 0) {
      return 'Último tubito registrado: $ultimoTubitoGlobal. A próxima numeração será gerada automaticamente.';
    }

    final numeros = List.generate(
      quantidade,
      (index) => (ultimoTubitoGlobal + index + 1).toString(),
    );

    return 'Tubitos: ${numeros.join(', ')}';
  }

  Widget construirHistorico() {
    if (visitas.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Text('Nenhuma visita registrada ainda.'),
        ),
      );
    }

    return Column(
      children: visitas.map((visita) {
        final tubitos = visita.tubitos.join(', ');
        final temFoto =
            visita.fotoPath.isNotEmpty && File(visita.fotoPath).existsSync();

        return Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border(
              left: BorderSide(
                color: AppColors.emDia,
                width: 5,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.emDia,
                    child: const Icon(Icons.check, color: Colors.white),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          visita.situacao,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
                      ],
                    ),
                  ),
                  if (temFoto)
                    IconButton(
                      tooltip: 'Ver foto',
                      onPressed: () => abrirFotoSalva(visita.fotoPath),
                      icon: const Icon(
                        Icons.photo_camera,
                        color: AppColors.primary,
                      ),
                    ),
                  if (visita.focoPositivo)
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.atrasado.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.warning_amber,
                        color: AppColors.atrasado,
                        size: 22,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _HistoricoLinha(icon: Icons.login, texto: visita.entradaEm),
              _HistoricoLinha(icon: Icons.logout, texto: visita.saidaEm),
              _HistoricoLinha(
                icon: Icons.person,
                texto: visita.agente.isEmpty
                    ? 'ACE não informado'
                    : visita.agente,
              ),
              _HistoricoLinha(
                icon: Icons.location_city,
                texto: visita.municipio.isEmpty
                    ? 'Município não informado'
                    : visita.municipio,
              ),
              _HistoricoLinha(
                icon: Icons.my_location,
                texto:
                    'Entrada GPS: ${visita.entradaLatitude?.toStringAsFixed(6) ?? '-'}, ${visita.entradaLongitude?.toStringAsFixed(6) ?? '-'}',
              ),
              _HistoricoLinha(
                icon: Icons.pin_drop,
                texto:
                    'Saída GPS: ${visita.saidaLatitude?.toStringAsFixed(6) ?? visita.latitude?.toStringAsFixed(6) ?? '-'}, ${visita.saidaLongitude?.toStringAsFixed(6) ?? visita.longitude?.toStringAsFixed(6) ?? '-'}',
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  _HistoricoChip(
                    icon: Icons.science,
                    texto: visita.focoPositivo
                        ? 'Foco positivo'
                        : 'Sem foco positivo',
                    color: visita.focoPositivo
                        ? AppColors.atrasado
                        : AppColors.emDia,
                  ),
                  if (visita.focoPositivo)
                    _HistoricoChip(
                      icon: Icons.numbers,
                      texto: tubitos.isEmpty ? 'Tubitos não listados' : tubitos,
                      color: AppColors.primary,
                    ),
                  _HistoricoChip(
                    icon: temFoto ? Icons.photo_camera : Icons.no_photography,
                    texto: temFoto ? 'Foto registrada' : 'Foto indisponível',
                    color: temFoto ? AppColors.primary : AppColors.textMuted,
                  ),
                ],
              ),
              if (visita.observacoes.trim().isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  visita.observacoes,
                  style: const TextStyle(color: AppColors.textStrong),
                ),
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
      appBar: AppBar(title: Text(widget.nome)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          construirResumoPE(),
          const SizedBox(height: AppSpacing.xl),
          construirControleVisita(),
          const SizedBox(height: AppSpacing.lg),
          construirFormularioFinalizacao(),
          const SizedBox(height: 28),
          const Text(
            'Histórico de visitas',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.md),
          construirHistorico(),
        ],
      ),
    );
  }
}

class _InfoLinha extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoLinha({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.white70),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoricoLinha extends StatelessWidget {
  final IconData icon;
  final String texto;

  const _HistoricoLinha({required this.icon, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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

class _HistoricoChip extends StatelessWidget {
  final IconData icon;
  final String texto;
  final Color color;

  const _HistoricoChip({
    required this.icon,
    required this.texto,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 6),
          Text(
            texto,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _FotoVisitaPage extends StatelessWidget {
  final String fotoPath;

  const _FotoVisitaPage({required this.fotoPath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Foto da visita')),
      backgroundColor: Colors.black,
      body: Center(
        child: InteractiveViewer(
          child: Image.file(File(fotoPath), fit: BoxFit.contain),
        ),
      ),
    );
  }
}
