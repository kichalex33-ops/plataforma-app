# Deploy HostGator

## Objetivo

Registrar cuidados caso a infraestrutura inicial use hospedagem compartilhada.

## Adequado Para

- APIs REST simples.
- Endpoints documentados.
- Painel administrativo tradicional.
- Polling moderado.

## Não Recomendado Para

- WebSocket persistente.
- Filas em background de alta frequência.
- Processos longos.
- BI pesado.
- IA local.

## Recomendação

Usar HostGator compartilhado apenas como etapa inicial e controlada. Para operação com tempo real, fila robusta, WebSocket e BI, migrar para VPS ou cloud gerenciada.

## Cuidados

- Rate limit.
- Paginação.
- Logs compactos.
- Backup diário.
- Tokens em variáveis de ambiente.
- Auditoria de operações críticas.
