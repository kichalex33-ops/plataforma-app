# Autenticação e Perfis

## Objetivo

O app possui uma única tela principal de login. O usuário é cadastrado previamente no painel web pelo operador ou controlador logístico, e o aplicativo apenas valida o acesso e aplica as permissões recebidas.

## Cadastro no Painel Web

O cadastro futuro do painel deve registrar:

- nome completo;
- login;
- senha inicial gerada;
- município;
- função;
- perfil;
- permissões;
- módulo permitido;
- status ativo ou inativo.

## Login Normal

Campos exibidos no app:

- Login;
- Senha;
- Entrar usando biometria.

Campos removidos do fluxo normal:

- Motorista;
- Município;
- seleção manual obrigatória de módulo.

O nome, município e função são carregados do cadastro do painel. Na demo atual, esse backend está representado por `PanelAuthService`, que simula usuários cadastrados.

## Roteamento por Perfil

Após login válido:

- `MOTORISTA`: abre diretamente a área Logística do motorista.
- `OPERADOR_LOGISTICA`: abre a área operacional permitida.
- Perfis futuros devem ser liberados apenas quando seus módulos forem incluidos no app.
- Usuário sem permissão ativa: exibe `Usuário sem permissão ativa. Procure o operador responsável.`

A tela de seleção de módulos só aparece quando o usuário tem mais de um módulo autorizado.

## Senha

A senha inicial é criada ou gerada no painel web. No primeiro acesso, o app oferece alteração de senha pela tela `AlterarSenhaScreen`.

Regras:

- senha atual obrigatória;
- nova senha obrigatória;
- confirmação obrigatória;
- mínimo 6 caracteres;
- pelo menos uma letra;
- pelo menos um número;
- senha antiga invalidada no serviço de autenticação.

## Biometria e Segurança do Aparelho

A segurança do aparelho só pode ser vinculada após login válido com login e senha.

Fluxo:

1. Usuário entra com login e senha.
2. App pergunta se deseja ativar segurança do aparelho.
3. Se aceitar, o app chama autenticação local.
4. Nos próximos acessos, o usuário pode desbloquear a sessão vinculada.

A biometria não cria usuário e não substitui o cadastro do painel. Ela apenas desbloqueia localmente um usuário já autorizado.

## GOD MODE

O GOD MODE permanece separado. Ele passa obrigatoriamente por `validateGodModeAccess()`, executa a animação e abre o painel GOD MODE.

O GOD MODE ignora limitações normais de perfil e libera acesso total ao módulo ativo, ferramentas avançadas e auditoria interna preparada.

## Limitações Atuais

- O backend real ainda não está conectado.
- `PanelAuthService` é um contrato/mock local para demonstrar o fluxo.
- Alteração de senha é simulada no serviço local.
- A base permanece modular para novas entradas futuras, mas o app atual mantém somente Logística ativa.
