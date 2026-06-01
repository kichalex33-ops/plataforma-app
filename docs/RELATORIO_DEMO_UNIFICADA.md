# Relatório da Demo Unificada

## Objetivo

Foi criada uma demo mobile isolada em `C:\dev\plataforma\app\plataforma teste`, sem alterar os projetos originais `logisaude` e `APP_LOGISTICA_MUNICIPAL_ENTREGA`.

## Arquivos criados na demo

- `lib/main.dart`
- `lib/screens/login_demo_page.dart`
- `lib/screens/module_selector_page.dart`
- `lib/modules/logistica/logistica_module_page.dart`
- `lib/modules/ace/ace_module_page.dart`
- `docs/RELATORIO_DEMO_UNIFICADA.md`
- `docs/PLANO_MELHORIAS_DEMO.md`

## Arquivos copiados

Para aplicar a identidade visual padrão sem alterar os projetos originais, os dois apps foram copiados para dentro da demo:

- `modules/logistica`: cópia local de `C:\dev\plataforma\app\logisaude`
- `modules/ace`: cópia local de `C:\dev\plataforma\app\APP_LOGISTICA_MUNICIPAL_ENTREGA`

Foram excluídos da cópia apenas artefatos gerados como `.dart_tool`, `build` e arquivos de lock/plugins gerados.

## Apps reaproveitados

- `modules/logistica`: usado como dependência local `logisaude_driver`.
- `modules/ace`: usado como dependência local `controle_ace`.

## Adaptações mínimas

- Criada tela inicial institucional com identidade Andrade Gestão em Saúde.
- Criado login local da demo com `Alex / 1234`.
- Criada tela simples de seleção com os módulos `Logística` e `ACE`.
- Criado wrapper `LogisticaModulePage` para inicializar banco/tema do LogiSaúde e abrir o app original sem o login interno.
- Criado wrapper `AceModulePage` para inicializar banco do ACE e abrir telas originais em uma casca mínima de navegação.
- Aplicada a paleta visual Andrade nas cópias locais dos módulos, alterando apenas tokens de cor em:
  - `modules/logistica/lib/core/theme/app_colors.dart`
  - `modules/ace/lib/core/theme/app_colors.dart`

## Layouts preservados

- O layout interno do LogiSaúde foi preservado; somente a paleta da cópia local foi ajustada.
- As telas internas do ACE (`PE`, `Visitas`, `Quarteirões`, `Mapa`, `BTI`, `Ovitrampas`, `LIRA/LIA`, `Relatórios` e outras) foram preservadas; somente a paleta da cópia local foi ajustada.
- A identidade Andrade foi aplicada apenas no login e na seleção de módulos da demo.

## Observações

O app `APP_LOGISTICA_MUNICIPAL_ENTREGA` possui várias telas ACE, mas não expõe um shell ACE único e pronto como widget público. Por isso, a demo cria apenas uma casca mínima para abrir essas telas originais sem alterar o código delas.

## Como rodar

```powershell
cd "C:\dev\plataforma\app\plataforma teste"
C:\flutter\bin\flutter.bat pub get
C:\flutter\bin\dart.bat analyze --no-fatal-warnings
C:\flutter\bin\flutter.bat run
```

## Validação executada

```powershell
C:\flutter\bin\flutter.bat pub get
C:\flutter\bin\dart.bat analyze --no-fatal-warnings
C:\flutter\bin\flutter.bat test
C:\flutter\bin\flutter.bat build apk --debug
```

Resultado:

- `pub get`: concluído usando dependências locais `modules/logistica` e `modules/ace`.
- `dart analyze --no-fatal-warnings`: sem issues.
- `flutter test`: teste da tela de login passou.
- `flutter build apk --debug`: APK gerado em `build/app/outputs/flutter-apk/app-debug.apk`.
- Cópia para teste local: `AndradeDemoUnificada-debug.apk`.

## Credenciais

- Login: `Alex`
- Senha: `1234`
