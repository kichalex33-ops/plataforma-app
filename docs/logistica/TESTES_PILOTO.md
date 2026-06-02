# Testes de Piloto

## Piloto 1 — Operação Mínima

Participantes:

- 1 motorista.
- 1 veículo.
- 1 viagem.
- 1 passageiro.

Roteiro:

1. Login do motorista.
2. Recebimento ou cadastro controlado da viagem.
3. Checklist pré-uso.
4. KM inicial.
5. Saída confirmada.
6. Envio de GPS.
7. Alteração de status do passageiro.
8. Registro de ocorrência simples.
9. Checklist pós-uso.
10. KM final.
11. Relatório final.

Critérios:

- Nenhum dado perdido offline.
- Fila sincronizável.
- Ocorrência registrada.
- Relatório coerente.

## Piloto 2 — Operação Simultânea

Participantes:

- 2 veículos.
- 2 motoristas.
- Viagens simultâneas.

Roteiro:

1. Uma viagem com conexão normal.
2. Uma viagem com motorista offline.
3. Alerta de GPS.
4. Ocorrência em uma viagem.
5. Fechamento operacional das duas viagens.

Critérios:

- Estados independentes.
- Eventos sem duplicidade.
- Motorista offline não bloqueia o outro.
- Fechamento operacional auditável.
