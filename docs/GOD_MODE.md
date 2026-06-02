# GOD MODE

## Objetivo

Criar uma entrada administrativa especial para demonstração avançada, com validação de credenciais, biometria opcional e animação de ativação.

## Credenciais Locais

- Login: `GODMODE`
- Senha: `app2026`

Essas credenciais são locais e servem apenas para demo. Em produção, o acesso deve vir do painel administrativo e de uma API segura.

## Fluxo Atual

1. Usuário informa login e senha na tela de login.
2. O app valida as credenciais no `GodModeAuthService`.
3. Se a opção de biometria estiver marcada, o app solicita validação nativa.
4. Após autorização, o app abre `GodModeActivationScreen`.
5. A animação MP4 é executada.
6. Ao finalizar, o app abre `GodModeDashboard`.

## Arquivos

- `lib/core/god_mode/god_mode_auth_service.dart`
- `lib/screens/god_mode_activation_screen.dart`
- `lib/screens/god_mode_dashboard.dart`
- `assets/animations/god_mode_activation.mp4`

## Segurança Atual

- Validação local de login e senha.
- Biometria opcional via `local_auth`.
- O painel GOD MODE exige `AppAccessMode.godMode`.

## Limitações

- Não existe autenticação real com backend.
- Não existe JWT, refresh token ou sessão criptografada.
- Não existe RBAC real para permissões finas.
- Não existe trilha de auditoria em servidor.

## Regras Para Evolução

- GOD MODE futuro deve depender de autenticação real.
- Permissões devem vir do painel administrativo.
- Ativações devem gerar auditoria.
- A senha local deve ser removida em build de produção.
