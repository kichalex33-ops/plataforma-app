# Homologação da Etapa 2

## Objetivo

Permitir o teste do fluxo de viagens atribuídas, preparação e check-in de saída sem depender do painel administrativo, mantendo produção sem dados falsos automáticos.

## Comportamento padrão

Por padrão, o app não cria viagens locais de teste.

```dart
DEMO_SEED_ENABLED = false
```

Quando não houver viagem atribuída ao motorista, a tela **Minhas viagens** deve mostrar:

```text
Nenhuma viagem atribuída
```

Esse é o comportamento correto para produção enquanto o painel ainda não enviar viagens ao app.

## Como ativar o seed de homologação

Para testar a Etapa 2 antes da integração com o painel, execute:

```powershell
C:\flutter\bin\flutter.bat run --dart-define=DEMO_SEED_ENABLED=true
```

Também é possível gerar um APK de homologação com:

```powershell
C:\flutter\bin\flutter.bat build apk --debug --dart-define=DEMO_SEED_ENABLED=true
```

## Dados criados em homologação

Quando `DEMO_SEED_ENABLED=true`, o app cria dados locais somente se a tabela `logistica_viagens` estiver vazia:

- Motorista `Alex` com id `motorista-local`.
- 2 veículos.
- 3 viagens.
- 8 pacientes.
- Passageiros e acompanhantes.
- Casos com acessibilidade, incluindo cadeirante, muletas, mobilidade reduzida, maca e acompanhante obrigatório.
- 1 abastecimento.
- 1 ocorrência de paciente ausente.
- 1 aviso da central.

## Regra de produção

Não usar `--dart-define=DEMO_SEED_ENABLED=true` em produção.

Com a flag desligada, a tela fica vazia até receber viagens atribuídas pela plataforma. Isso evita simular viagens inexistentes e preserva o fluxo correto de recebimento pelo painel.

## Arquivos envolvidos

- `modules/logistica/lib/core/logistica/logistica_demo_config.dart`
- `modules/logistica/lib/core/logistica/logistica_mock_seed.dart`
- `modules/logistica/lib/database/database_helper.dart`
- `modules/logistica/lib/motorista/operacional/logistica_fluxo_viagem_pages.dart`
- `modules/logistica/lib/motorista/minhas_viagens/minhas_viagens_page.dart`
