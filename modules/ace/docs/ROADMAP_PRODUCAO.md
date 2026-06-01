# Roadmap de Producao

## Fase 1 - Estabilizacao logistica

- Consolidar estados da viagem.
- Garantir passageiros sempre vinculados a viagem.
- Remover ultimos vestigios ACE/endemia do nucleo ativo.
- Garantir `sync_queue` para viagens, veiculos, motoristas, passageiros, pacientes, auditoria e GPS.

## Fase 2 - GPS real

- Coletar localizacao real em background/controlado.
- Registrar `rastreamento_viagem` com `origem_dado = gps_real`.
- Definir intervalo de coleta.
- Mostrar ultima posicao por viagem.

## Fase 3 - Backend

- Persistir dados em banco real no servidor Node.js.
- Receber fila offline.
- Devolver atualizacoes incrementais.
- Resolver conflitos por `updated_at`, `version` e regras de perfil.

## Fase 4 - Controle operacional

- Painel web municipal.
- Visao por veiculo.
- Alertas de atraso.
- Historico de passageiros por paciente.
- Exportacao de relatorios.

## Fase 5 - Producao assistida

- Piloto com equipe pequena.
- Validacao de campo.
- Ajustes de UX de motorista.
- Revisao de seguranca local.
- Politica de backup e suporte.
