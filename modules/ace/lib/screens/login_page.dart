import 'package:flutter/material.dart';

import '../core/app_info.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../database/database_helper.dart';
import '../models/ace_profile_model.dart';

class LoginPage extends StatefulWidget {
  final void Function(BuildContext context, String agente, String municipio)
  onEntrar;

  const LoginPage({super.key, required this.onEntrar});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final agenteController = TextEditingController();
  final municipioController = TextEditingController();
  final senhaController = TextEditingController();

  bool ocultarSenha = true;
  bool modoCriarConta = false;
  bool processando = false;
  int? perfilSelecionadoId;
  List<ACEProfileModel> perfis = [];

  @override
  void initState() {
    super.initState();
    carregarDados();
  }

  Future<void> carregarDados() async {
    try {
      final config = await DatabaseHelper.instance.carregarConfiguracao();
      final lista = (await DatabaseHelper.instance.listarPerfisACE())
          .where((perfil) => perfil.id != null)
          .toList();

      if (!mounted) return;

      setState(() {
        perfis = lista;
        municipioController.text = config['municipio'] ?? '';
        agenteController.text = config['agente'] ?? '';
        modoCriarConta = lista.isEmpty;

        if (lista.isNotEmpty) {
          final existeSelecionado = lista.any(
            (perfil) => perfil.id == perfilSelecionadoId,
          );
          final selecionado = existeSelecionado
              ? lista.firstWhere((perfil) => perfil.id == perfilSelecionadoId)
              : lista.first;

          perfilSelecionadoId = selecionado.id;
          agenteController.text = selecionado.nome;
          municipioController.text = selecionado.municipio;
        }
      });
    } catch (error) {
      if (!mounted) return;
      mostrarMensagem('Erro ao carregar perfis: $error');
      setState(() => modoCriarConta = true);
    }
  }

  @override
  void dispose() {
    agenteController.dispose();
    municipioController.dispose();
    senhaController.dispose();
    super.dispose();
  }

  Future<void> criarConta() async {
    if (processando) return;

    final agente = agenteController.text.trim();
    final municipio = municipioController.text.trim();
    final senha = senhaController.text.trim();

    if (agente.isEmpty || municipio.isEmpty || senha.isEmpty) {
      mostrarMensagem('Informe operador, municipio e senha.');
      return;
    }

    setState(() => processando = true);

    try {
      final criadoEm = DateTime.now().toIso8601String();
      final perfil = ACEProfileModel(
        nome: agente,
        municipio: municipio,
        senha: senha,
        createdAt: criadoEm,
      );

      final id = await DatabaseHelper.instance
          .inserirPerfilACE(perfil)
          .timeout(const Duration(seconds: 12));

      if (id <= 0) {
        mostrarMensagem('Nao foi possivel salvar o perfil.');
        return;
      }

      await DatabaseHelper.instance
          .salvarConfiguracao(municipio: municipio, agente: agente)
          .timeout(const Duration(seconds: 12));

      if (!mounted) return;

      setState(() {
        perfilSelecionadoId = id;
        perfis = [
          ...perfis,
          ACEProfileModel(
            id: id,
            nome: agente,
            municipio: municipio,
            senha: senha,
            createdAt: criadoEm,
          ),
        ];
      });

      widget.onEntrar(context, agente, municipio);
    } catch (error) {
      if (!mounted) return;
      mostrarMensagem('Erro ao criar perfil: $error');
    } finally {
      if (mounted) setState(() => processando = false);
    }
  }

  Future<void> entrar() async {
    if (processando) return;

    if (modoCriarConta) {
      await criarConta();
      return;
    }

    final senha = senhaController.text.trim();
    ACEProfileModel? perfil;

    for (final item in perfis) {
      if (item.id == perfilSelecionadoId) {
        perfil = item;
        break;
      }
    }

    if (perfil == null) {
      mostrarMensagem('Selecione um perfil ou crie uma conta.');
      return;
    }

    if (senha.isEmpty) {
      mostrarMensagem('Informe a senha.');
      return;
    }

    if (senha != perfil.senha) {
      mostrarMensagem('Senha incorreta para este perfil.');
      return;
    }

    setState(() => processando = true);

    try {
      await DatabaseHelper.instance.salvarConfiguracao(
        municipio: perfil.municipio,
        agente: perfil.nome,
      );

      if (!mounted) return;

      widget.onEntrar(context, perfil.nome, perfil.municipio);
    } catch (error) {
      if (!mounted) return;
      mostrarMensagem('Erro ao entrar: $error');
    } finally {
      if (mounted) setState(() => processando = false);
    }
  }

  void mostrarMensagem(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  ACEProfileModel? perfilSelecionado() {
    for (final perfil in perfis) {
      if (perfil.id == perfilSelecionadoId) return perfil;
    }
    return null;
  }

  Future<void> editarPerfilSelecionado() async {
    final perfil = perfilSelecionado();
    final id = perfil?.id;
    if (perfil == null || id == null) return;

    final nomeController = TextEditingController(text: perfil.nome);
    final municipioEdicaoController = TextEditingController(
      text: perfil.municipio,
    );

    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar perfil'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: municipioEdicaoController,
                decoration: const InputDecoration(labelText: 'Municipio'),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: nomeController,
                decoration: const InputDecoration(labelText: 'Operador'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );

    if (confirmou != true) return;

    final nome = nomeController.text.trim();
    final municipio = municipioEdicaoController.text.trim();

    if (nome.isEmpty || municipio.isEmpty) {
      mostrarMensagem('Informe municipio e operador.');
      return;
    }

    await DatabaseHelper.instance.atualizarPerfilACE(
      ACEProfileModel(
        id: id,
        nome: nome,
        municipio: municipio,
        senha: perfil.senha,
        createdAt: perfil.createdAt,
      ),
    );

    await carregarDados();
    if (!mounted) return;
    mostrarMensagem('Perfil atualizado.');
  }

  Future<void> trocarSenhaPerfilSelecionado() async {
    final perfil = perfilSelecionado();
    final id = perfil?.id;
    if (perfil == null || id == null) return;

    final senhaAtualController = TextEditingController();
    final novaSenhaController = TextEditingController();

    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Trocar senha'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: senhaAtualController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Senha atual'),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: novaSenhaController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Nova senha'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Alterar'),
            ),
          ],
        );
      },
    );

    if (confirmou != true) return;

    final senhaAtual = senhaAtualController.text.trim();
    final novaSenha = novaSenhaController.text.trim();

    if (senhaAtual != perfil.senha) {
      mostrarMensagem('Senha atual incorreta.');
      return;
    }

    if (novaSenha.isEmpty) {
      mostrarMensagem('Informe a nova senha.');
      return;
    }

    await DatabaseHelper.instance.atualizarSenhaPerfilACE(
      id: id,
      senha: novaSenha,
    );

    senhaController.clear();
    await carregarDados();
    if (!mounted) return;
    mostrarMensagem('Senha alterada.');
  }

  Future<void> redefinirSenhaEsquecida() async {
    final perfil = perfilSelecionado();
    final id = perfil?.id;
    if (perfil == null || id == null) {
      mostrarMensagem('Selecione um perfil para redefinir a senha.');
      return;
    }

    final novaSenhaController = TextEditingController();
    final confirmarSenhaController = TextEditingController();

    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Esqueci a senha'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Redefinir a senha local de ${perfil.nome}.'),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: novaSenhaController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Nova senha'),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: confirmarSenhaController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirmar nova senha',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Redefinir'),
            ),
          ],
        );
      },
    );

    if (confirmou != true) {
      novaSenhaController.dispose();
      confirmarSenhaController.dispose();
      return;
    }

    final novaSenha = novaSenhaController.text.trim();
    final confirmarSenha = confirmarSenhaController.text.trim();

    novaSenhaController.dispose();
    confirmarSenhaController.dispose();

    if (novaSenha.length < 4) {
      mostrarMensagem('Use uma senha com pelo menos 4 caracteres.');
      return;
    }

    if (novaSenha != confirmarSenha) {
      mostrarMensagem('As senhas nao conferem.');
      return;
    }

    await DatabaseHelper.instance.atualizarSenhaPerfilACE(
      id: id,
      senha: novaSenha,
    );

    senhaController.clear();
    await carregarDados();
    if (!mounted) return;
    mostrarMensagem('Senha local redefinida.');
  }

  Future<void> excluirPerfilSelecionado() async {
    final perfil = perfilSelecionado();
    final id = perfil?.id;
    if (perfil == null || id == null) return;

    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Excluir usuario'),
          content: Text('Excluir o perfil local de ${perfil.nome}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.atrasado,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (confirmou != true) return;

    await DatabaseHelper.instance.excluirPerfilACE(id);

    setState(() {
      perfilSelecionadoId = null;
      senhaController.clear();
    });

    await carregarDados();
    if (!mounted) return;
    mostrarMensagem('Usuario excluido.');
  }

  Widget construirSelecaoPerfil() {
    if (perfis.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Primeiro acesso',
                style: TextStyle(
                  color: AppColors.textStrong,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'Crie o primeiro perfil local para entrar no aplicativo.',
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    modoCriarConta = true;
                    senhaController.clear();
                  });
                },
                icon: const Icon(Icons.person_add),
                label: const Text('Criar perfil'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Perfil de acesso',
          style: TextStyle(
            color: AppColors.textStrong,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...perfis.map((perfil) {
          final selecionado = perfil.id == perfilSelecionadoId;

          return Card(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: ListTile(
              selected: selecionado,
              selectedTileColor: AppColors.primaryLight,
              leading: CircleAvatar(
                backgroundColor: selecionado
                    ? AppColors.primary
                    : AppColors.primaryLight,
                child: Icon(
                  selecionado ? Icons.check : Icons.person,
                  color: selecionado ? Colors.white : AppColors.primary,
                ),
              ),
              title: Text(
                perfil.nome,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(perfil.municipio),
              trailing: selecionado
                  ? const Icon(Icons.radio_button_checked)
                  : const Icon(Icons.radio_button_unchecked),
              onTap: () {
                setState(() {
                  perfilSelecionadoId = perfil.id;
                  agenteController.text = perfil.nome;
                  municipioController.text = perfil.municipio;
                });
              },
            ),
          );
        }),
      ],
    );
  }

  Widget construirCamposCriarConta() {
    return Column(
      children: [
        TextField(
          controller: municipioController,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Município',
            prefixIcon: Icon(Icons.location_on),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          controller: agenteController,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Operador',
            prefixIcon: Icon(Icons.badge),
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget construirCampoSenha() {
    return TextField(
      controller: senhaController,
      obscureText: ocultarSenha,
      decoration: InputDecoration(
        labelText: 'Senha',
        prefixIcon: const Icon(Icons.lock),
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: Icon(ocultarSenha ? Icons.visibility : Icons.visibility_off),
          onPressed: () {
            setState(() {
              ocultarSenha = !ocultarSenha;
            });
          },
        ),
      ),
      onSubmitted: (_) => entrar(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            const SizedBox(height: AppSpacing.xxl),
            const Icon(
              Icons.local_shipping,
              size: 62,
              color: AppColors.primary,
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              AppInfo.nome,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
                height: 1.15,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Operacao logistica municipal offline',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54, fontSize: 16),
            ),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Criado por Alex Jr. Kich',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black45,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            if (modoCriarConta)
              construirCamposCriarConta()
            else
              construirSelecaoPerfil(),
            if (!modoCriarConta && perfis.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                alignment: WrapAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: editarPerfilSelecionado,
                    icon: const Icon(Icons.edit),
                    label: const Text('Editar'),
                  ),
                  OutlinedButton.icon(
                    onPressed: trocarSenhaPerfilSelecionado,
                    icon: const Icon(Icons.lock_reset),
                    label: const Text('Trocar senha'),
                  ),
                  OutlinedButton.icon(
                    onPressed: excluirPerfilSelecionado,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Excluir'),
                  ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            construirCampoSenha(),
            if (!modoCriarConta && perfis.isNotEmpty)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: redefinirSenhaEsquecida,
                  icon: const Icon(Icons.help_outline),
                  label: const Text('Esqueci a senha'),
                ),
              ),
            const SizedBox(height: AppSpacing.xxl),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
              ),
              onPressed: processando ? null : entrar,
              icon: Icon(modoCriarConta ? Icons.person_add : Icons.login),
              label: Text(
                processando
                    ? 'Aguarde...'
                    : (modoCriarConta ? 'Criar conta' : 'Entrar'),
                style: const TextStyle(fontSize: 18),
              ),
            ),
            if (perfis.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    modoCriarConta = !modoCriarConta;
                    senhaController.clear();
                  });
                },
                icon: Icon(
                  modoCriarConta ? Icons.arrow_back : Icons.person_add,
                ),
                label: Text(
                  modoCriarConta
                      ? 'Voltar para perfis salvos'
                      : 'Cadastrar outro operador',
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'Perfis locais para uso offline. A sincronizacao multiusuario sera conectada em etapa futura.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54, fontSize: 13),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Versao local ${AppInfo.versaoLocal}',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black38, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
