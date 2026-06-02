# Andrade Demo Unificada

Demo mobile Flutter da Plataforma Municipal de Saúde, reunindo uma entrada única com identidade Andrade Gestão em Saúde e acesso por perfil aos módulos permitidos.

## Credenciais

Usuários simulados do painel:

- Login: `Alexk`, `Barbara` ou `Gilyan`
- Senha: `1234`
- Perfil: `MOTORISTA`
- Módulo: `Logística`

GOD MODE:

- Login: `GODMODE`
- Senha: `app2026`
- Biometria: opcional, quando o aparelho permitir.

## Módulos

- **Logística**: reaproveita a cópia local do módulo Logística em `modules/logistica`.
- **ACE**: reaproveita a cópia local do app ACE em `modules/ace`.

Os fluxos internos foram preservados. A identidade Andrade foi aplicada na entrada, nos wrappers visíveis e nos tokens visuais dos módulos copiados.

## Autenticação por Perfil

O app não pede mais Motorista, Município e Senha dentro do módulo Logística. O usuário entra pela tela institucional única, e os dados de nome, município, perfil e permissões são carregados do cadastro do painel web.

Motoristas entram direto na área Logística do motorista. A seleção de módulos só aparece para usuários com mais de um módulo autorizado.

## Animações

Os vídeos MP4 usados na abertura e no GOD MODE ficam em:

- `assets/animations/app_intro.mp4`
- `assets/animations/god_mode_activation.mp4`

O app exibe a animação inicial antes do login. No GOD MODE, a animação só é aberta após validar login, senha e, se marcada, biometria.

## Minhas Viagens

A tela **Minhas viagens** mostra apenas viagens atribuídas ao motorista pela plataforma. Quando não houver viagem recebida do painel, o comportamento esperado é exibir:

`Nenhuma viagem atribuída`

O app não cria viagens falsas automaticamente em produção.

## Homologação da Etapa 2

Para testar o fluxo operacional antes da plataforma enviar viagens reais, existe um seed opcional de homologação. Ele fica desligado por padrão:

```dart
DEMO_SEED_ENABLED = false
```

Para ativar os dados locais de teste, execute o app com:

```powershell
C:\flutter\bin\flutter.bat run --dart-define=DEMO_SEED_ENABLED=true
```

O seed cria motorista `Alex` com id `motorista-local`, 2 veículos, 3 viagens, passageiros, acompanhantes e casos de acessibilidade. Para produção, não use esse `dart-define`.

## Como Rodar Após Clonar

```powershell
git clone https://github.com/kichalex33-ops/plataforma-app.git
cd plataforma-app
C:\flutter\bin\flutter.bat pub get
C:\flutter\bin\flutter.bat run
```

## Comandos de Validação

```powershell
C:\flutter\bin\flutter.bat pub get
C:\flutter\bin\dart.bat analyze --no-fatal-warnings
C:\flutter\bin\flutter.bat test
C:\flutter\bin\flutter.bat build apk --debug
```

## Documentação

- `docs/RELATORIO_DEMO_UNIFICADA.md`
- `docs/PLANO_MELHORIAS_DEMO.md`
- `docs/IDENTIDADE_VISUAL_ANDRADE.md`
- `docs/AUTENTICACAO_E_PERFIS.md`
- `docs/ANIMATIONS.md`
- `docs/GOD_MODE.md`
- `docs/ESCOPO_LOGISTICA_MVP.md`
- `docs/ROADMAP_LOGISTICA_3_MESES.md`
- `docs/MAQUINA_ESTADOS_VIAGEM.md`
- `docs/PLANO_DADOS_LOGISTICA.md`
- `docs/HOMOLOGACAO_ETAPA_2.md`
- `docs/logistica/`
- `docs/v2/`
