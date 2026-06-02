# Plano de Dados da Logística

## Objetivo

Planejar a evolução dos dados locais do módulo Logística para suportar transporte sanitário offline-first, preservando a base SQLite atual e preparando sincronização futura com servidor.

## Base de dados atual

O banco atual é inicializado em `modules/logistica/lib/database/database_helper.dart` com o arquivo `logisaude.db`.

Na etapa 2, o schema passou a ser garantido por uma rotina idempotente para adicionar campos novos mesmo quando o banco local já existir no aparelho.

Tabelas já existentes:

- `app_config`
- `sync_queue`
- `sync_logs`
- `auditoria_eventos`
- `exclusoes_log`
- `alertas_operacionais`
- `transportes_motoristas`
- `transportes_veiculos`
- `transportes_viagens`
- `transportes_passageiros`
- `pacientes`
- `mapas_camadas`
- `rastreamento_viagem`
- `mensagens`
- `checklists`

## Entidades atuais aproveitáveis

### Motoristas

Tabela: `transportes_motoristas`

Campos úteis:

- `id`
- `municipio_id`
- `nome`
- `cpf`
- `telefone`
- `cnh`
- `status`
- `observacoes`
- `sync_status`

Evolução:

- Vincular motorista logado à viagem ativa.
- Calcular histórico por motorista.
- Associar veículo atual.

### Veículos

Tabela: `transportes_veiculos`

Campos úteis:

- `id`
- `municipio_id`
- `placa`
- `modelo`
- `tipo`
- `capacidade`
- `status`
- `observacoes`
- `sync_status`

Evolução:

- Adicionar controle operacional de KM atual.
- Relacionar checklists, abastecimentos, despesas e ocorrências.

### Viagens

Tabela: `transportes_viagens`

Campos úteis:

- `id`
- `municipio_id`
- `motorista_id`
- `veiculo_id`
- `origem`
- `destino`
- `data_hora_saida`
- `data_hora_retorno`
- `status`
- `finalidade`
- `rota_geojson`
- `observacoes`
- `sync_status`

Evolução para MVP:

- `prioridade` - implementado na etapa 2.
- `destino_principal` - implementado na etapa 2.
- `status_operacional` - implementado na etapa 2.
- `km_saida` - implementado na etapa 2.
- `horario_saida_confirmada` - implementado na etapa 2.
- `km_final`
- `horario_inicio_espera`
- `horario_inicio_retorno`
- `horario_finalizacao`
- `total_km`
- `total_despesas`
- `pendente_revisao_km`
- `motivo_revisao_km`
- `rota_atualizada_pendente`
- `rota_confirmada_em`

### Passageiros

Tabela: `transportes_passageiros`

Campos úteis:

- `id`
- `municipio_id`
- `viagem_id`
- `paciente_id`
- `nome`
- `documento`
- `necessidade_especial`
- `embarque`
- `desembarque`
- `status`
- `observacoes`
- `sync_status`

Evolução para MVP:

- `cadeirante` - implementado na etapa 2.
- `usa_muletas` - planejado.
- `dificuldade_locomocao` - implementado como `mobilidade_reduzida`.
- `acompanhante` - implementado na etapa 2.
- `observacoes_embarque` - implementado na etapa 2.
- `telefone` - implementado na etapa 2.
- `endereco_embarque` - implementado na etapa 2.
- `ordem_embarque`
- `ordem_desembarque`
- `status_ida`
- `status_retorno`
- `justificativa_nao_retorno`
- `comprovante_foto_path`
- `assinatura_path`, futuro.

### Eventos operacionais

Tabela usada: `eventos_operacionais`, via repositório específico.

Campos identificados no modelo:

- `id`
- `viagem_id`
- `motorista_id`
- `municipio_id`
- `tipo`
- `payload_json`
- `latitude`
- `longitude`
- `created_at`
- `sync_status`

Evolução:

- Padronizar tipos de evento da máquina de estados.
- Usar payload versionado.
- Registrar eventos de pânico, KM, checklist, despesas, comprovantes e ocorrências.

### Checklists

Tabela: `checklists`

Campos úteis:

- `id`
- `municipio_id`
- `viagem_id`
- `motorista_id`
- `tipo`
- `payload_json`
- `created_at`
- `sync_status`

Evolução:

- `tipo = pre_uso`
- `tipo = pos_uso`
- Payload com itens obrigatórios e observações.
- Bloquear saída sem checklist pré-uso.

### Mensagens e avisos

Tabela: `mensagens`

Campos úteis:

- `id`
- `municipio_id`
- `motorista_id`
- `viagem_id`
- `direcao`
- `conteudo`
- `created_at`
- `sync_status`

Evolução:

- Adicionar `titulo`.
- Adicionar `prioridade`.
- Adicionar `lida_em`.
- Usar como base para avisos da central mockados.

## Novas entidades recomendadas para o MVP

### `viagem_estado_eventos`

Finalidade: registrar histórico de transições da máquina de estados.

Campos:

- `id`
- `municipio_id`
- `viagem_id`
- `estado_anterior`
- `estado_novo`
- `evento`
- `payload_json`
- `latitude`
- `longitude`
- `created_at`
- `sync_status`

### `viagem_paradas`

Finalidade: ordenar rota de ida e volta.

Campos:

- `id`
- `municipio_id`
- `viagem_id`
- `tipo`
- `ordem`
- `titulo`
- `endereco`
- `latitude`
- `longitude`
- `paciente_id`
- `status`
- `created_at`
- `updated_at`
- `sync_status`

Tipos:

- `embarque`
- `desembarque_ida`
- `reembarque_retorno`
- `desembarque_retorno`
- `destino_principal`

### `viagem_km_registros`

Finalidade: controlar KM inicial/final e auditoria.

Campos:

- `id`
- `municipio_id`
- `viagem_id`
- `veiculo_id`
- `motorista_id`
- `tipo`
- `km`
- `horario`
- `foto_painel_path`
- `observacao`
- `pendente_revisao`
- `motivo_revisao`
- `sync_status`

Tipos:

- `saida`
- `final`
- `intermediario`

### `viagem_preparacoes`

Implementada na etapa 2.

Finalidade: registrar a preparação, checklist pré-uso, KM inicial e confirmação de saída.

Campos:

- `id`
- `municipio_id`
- `viagem_id`
- `motorista_id`
- `veiculo_id`
- `km_inicial`
- `checklist_concluido`
- `checklist_payload_json`
- `horario_preparacao`
- `horario_saida`
- `status`
- `sync_status`

### `viagem_despesas`

Finalidade: registrar abastecimentos e despesas.

Campos:

- `id`
- `municipio_id`
- `viagem_id`
- `veiculo_id`
- `motorista_id`
- `tipo`
- `local`
- `litros`
- `valor`
- `valor_por_litro`
- `foto_cupom_path`
- `observacao`
- `created_at`
- `sync_status`

Tipos:

- `abastecimento`
- `pedagio`
- `estacionamento`
- `manutencao_emergencial`
- `outro`

### `viagem_ocorrencias`

Finalidade: tipar ocorrências e botão de pânico.

Campos:

- `id`
- `municipio_id`
- `viagem_id`
- `motorista_id`
- `paciente_id`
- `tipo`
- `descricao`
- `foto_path`
- `latitude`
- `longitude`
- `created_at`
- `sync_status`

Tipos:

- `paciente_ausente`
- `desistencia`
- `pane_mecanica`
- `pneu_furado`
- `acidente`
- `paciente_passou_mal`
- `atraso`
- `panico`
- `outro`

### `viagem_comprovantes`

Finalidade: vincular foto de comprovante/canhoto a paciente e viagem.

Campos:

- `id`
- `municipio_id`
- `viagem_id`
- `passageiro_id`
- `paciente_id`
- `tipo`
- `foto_path`
- `assinatura_path`
- `observacao`
- `created_at`
- `sync_status`

Tipos:

- `presenca`
- `consulta`
- `retorno`
- `outro`

### `avisos_central`

Finalidade: avisos mockados/local no MVP e sincronizados no futuro.

Campos:

- `id`
- `municipio_id`
- `motorista_id`
- `viagem_id`
- `titulo`
- `mensagem`
- `prioridade`
- `created_at`
- `lido_em`
- `sync_status`

Prioridades:

- `baixa`
- `normal`
- `alta`
- `urgente`

## Dados para versão 2.0

### Material/carga sanitária

Entidade futura: `viagem_materiais`

Campos planejados:

- `id`
- `municipio_id`
- `viagem_id`
- `descricao`
- `quantidade`
- `destino`
- `receptor`
- `foto_protocolo_path`
- `codigo_barras`
- `qr_code`
- `created_at`
- `sync_status`

## Estratégia offline-first

- Toda ação operacional deve gravar primeiro no SQLite.
- Toda ação sincronizável deve entrar na `sync_queue` ou em tabela com `sync_status`.
- Não depender do backend para continuar a viagem.
- Falhas de rede devem aparecer como pendência, não como bloqueio.
- Imagens devem ser armazenadas por caminho local e sincronizadas futuramente por endpoint de upload.

## Estratégia de migração

1. Não apagar tabelas existentes.
2. Adicionar novas tabelas com `CREATE TABLE IF NOT EXISTS`.
3. Manter compatibilidade com `transportes_viagens.status`.
4. Usar `status_operacional` novo para a máquina sanitária.
5. Criar migração incremental quando houver mudança real no código.
6. Documentar cada tabela nova antes da implementação.

## Índices recomendados

- `viagem_estado_eventos(viagem_id, created_at)`
- `viagem_paradas(viagem_id, tipo, ordem)`
- `viagem_km_registros(viagem_id, tipo)`
- `viagem_despesas(viagem_id, created_at)`
- `viagem_ocorrencias(viagem_id, tipo, created_at)`
- `viagem_comprovantes(viagem_id, passageiro_id)`
- `avisos_central(motorista_id, created_at)`

## Riscos de dados

- Crescimento de arquivos de imagem no aparelho.
- Eventos duplicados quando o motorista tocar duas vezes em um botão.
- Conflito entre rota local e rota alterada pela central.
- Divergência de KM entre motorista e odômetro esperado.
- Perda de contexto se a viagem for encerrada sem sincronizar.
- Incompatibilidade entre status antigo e novo durante migração.

## Critérios de aceite

- O app mantém viagem operacional mesmo offline.
- Todos os eventos obrigatórios possuem `sync_status`.
- KM inicial e final ficam auditáveis.
- Comprovantes ficam vinculados ao paciente e à viagem.
- Ocorrências ficam tipadas e pesquisáveis.
- A fila de sincronização consegue contar pendências e falhas.
