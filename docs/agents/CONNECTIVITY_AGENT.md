# ConnectivityAgent

## Objetivo

O `ConnectivityAgent` prepara o app para reconhecer o estado da conexao e informar o `SyncAgent` quando houver condicao segura para tentar envio.

## Estrutura Implementada

Arquivos principais:

- `lib/core/agents/connectivity_agent.dart`
- `lib/core/connectivity/models/connectivity_status.dart`
- `lib/core/connectivity/services/connectivity_service.dart`
- `lib/core/connectivity/providers/connectivity_providers.dart`

## Status de Conexao

- `wifi`: conexao por Wi-Fi, liberada para sincronizacao.
- `mobile`: dados moveis 3G/4G, liberados para sincronizacao.
- `offline`: sem conexao, fila permanece local.
- `unstable`: conexao instavel, envio automatico fica bloqueado para evitar perda operacional.

## Comportamento Offline

Quando o app esta offline:

- eventos continuam sendo salvos localmente;
- o motorista nao perde registros;
- o `SyncAgent` nao tenta envio;
- o `AuditAgent` registra sincronizacao ignorada;
- a interface pode exibir status offline e pendencias.

## Comportamento com Conexao Instavel

Conexao instavel e tratada como nao segura para sincronizar automaticamente. Os itens permanecem pendentes ate o estado mudar para Wi-Fi ou dados moveis.

## Relacao com o SyncAgent

O `ConnectivityAgent` permite registrar listeners. O `SyncAgent` escuta essas mudancas e dispara `syncNow()` quando o status passa para:

- `wifi`;
- `mobile`.

## Limitacoes Atuais

- A deteccao real por plugin nativo ainda nao foi ligada.
- O status e uma abstracao preparada para receber uma implementacao futura com `connectivity_plus` ou servico equivalente.
- Ainda nao existe medicao de qualidade da rede por latencia/perda de pacotes.

## Proximos Passos

Na Fase 8, conectar a abstracao ao detector real de rede do aparelho, criar politica para sync em dados moveis e adicionar backoff para conexoes instaveis.
