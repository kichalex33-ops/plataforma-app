# Andrade Demo Unificada

Demo mobile Flutter da Plataforma Municipal de Saúde, reunindo uma entrada única com identidade Andrade Gestão em Saúde e acesso aos módulos preservados de Logística e ACE.

## Credenciais

Demo normal:

- Login: `Alex`
- Senha: `1234`

God Mode:

- Login: `Alexkich`
- Senha: `@l3xk1cH`

## Módulos

- **Logística**: reaproveita a cópia local do app LogiSaúde em `modules/logistica`.
- **ACE**: reaproveita a cópia local do app ACE em `modules/ace`.

Os fluxos internos foram preservados. A identidade Andrade foi aplicada na entrada, seleção de módulos, wrappers visíveis e tokens visuais dos módulos copiados.

## Como rodar após clonar o repositório

```powershell
git clone https://github.com/kichalex33-ops/plataforma-app.git
cd plataforma-app
C:\flutter\bin\flutter.bat pub get
C:\flutter\bin\flutter.bat run
```

## Comandos de validação

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
- `docs/ESCOPO_LOGISTICA_MVP.md`
- `docs/ROADMAP_LOGISTICA_3_MESES.md`
- `docs/MAQUINA_ESTADOS_VIAGEM.md`
- `docs/PLANO_DADOS_LOGISTICA.md`
