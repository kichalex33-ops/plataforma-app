# Roadmap Logística - 3 Meses

## Situação após a etapa 5

A base técnica offline-first e o controle operacional inicial foram criados:

- Enums de estados, pacientes, ocorrências, acessibilidade e sync.
- Modelos locais de domínio.
- Tabelas SQLite `logistica_*`.
- Validações essenciais.
- Calculadora operacional.
- Fila offline tipada.
- Seed mockado realista.
- Testes unitários da base.
- Fluxo operacional de viagem.
- Checklist pré-uso e pós-uso.
- Abastecimentos e despesas gerais.
- Ocorrências tipadas e botão de pânico.
- Comprovantes SUS vinculados à viagem e ao paciente.
- Histórico da viagem com checklists, despesas, ocorrências, comprovantes e sync.

## Próxima ordem recomendada

### 1. Refinar repositórios locais

Criar repositórios específicos para:

- Viagens.
- Pacientes.
- Passageiros.
- Abastecimentos e despesas.
- Ocorrências e pânico.
- Comprovantes SUS.
- Avisos.
- Fila offline.

### 2. Captura real de mídia e localização

Evoluir os campos locais atuais para:

- Câmera/galeria para comprovantes.
- Foto do cupom.
- Foto de ocorrência.
- GPS real para pânico e ocorrências.
- Permissão e tratamento quando localização estiver indisponível.

### 3. Tela de rota de ida

Usar os modelos novos para:

- Lista de paradas.
- Pacientes.
- Acessibilidade.
- Ausência/desistência.
- Eventos offline.

### 4. Espera e reembarque

Implementar:

- Estado `em_espera`.
- Tempo de espera.
- Reembarque de retorno.
- Validação de pacientes embarcados ou justificados.

### 5. Encerramento

Implementar:

- KM final.
- Cálculo de KM rodado.
- Divergência de KM.
- Total de despesas.
- Pacientes transportados.
- Ocorrências.

### 6. Sincronização futura

Evoluir:

- `logistica_sync_items`.
- Tentativas.
- Erros.
- Reenvio.
- Contrato de API futuro.

## Entregas já concluídas

- Etapa 2: viagens atribuídas, preparação e check-in de saída.
- Etapa 3: base técnica de modelos, estados e banco local.
- Etapa 4: fluxo operacional da viagem.
- Etapa 5: checklists, abastecimentos, despesas, ocorrências, pânico, comprovantes e histórico.

## Pendências do MVP

- Captura real de fotos.
- Captura real de GPS.
- Assinatura digital.
- Painel de pendências de sync baseado em `logistica_sync_items`.
