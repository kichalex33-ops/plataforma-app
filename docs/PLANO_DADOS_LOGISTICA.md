# Plano de Dados da Logística

## Base técnica implementada

A etapa 3 criou uma base offline-first própria para transporte sanitário dentro do módulo Logística, sem remover as tabelas legadas do próprio módulo.

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

## Ajustes da etapa 5

Foram adicionados campos opcionais por migração leve para suportar auditoria e operação real sem quebrar bancos existentes:

- `logistica_checklists`: `observacao`, `foto_path`, `created_by`, `deleted_at`.
- `logistica_abastecimentos`: `created_by`, `deleted_at`.
- `logistica_ocorrencias`: `latitude`, `longitude`, `created_by`, `deleted_at`.
- `logistica_comprovantes`: `created_by`, `deleted_at`.

As despesas gerais usam `logistica_abastecimentos` como tabela operacional de despesas da viagem, diferenciadas pelo campo `tipo`.

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
- Checklist pré-uso é obrigatório para confirmar saída.
- Checklist pós-uso é obrigatório para concluir viagem.
- Checklist deve ter ao menos um item.
- Despesa geral não pode ter valor negativo.
- Despesa geral deve ter descrição.

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
- Valor por litro no registro de abastecimento.
- Custo por km para despesas da viagem.
- Custo por paciente no snapshot operacional da viagem.

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

## Seed de homologação

Arquivo: `logistica_mock_seed.dart`

Criado para homologação sem backend, mas desligado por padrão. O seed só roda quando o app for iniciado com:

```powershell
C:\flutter\bin\flutter.bat run --dart-define=DEMO_SEED_ENABLED=true
```

Quando habilitado, cria:

- 2 veículos.
- 2 motoristas, incluindo `Alex` com id `motorista-local`.
- 3 viagens.
- 8 pacientes.
- Pacientes com acessibilidade.
- 1 abastecimento.
- 1 ocorrência de paciente ausente.
- 1 aviso da central.

Com `DEMO_SEED_ENABLED=false`, o app não cria dados falsos e a tela de viagens permanece vazia até receber viagens atribuídas pelo painel.

## Pendências

- Criar repositórios específicos para cada tabela nova.
- Migrar gradualmente as telas atuais para consumir `logistica_*`.
- Criar sincronização real dos itens `logistica_sync_items`.
- Trocar campos de caminho de foto pela captura real de câmera/galeria.
- Capturar GPS real para ocorrências e pânico.
- Implementar assinatura digital do comprovante SUS.
