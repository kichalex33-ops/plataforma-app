# Andrade Demo Unificada

Demo mobile Flutter da Plataforma Municipal de Saúde, reunindo uma entrada única com identidade Andrade Gestão em Saúde e acesso aos módulos preservados de Logística e ACE.

## Credenciais

- Login: `Alex`
- Senha: `1234`

## Módulos

- **Logística**: reaproveita a cópia local do app LogiSaúde em `modules/logistica`.
- **ACE**: reaproveita a cópia local do app ACE em `modules/ace`.

Os layouts internos dos módulos foram preservados. A identidade visual padrão foi aplicada por tokens de cor nas cópias locais dos módulos.

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
