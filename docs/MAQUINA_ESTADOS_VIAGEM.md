# Máquina de Estados da Viagem

## Estados implementados na base técnica

A etapa 3 formalizou os estados em `StatusViagem`:

- `aguardando`
- `preparacao`
- `saidaConfirmada`
- `emTransitoIda`
- `emEspera`
- `reembarqueRetorno`
- `emTransitoVolta`
- `finalizacao`
- `concluida`
- `pendenteSincronizacao`
- `sincronizada`
- `erroSincronizacao`
- `pendenteRevisao`

Na persistência, esses valores são serializados em `snake_case`, por exemplo:

- `saidaConfirmada` vira `saida_confirmada`
- `emTransitoIda` vira `em_transito_ida`
- `pendenteRevisao` vira `pendente_revisao`

## Fluxo operacional

Fluxo principal planejado:

1. `aguardando`
2. `preparacao`
3. `saida_confirmada`
4. `em_transito_ida`
5. `em_espera`
6. `reembarque_retorno`
7. `em_transito_volta`
8. `finalizacao`
9. `concluida`

Estados de sincronização e auditoria:

- `pendente_sincronizacao`
- `sincronizada`
- `erro_sincronizacao`
- `pendente_revisao`

## Estados de paciente

Ida:

- `aguardando`
- `embarcado`
- `desembarcado`
- `ausente`
- `desistiu`

Volta:

- `aguardando`
- `embarcado`
- `desembarcado`
- `nao_retornou`
- `justificado`

## Ocorrências

Tipos criados em `TipoOcorrencia`:

- `panico`
- `paciente_ausente`
- `desistencia`
- `pane_mecanica`
- `pneu_furado`
- `acidente`
- `paciente_passou_mal`
- `atraso`
- `abastecimento`
- `despesa`
- `outro`

## Regras implementadas

- KM final menor que KM inicial gera erro.
- KM muito divergente marca pendência de revisão.
- Início de viagem exige KM de saída e checklist pré-uso.
- Retorno exige pacientes embarcados ou justificados.
- Conclusão exige KM final.
- Abastecimento exige litros maior que zero e valor não negativo.
- Ocorrência exige tipo e data/hora.

## Eventos da fila offline

Eventos formalizados em `TipoEventoSync`:

- `viagem_iniciada`
- `paciente_desembarcado`
- `paciente_ausente`
- `paciente_desistiu`
- `comprovante_capturado`
- `abastecimento_registrado`
- `ocorrencia_registrada`
- `panico_acionado`
- `retorno_iniciado`
- `viagem_concluida`

## Pendências

- Aplicar `StatusViagem` novo nas próximas telas complexas.
- Criar transições controladas por serviço de estado.
- Persistir histórico completo de transições por viagem.
- Integrar a fila `logistica_sync_items` com envio real no futuro.
