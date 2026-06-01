# Andrade Demo Unificada

Demo mobile Flutter da Plataforma Municipal de Saude, reunindo uma entrada unica com identidade Andrade Gestao em Saude e acesso aos modulos preservados de Logistica e ACE Territorial.

## Credenciais

- Login: `Alex`
- Senha: `1234`

## Modulos

- **Logistica**: reaproveita a copia local do app LogiSaude em `modules/logistica`.
- **ACE Territorial**: reaproveita a copia local do app ACE em `modules/ace`.

Os layouts internos dos modulos foram preservados. A identidade visual padrao foi aplicada por tokens de cor nas copias locais dos modulos.

## Como rodar

```powershell
cd "C:\dev\plataforma\app\plataforma teste"
C:\flutter\bin\flutter.bat pub get
C:\flutter\bin\dart.bat analyze --no-fatal-warnings
C:\flutter\bin\flutter.bat run
```

## Validacao

```powershell
C:\flutter\bin\flutter.bat pub get
C:\flutter\bin\dart.bat analyze --no-fatal-warnings
C:\flutter\bin\flutter.bat test
```

## Documentacao

Veja o relatorio em `docs/RELATORIO_DEMO_UNIFICADA.md`.
