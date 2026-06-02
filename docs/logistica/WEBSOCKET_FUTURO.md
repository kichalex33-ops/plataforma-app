# WebSocket Futuro

## Arquitetura Atual

O app trabalha com operação offline-first, persistência local e fila de sincronização. A comunicação futura com servidor pode começar por polling simples e evoluir para eventos em tempo real.

## Limites do Polling

- Pode atrasar alertas críticos.
- Aumenta consumo de rede.
- Pode gerar consultas repetidas.
- Escala mal com muitos motoristas.

## Eventos em Tempo Real Candidatos

- Viagem atribuída.
- Alteração de rota.
- Aviso da central.
- Pânico.
- Ocorrência.
- GPS atualizado.
- Retorno iniciado.
- Viagem concluída.

## Infraestrutura Necessária

- VPS ou ambiente com processo persistente.
- Suporte a WebSocket.
- TLS.
- Monitoramento.
- Reconexão automática.
- Fallback para fila offline.

## HostGator Compartilhado

Hospedagem compartilhada geralmente não é adequada para WebSocket persistente. A recomendação é usar VPS para tempo real e manter polling/fila offline como contingência.

## Recomendação

Não implementar WebSocket em produção até existir infraestrutura adequada. A primeira versão real deve manter polling controlado e fila offline.
