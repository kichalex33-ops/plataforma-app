# Plano de Dados da Logística

## Base técnica implementada

A etapa 3 criou uma base offline-first própria para transporte sanitário dentro do módulo Logística, sem remover as tabelas legadas do LogiSaúde.

Arquivos principais:

- `modules/logistica/lib/core/logistica/logistica_enums.dart`
- `modules/logistica/lib/core/logistica/logistica_models.dart`
- `modules/logistica/lib/core/logistica/logistica_validators.dart`
- `modules/logistica/lib/core/logistica/logistica_calculator.dart`
- `modules/logistica/lib/core/logistica/logistica_offline_queue.dart`
- `modules/logistica/lib/core/logistica/logistica_mock_seed.dart`
- `modules/logistica/lib/database/database_helper.dart`

## Enums criados

- `StatusViagem`
- `StatusPacienteIda`
- `StatusPacienteVolta`
- `TipoOcorrencia`
- `TipoAcessibilidade`
- `StatusSync`
- `TipoEventoSync`

Todos possuem serialização em `snake_case` por `dbValue`, facilitando persistência local e sincronização futura.

## Modelos criados

Todos os modelos possuem:

- `idLocal`
- `idServidor`
- `createdAt`
- `updatedAt`
- `statusSync`

Modelos:

- `LogisticaViagem`
- `LogisticaPaciente`
- `LogisticaPassageiroViagem`
- `LogisticaVeiculo`
- `LogisticaMotorista`
- `LogisticaChecklist`
- `LogisticaAbastecimento`
- `LogisticaOcorrencia`
- `LogisticaComprovante`
- `LogisticaAvisoCentral`
- `LogisticaSyncItem`

## Tabelas criadas

As tabelas são criadas com `CREATE TABLE IF NOT EXISTS`, mantendo compatibilidade com bancos já existentes.

- `logistica_viagens`
- `logistica_pacientes`
- `logistica_passageiros_viagem`
- `logistica_veiculos`
- `logistica_motoristas`
- `logistica_checklists`
- `logistica_abastecimentos`
- `logistica_ocorrencias`
- `logistica_comprovantes`
- `logistica_avisos_central`
- `logistica_sync_items`

Índices criados:

- `idx_logistica_viagens_status`
- `idx_logistica_passageiros_viagem`
- `idx_logistica_sync_status`

## Tabelas legadas preservadas

Continuam existindo e não foram removidas:

- `transportes_viagens`
- `transportes_passageiros`
- `transportes_motoristas`
- `transportes_veiculos`
- `checklists`
- `mensagens`
- `sync_queue`
- `auditoria_eventos`

## Validações criadas

Arquivo: `logistica_validators.dart`

- KM final não pode ser menor que KM inicial.
- KM final muito divergente marca pendência de revisão.
- Não iniciar viagem sem KM de saída.
- Não iniciar viagem sem checklist pré-uso.
- Não iniciar retorno sem pacientes embarcados ou justificados.
- Não concluir viagem sem KM final.
- Abastecimento não pode ter litros zero ou valor negativo.
- Ocorrência deve ter tipo e data/hora.

## Cálculos criados

Arquivo: `logistica_calculator.dart`

- KM rodado.
- Valor por litro.
- Custo por km.
- Custo por paciente.
- Total de despesas da viagem.
- Tempo em espera.
- Duração total da viagem.
- Quantidade de pacientes transportados.
- Quantidade de ausentes/desistentes.

## Fila offline

Arquivo: `logistica_offline_queue.dart`

Eventos suportados:

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

Tabela local:

- `logistica_sync_items`

Campos:

- `id_local`
- `tipo_evento`
- `payload_json`
- `status_sync`
- `tentativas`
- `ultima_tentativa`
- `erro`
- `created_at`
- `updated_at`

## Seed mockado

Arquivo: `logistica_mock_seed.dart`

Criado para demonstração sem backend:

- 2 veículos.
- 2 motoristas.
- 3 viagens.
- 8 pacientes.
- Pacientes com acessibilidade.
- 1 abastecimento.
- 1 ocorrência de paciente ausente.
- 1 aviso da central.

O seed roda apenas quando `logistica_viagens` está vazia.

## Pendências

- Criar repositórios específicos para cada tabela nova.
- Migrar gradualmente as telas atuais para consumir `logistica_*`.
- Criar sincronização real dos itens `logistica_sync_items`.
- Adicionar controle de fotos para comprovantes e cupons.
- Criar telas de rota, espera, retorno e encerramento usando esta base.
