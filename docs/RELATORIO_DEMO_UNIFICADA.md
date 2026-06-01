# Relatorio da Demo Unificada

## Objetivo

Foi criada uma demo mobile isolada em `C:\dev\plataforma\app\plataforma teste`, sem alterar os projetos originais `logisaude` e `APP_LOGISTICA_MUNICIPAL_ENTREGA`.

## Arquivos criados na demo

- `lib/main.dart`
- `lib/screens/login_demo_page.dart`
- `lib/screens/module_selector_page.dart`
- `lib/modules/logistica/logistica_module_page.dart`
- `lib/modules/ace/ace_module_page.dart`
- `docs/RELATORIO_DEMO_UNIFICADA.md`

## Arquivos copiados

Para aplicar a identidade visual padrao sem alterar os projetos originais, os dois apps foram copiados para dentro da demo:

- `modules/logistica`: copia local de `C:\dev\plataforma\app\logisaude`
- `modules/ace`: copia local de `C:\dev\plataforma\app\APP_LOGISTICA_MUNICIPAL_ENTREGA`

Foram excluidos da copia apenas artefatos gerados como `.dart_tool`, `build` e arquivos de lock/plugins gerados.

## Apps reaproveitados

- `modules/logistica`: usado como dependencia local `logisaude_driver`.
- `modules/ace`: usado como dependencia local `controle_ace`.

## Adaptacoes minimas

- Criada tela inicial institucional com identidade Andrade Gestao em Saude.
- Criado login local da demo com `Alex / 1234`.
- Criada tela simples de selecao com os modulos `Logistica` e `ACE Territorial`.
- Criado wrapper `LogisticaModulePage` para inicializar banco/tema do LogiSaude e abrir o app original sem o login interno.
- Criado wrapper `AceModulePage` para inicializar banco do ACE e abrir telas originais em uma casca minima de navegacao.
- Aplicada a paleta visual Andrade nas copias locais dos modulos, alterando apenas tokens de cor em:
  - `modules/logistica/lib/core/theme/app_colors.dart`
  - `modules/ace/lib/core/theme/app_colors.dart`

## Layouts preservados

- O layout interno do LogiSaude foi preservado; somente a paleta da copia local foi ajustada.
- As telas internas do ACE Territorial (`PE`, `Visitas`, `Quarteiroes`, `Mapa`, `BTI`, `Ovitrampas`, `LIRA/LIA`, `Relatorios` e outras) foram preservadas; somente a paleta da copia local foi ajustada.
- A identidade Andrade foi aplicada apenas no login e na selecao de modulos da demo.

## Observacoes

O app `APP_LOGISTICA_MUNICIPAL_ENTREGA` possui varias telas ACE, mas nao expoe um shell ACE unico e pronto como widget publico. Por isso, a demo cria apenas uma casca minima para abrir essas telas originais sem alterar o codigo delas.

## Como rodar

```powershell
cd "C:\dev\plataforma\app\plataforma teste"
C:\flutter\bin\flutter.bat pub get
C:\flutter\bin\dart.bat analyze --no-fatal-warnings
C:\flutter\bin\flutter.bat run
```

## Validacao executada

```powershell
C:\flutter\bin\flutter.bat pub get
C:\flutter\bin\dart.bat analyze --no-fatal-warnings
C:\flutter\bin\flutter.bat test
```

Resultado:

- `pub get`: concluido usando dependencias locais `modules/logistica` e `modules/ace`.
- `dart analyze --no-fatal-warnings`: sem issues.
- `flutter test`: teste da tela de login passou.
- Preview web atualizado aberto em `http://127.0.0.1:5188`.

## Credenciais

- Login: `Alex`
- Senha: `1234`
