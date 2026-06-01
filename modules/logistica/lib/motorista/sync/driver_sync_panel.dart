import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../widgets/status_badge.dart';
import 'driver_sync_service.dart';

class DriverSyncPanel extends StatefulWidget {
  final ValueChanged<DriverSyncStatus>? onStatusChanged;

  const DriverSyncPanel({super.key, this.onStatusChanged});

  @override
  State<DriverSyncPanel> createState() => _DriverSyncPanelState();
}

class _DriverSyncPanelState extends State<DriverSyncPanel> {
  final _syncService = DriverSyncService();
  DriverSyncStatus _status = const DriverSyncStatus(online: false);
  bool _processando = false;

  @override
  void initState() {
    super.initState();
    _carregarStatusSalvo();
  }

  Future<void> _carregarStatusSalvo() async {
    try {
      final status = await _syncService.carregarStatusSalvo();
      if (!mounted) return;
      setState(() => _status = status);
      widget.onStatusChanged?.call(status);
    } catch (_) {
      // Falha local nao deve travar a tela.
    }
  }

  Future<void> _testarConexao() async {
    if (_processando) return;
    setState(() => _processando = true);
    try {
      final status = await _syncService.testarConexao();
      if (!mounted) return;
      setState(() => _status = status);
      widget.onStatusChanged?.call(status);
      _mostrarSnack(status.mensagem ?? status.resumoSync);
    } finally {
      if (mounted) setState(() => _processando = false);
    }
  }

  Future<void> _sincronizarAgora() async {
    if (_processando) return;
    setState(() => _processando = true);
    try {
      final status = await _syncService.sincronizarAgora();
      if (!mounted) return;
      setState(() => _status = status);
      widget.onStatusChanged?.call(status);
      _mostrarSnack(status.mensagem ?? status.resumoSync);
    } finally {
      if (mounted) setState(() => _processando = false);
    }
  }

  void _mostrarSnack(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            StatusBadge(label: _status.rotuloConexao),
            Chip(label: Text('Enviados: ${_status.enviados}')),
            Chip(label: Text('Falhas: ${_status.falhas}')),
            if (_status.ultimoSync?.isNotEmpty == true)
              Chip(label: Text('Ultimo sync: ${_status.ultimoSync}')),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton.icon(
          onPressed: _processando ? null : _testarConexao,
          icon: const Icon(Icons.wifi_tethering),
          label: const Text('Testar conexao'),
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          onPressed: _processando ? null : _sincronizarAgora,
          icon: _processando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.cloud_sync),
          label: Text(_processando ? 'Sincronizando...' : 'Sincronizar agora'),
        ),
        if (_status.mensagem?.isNotEmpty == true) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            _status.mensagem!,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }
}
