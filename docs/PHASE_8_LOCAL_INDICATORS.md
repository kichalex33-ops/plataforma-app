# Fase 8 - Indicadores Locais

## Objetivo

Criar indicadores locais dentro do app, usando dados ja salvos no aparelho, sem depender de internet e sem alterar o painel web.

## Arquivos principais

- `lib/features/indicators/models/local_indicators.dart`
- `lib/features/indicators/services/local_indicators_service.dart`
- `lib/features/indicators/providers/local_indicators_providers.dart`
- `lib/features/indicators/pages/local_indicators_page.dart`
- `lib/features/indicators/widgets/indicator_card.dart`
- `lib/core/agents/report_agent.dart`
- `lib/core/agents/validation_agent.dart`
- `lib/core/agents/audit_agent.dart`

## Indicadores criados

- Total de viagens.
- Viagens pendentes.
- Viagens em andamento.
- Viagens concluidas.
- Passageiros transportados.
- Ocorrencias registradas.
- Checklists concluidos.
- Itens pendentes de sincronizacao.
- Ultima sincronizacao.
- Status atual de conexao.
- Erros locais recentes.

## Origem dos dados

Os indicadores operacionais usam tabelas locais do modulo logistico:

- `logistica_viagens`
- `logistica_passageiros_viagem`
- `logistica_ocorrencias`
- `logistica_checklists`
- `logistica_sync_items`

Os indicadores de saude e sincronizacao usam a base da Fase 7:

- `SyncAgent`
- `AppHealthAgent`
- `ConnectivityAgent`
- `SyncQueueRepository`

## Comportamento offline

A tela funciona sem internet. Quando nao houver dados locais, os indicadores exibem zero ou `nao disponivel`, sem quebrar a interface.

Nenhuma tentativa de envio ao servidor e feita pela tela de indicadores.

## Participacao dos agentes

- `ReportAgent`: coordena a consolidacao dos dados locais.
- `AppHealthAgent`: informa pendencias, ultima sincronizacao, erros recentes e status geral.
- `AuditAgent`: registra acesso e atualizacao manual da tela.
- `ValidationAgent`: valida os dados consolidados antes de liberar o resultado.

## Interface

Foi criada a tela `Indicadores Locais`, com cards para:

- viagens;
- passageiros;
- ocorrencias;
- checklists;
- sincronizacao;
- conexao;
- saude do app.

A tela foi ligada ao painel operacional do operador logistico e ao God Mode. No fluxo direto do motorista, a home ainda pertence ao pacote interno da logistica; a integracao visual nessa home fica como passo futuro para evitar acoplamento desnecessario nesta fase.

## Limitacoes atuais

- Sem filtros por periodo.
- Sem graficos historicos.
- Sem comparativo por motorista, veiculo ou rota.
- Sem envio ao painel.
- Sem BI externo.

## Preparacao para a Fase 9

A Fase 9 pode evoluir para:

- filtros locais por data, motorista e veiculo;
- graficos simples no app;
- exportacao de resumo;
- envio dos indicadores consolidados para API futura;
- comparacao entre dados locais e dados sincronizados do painel.
