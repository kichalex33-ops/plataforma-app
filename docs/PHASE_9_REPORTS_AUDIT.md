# Fase 9 - Relatorios e Auditoria Local

## Objetivo

Criar estrutura local de relatorios e auditoria dentro do app, funcionando sem internet e sem alterar o painel web.

## Arquivos criados

Auditoria:

- `lib/core/audit/models/audit_log.dart`
- `lib/core/audit/models/audit_event_type.dart`
- `lib/core/audit/models/audit_severity.dart`
- `lib/core/audit/models/audit_filter.dart`
- `lib/core/audit/repositories/audit_log_repository.dart`
- `lib/core/audit/services/audit_log_service.dart`
- `lib/core/audit/providers/audit_providers.dart`
- `lib/features/audit/pages/audit_history_page.dart`
- `lib/features/audit/widgets/audit_log_card.dart`
- `lib/features/audit/widgets/audit_filter_bar.dart`

Relatorios:

- `lib/features/reports/models/local_report.dart`
- `lib/features/reports/models/report_filter.dart`
- `lib/features/reports/services/local_report_service.dart`
- `lib/features/reports/providers/local_report_providers.dart`
- `lib/features/reports/pages/local_reports_page.dart`
- `lib/features/reports/widgets/report_summary_card.dart`

## Relatorios criados

- resumo de viagens;
- resumo de passageiros;
- resumo de ocorrencias;
- resumo de checklists;
- resumo de sincronizacao;
- resumo de saude local do app.

## Origem dos dados

Os relatorios reaproveitam os indicadores locais da Fase 8, que consolidam dados das tabelas locais do modulo logistico e da fila de sincronizacao da Fase 7.

## Filtros disponiveis

Auditoria:

- tipo de evento;
- severidade;
- data inicial;
- data final.

Relatorios:

- estrutura preparada para periodo inicial/final;
- filtro validado pelo `ValidationAgent`.

## Participacao dos agentes

- `AuditAgent`: registra eventos importantes e preserva compatibilidade com os eventos da sincronizacao.
- `ReportAgent`: coordena a consolidacao dos relatorios locais.
- `ValidationAgent`: valida filtros e evita contagens invalidas.
- `AppHealthAgent`: fornece pendencias, erros recentes e diagnostico local.

## Cuidados com dados sensiveis

A auditoria nao salva:

- senha;
- token;
- CPF completo;
- metadados sensiveis.

Quando esses dados aparecem em uma descricao, sao mascarados ou removidos antes da persistencia.

## Acesso no app

Foram adicionados acessos a:

- `Auditoria Local`;
- `Relatorios Locais`;

nos pontos de shell operacional e GOD MODE, sem alterar o painel web.

## Limitacoes atuais

- Relatorio ainda nao exporta PDF.
- Auditoria ainda nao sincroniza com o servidor.
- Logs locais ainda nao possuem politica de retencao.
- Filtros de relatorio por periodo estao preparados, mas os indicadores atuais ainda consolidam o estado local total.

## Proximos passos para a Fase 10

- Exportacao PDF/CSV controlada.
- Sincronizacao segura dos logs de auditoria.
- Relatorios por periodo, motorista e veiculo.
- Retencao local configuravel.
- Assinatura de eventos criticos.
