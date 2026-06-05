# SyncAgent

## Objetivo

O `SyncAgent` prepara o app para sincronizacao segura em Wi-Fi, 3G/4G, modo offline e conexao instavel. Ele garante que eventos operacionais sejam gravados localmente antes de qualquer tentativa de envio para o servidor.

## Estrutura Implementada

Arquivos principais:

- `lib/core/agents/sync_agent.dart`
- `lib/core/sync/models/sync_queue_item.dart`
- `lib/core/sync/models/sync_status.dart`
- `lib/core/sync/models/sync_operation_type.dart`
- `lib/core/sync/repositories/sync_queue_repository.dart`
- `lib/core/sync/services/sync_queue_service.dart`
- `lib/core/sync/providers/sync_providers.dart`

## Como Funciona a Fila

Cada evento entra na fila como `SyncQueueItem` com:

- `id` local seguro;
- tipo de operacao;
- entidade;
- id da entidade;
- `payload`;
- status;
- tentativas;
- data de criacao;
- data da ultima tentativa;
- data de sincronizacao;
- erro mais recente.

O reposititorio padrao do app usa `SharedPreferencesSyncQueueRepository`, preservando os itens localmente entre execucoes do app. Para testes unitarios, existe `InMemorySyncQueueRepository`.

## Status

- `pending`: evento salvo localmente e aguardando envio.
- `syncing`: evento em tentativa de envio.
- `synced`: evento enviado com sucesso.
- `failed`: envio falhou, mas o item continua salvo para reenvio.

Nenhum dado local e apagado quando ocorre falha.

## Conversa com o Servidor

O servidor existente em `C:\dev\plataforma\app\server` ja expoe contratos compativeis para evolucao:

- `GET /api/status`
- `POST /api/driver/sync`
- `POST /api/sync/evento`
- `GET /api/sync/status`
- `POST /api/sync/forcar`

Nesta fase, o envio real fica preparado por meio de um `dispatcher` injetavel. As chamadas reais podem ser conectadas ao `DriverApiClient` sem alterar a regra da fila.

## Como o SyncAgent Conversa com o ConnectivityAgent

O `SyncAgent` escuta mudancas de conexao no `ConnectivityAgent`. Quando a conexao muda para Wi-Fi ou dados moveis, o agente tenta sincronizar os itens pendentes.

Se a conexao estiver offline ou instavel, o envio e ignorado e os itens permanecem locais.

## Auditoria

O `SyncAgent` aciona o `AuditAgent` para registrar:

- tentativa de sincronizacao;
- sincronizacao concluida;
- falha de sincronizacao;
- sincronizacao ignorada por falta de conexao segura.

## Limitacoes Atuais

- O envio real para API ainda nao foi ligado ao dispatcher padrao.
- Ainda nao ha reconciliacao de conflitos com dados vindos do servidor.
- Ainda nao ha backoff exponencial.
- A fila central em `lib/core/sync` usa `SharedPreferences`; o modulo Logistica tambem possui fila SQLite propria que continua preservada.

## Proximos Passos

Na Fase 8, ligar o dispatcher ao contrato real do servidor, definir politica de reenvio, aplicar backoff, tratar conflitos e unificar gradualmente a fila core com a fila SQLite da Logistica.
