# GOD MODE

## Objetivo

O GOD MODE e uma entrada tecnica separada para testes internos, auditoria avancada e ferramentas de desenvolvimento. Ele nao faz parte do fluxo operacional do motorista.

## Regras de seguranca

- O GOD MODE fica bloqueado por padrao.
- Em producao (`APP_ENV=producao`) o GOD MODE fica sempre indisponivel.
- Nao existe senha fixa de GOD MODE no codigo.
- Fora de producao, o acesso so pode ser habilitado por build controlado:

```bash
--dart-define=GOD_MODE_ENABLED=true
--dart-define=GOD_MODE_PASSWORD=<senha-temporaria>
```

## Fluxo Atual

1. Usuario informa `GODMODE` na tela principal de login.
2. `GodModeAuthService` valida se o ambiente permite GOD MODE.
3. O servico valida a senha temporaria recebida por `dart-define`.
4. Se a opcao de biometria for exigida, o app solicita validacao nativa.
5. Apos autorizacao, o app abre `GodModeActivationScreen`.
6. A animacao MP4 e executada.
7. Ao finalizar, o app abre `GodModeDashboard`.

## Arquivos

- `lib/core/god_mode/god_mode_auth_service.dart`
- `lib/screens/god_mode_activation_screen.dart`
- `lib/screens/god_mode_dashboard.dart`
- `assets/animations/god_mode_activation.mp4`

## Limitacoes

- O GOD MODE ainda nao consulta permissao remota.
- O acesso de producao esta bloqueado ate existir autorizacao forte pelo backend.
- Ativacoes devem continuar gerando auditoria local e, futuramente, auditoria no servidor.
