# Integrações Externas

## Objetivo

Preparar a Logística para conversar futuramente com seguradora, guincho, assistência técnica, manutenção e central externa.

## Implementação Atual

Arquivo:

- `modules/logistica/lib/core/logistica/integracoes/logistica_external_integration.dart`

Estruturas criadas:

- `LogisticaExternalDestination`
- `LogisticaExternalDispatchStatus`
- `LogisticaExternalDispatchItem`
- `LogisticaExternalIntegrationLog`
- `LogisticaExternalDispatchQueue`
- `LogisticaWebhookSimulationGateway`

## Status de Envio

- `aguardandoEnvio`
- `enviado`
- `recebido`
- `confirmado`
- `emAtendimento`
- `concluido`
- `erro`

## Fluxo Simulado

1. A operação cria um item de envio externo.
2. O item entra como `aguardandoEnvio`.
3. O processamento usa gateway simulado.
4. Falha simulada marca `erro`.
5. Nova tentativa pode marcar `enviado`.
6. Cada etapa gera log interno.

## Produção

Antes de integrar API real:

- obter credenciais;
- mapear endpoints;
- assinar contrato de tratamento de dados;
- registrar auditoria;
- aplicar retry com backoff;
- garantir idempotência por `id`;
- proteger tokens e logs sensíveis.
