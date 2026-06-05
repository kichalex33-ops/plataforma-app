# ReportAgent

## Objetivo

O `ReportAgent` coordena a consolidacao de dados locais para relatorios e indicadores do app, sem executar calculos diretamente na interface.

## Responsabilidades

- Receber uma rotina de consolidacao.
- Centralizar o ponto de entrada para relatorios locais.
- Permitir evolucao futura para cache, filtros, exportacao e envio ao painel.
- Manter a tela desacoplada das consultas do banco local.

## Uso na Fase 8

Na Fase 8, o agente e usado pelo `LocalIndicatorsService` para consolidar:

- total de viagens;
- viagens pendentes;
- viagens em andamento;
- viagens concluidas;
- passageiros transportados;
- ocorrencias registradas;
- checklists concluidos;
- pendencias de sincronizacao;
- ultima sincronizacao;
- status de conexao;
- erros recentes.

## Limites atuais

- Nao envia relatorios ao servidor.
- Nao gera PDF, planilha ou BI externo.
- Nao aplica filtros por periodo, motorista ou veiculo.

## Proximos passos

- Adicionar filtros locais.
- Preparar exportacao controlada.
- Integrar com relatorios do painel quando a API oficial estiver pronta.
