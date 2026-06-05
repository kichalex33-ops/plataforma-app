# Fase 7 - Sincronizacao 3G/4G/Wi-Fi Preparada com Agentes

## Objetivo

Preparar o app Flutter para operar com sincronizacao segura em Wi-Fi, 3G/4G, modo offline e conexao instavel, sem alterar o servidor em `C:\dev\plataforma\app\server` e sem quebrar os fluxos ja existentes da Logistica.

## Analise Tecnica

O app ja possuia bases importantes no modulo Logistica:

- fila SQLite `sync_queue`;
- registros operacionais locais;
- `DriverSyncService`;
- `DriverSyncPanel`;
- card visual de sincronizacao na home do motorista;
- cliente `DriverApiClient` apontando para os contratos do servidor.

O servidor Node existente ja expoe endpoints compativeis com a evolucao:

- `GET /api/status`;
- `POST /api/driver/sync`;
- `POST /api/sync/evento`;
- `GET /api/sync/status`;
- `POST /api/sync/forcar`;
- endpoints operacionais do motorista em `/api/driver/...`.

Nesta fase, o painel web e o servidor nao foram alterados.

## Arquitetura Criada

Foram criadas camadas reutilizaveis em `lib/core`:

- `SyncAgent`;
- `ConnectivityAgent`;
- `AppHealthAgent`;
- `AuditAgent`;
- fila local core com `SyncQueueItem`;
- enums `SyncStatus`, `ConnectivityStatus` e `SyncOperationType`;
- reposititorio local persistente por `SharedPreferences`;
- servico de fila com dispatcher injetavel;
- widget compartilhado `SyncStatusCard`.

## Como Eventos Pendentes Sao Armazenados

Antes de qualquer tentativa de envio, o app cria um `SyncQueueItem` local. O item recebe:

- identificador local seguro;
- entidade;
- id da entidade;
- operacao;
- payload;
- status;
- contador de tentativas;
- data/hora de criacao;
- data/hora da ultima tentativa;
- data/hora de sincronizacao;
- erro mais recente.

Se o envio falhar, o item muda para `failed`, mas continua salvo localmente.

## Como o App se Comporta Offline

Quando a conexao esta `offline` ou `unstable`:

- o envio nao e executado;
- o evento permanece local;
- a quantidade de pendencias continua disponivel;
- o `AuditAgent` registra que a sincronizacao foi ignorada;
- o motorista pode continuar operando.

Quando a conexao volta para `wifi` ou `mobile`, o `SyncAgent` tenta reenviar automaticamente.

## Status Visual

O modulo Logistica ja possuia card de sincronizacao na home do motorista. Ele foi ajustado para exibir tambem a quantidade de pendencias reais da fila local.

Tambem foi criado o componente reutilizavel:

- `lib/shared/widgets/sync_status_card.dart`

Esse componente exibe:

- online/offline;
- sincronizando;
- pendente;
- erro de sincronizacao;
- ultima sincronizacao;
- contador de pendencias.

## AppHealthAgent

O `AppHealthAgent` consolida:

- quantidade de itens pendentes;
- ultima sincronizacao concluida;
- erros recentes;
- status geral de sync;
- status atual de conectividade;
- quantidade de eventos de auditoria.

## AuditAgent

O `AuditAgent` registra:

- tentativa de sincronizacao;
- sincronizacao concluida;
- falha de sincronizacao;
- sincronizacao ignorada por falta de conexao segura.

## Como Esta Fase Prepara a Fase 8

A Fase 7 deixa prontos os contratos internos para que a Fase 8 possa:

- ligar o dispatcher ao `DriverApiClient`;
- enviar eventos reais para `/api/driver/sync` ou `/api/sync/evento`;
- buscar status do servidor;
- aplicar reenvio automatico com backoff;
- tratar conflitos;
- decidir politica de sync em dados moveis;
- unificar gradualmente a fila core com a fila SQLite operacional da Logistica.

## Limitacoes Atuais

- O detector real de rede ainda nao usa plugin nativo.
- O dispatcher padrao ainda nao envia para a API real.
- Nao ha resolucao de conflitos servidor x dispositivo.
- A fila core e persistida em `SharedPreferences`, enquanto a Logistica continua com fila SQLite propria.
- Arquivos grandes, como fotos e comprovantes, ainda precisam de politica propria de upload.

## Validacao

Testes criados em:

- `test/core_sync_agents_test.dart`

Coberturas principais:

- evento salvo localmente quando offline;
- pendencia preservada sem internet;
- sincronizacao automatica quando conexao volta;
- falha preserva item e registra erro;
- health report informa pendencias e erros;
- reposititorio local preserva fila entre instancias;
- card do motorista exibe pendencias no resumo.
