# WebSocket e Tempo Real

## Objetivo

Planejar comunicação em tempo real entre painel futuro, app do motorista e supervisão.

## Eventos Candidatos

- Viagem atribuída.
- Saída confirmada.
- Paciente ausente.
- Ocorrência registrada.
- Pânico acionado.
- Retorno iniciado.
- Viagem concluída.

## Regras

- O app deve continuar offline-first.
- WebSocket não substitui fila offline.
- Eventos críticos devem ser persistidos localmente antes de sincronizar.

## Riscos

- Conexão instável em áreas rurais.
- Eventos duplicados.
- Ordem incorreta de eventos.
