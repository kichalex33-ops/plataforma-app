# Manutenção Preventiva da Frota

## Objetivo

Evitar que veículos com risco operacional sejam usados em viagens de saúde.

## Implementação Atual

Arquivo:

- `modules/logistica/lib/core/logistica/manutencao/logistica_manutencao_frota.dart`

Classes:

- `LogisticaFleetMaintenanceSnapshot`
- `LogisticaFleetMaintenanceStatus`
- `LogisticaFleetMaintenancePolicy`

## Regras Preparadas

Bloqueio operacional:

- revisão vencida por KM;
- troca de óleo vencida;
- documento vencido;
- seguro vencido;
- CNH vencida.

Alertas preventivos:

- revisão próxima;
- troca de óleo próxima;
- documento próximo do vencimento;
- seguro próximo do vencimento;
- CNH próxima do vencimento;
- pneus com revisão pendente.

## Próximo Passo

Persistir esses dados em banco local e exibir alertas no fluxo de seleção/preparação do veículo.
