# Modelo de Dados Logistica

## Viagem

Tabela: `transportes_viagens`

Campos principais:

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
- `device_id`
- `version`
- `created_at`
- `updated_at`
- `sync_status`

Estados aceitos:

- `rascunho`
- `agendada`
- `em_andamento`
- `concluida`
- `cancelada`

## Paciente

Tabela: `pacientes`

Paciente e a pessoa cadastrada na rede municipal. Pode existir sem viagem.

## Passageiro

Tabela: `transportes_passageiros`

Passageiro e a participacao de uma pessoa em uma viagem especifica.

Campos principais:

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
- `created_at`
- `updated_at`
- `sync_status`

Regra: `viagem_id` e obrigatorio.

## Rastreio GPS

Tabela: `rastreamento_viagem`

Campos:

- `id`
- `municipio_id`
- `viagem_id`
- `latitude`
- `longitude`
- `velocidade`
- `timestamp`
- `origem_dado`
- `device_id`
- `version`
- `created_at`
- `updated_at`
- `sync_status`

Valores de `origem_dado`:

- `gps_real`
- `simulado`

## Sincronizacao

Devem entrar na `sync_queue`:

- `transportes_viagens`
- `transportes_motoristas`
- `transportes_veiculos`
- `transportes_passageiros`
- `pacientes`
- `auditoria_eventos`
- `rastreamento_viagem`
