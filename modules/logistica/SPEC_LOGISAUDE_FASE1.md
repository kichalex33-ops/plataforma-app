# LogiSaúde - Especificação Fase 1

## Objetivo

Criar o núcleo operacional do aplicativo LogiSaúde para organização dos transportes da saúde municipal.

## Perfis

### Motorista
- Visualiza viagens atribuídas
- Inicia viagem
- Registra chegada
- Marca paciente ausente
- Registra observações
- Sincroniza dados com o servidor

### Supervisor
- Cria viagens
- Atribui motorista
- Atribui veículo
- Visualiza status em tempo real ou sincronizado
- Gera relatórios
- Acompanha pendências

## Entidades principais

### Motorista
- id
- nome
- telefone
- ativo

### Veículo
- id
- placa
- modelo
- capacidade
- ativo

### Paciente
- id
- nome
- telefone
- endereço
- observações

### Viagem
- id
- motorista_id
- veiculo_id
- paciente_id
- origem
- destino
- data
- horario_previsto
- status
- observacao
- criado_em
- atualizado_em
- sincronizado

## Status da viagem

- agendada
- em_andamento
- concluida
- cancelada
- paciente_ausente
- reagendada

## Regras iniciais

1. O app deve funcionar mesmo sem internet.
2. Todo registro deve ser salvo primeiro no banco local.
3. A sincronização com o servidor acontece depois.
4. O motorista não deve apagar viagens.
5. Cancelamentos exigem justificativa.
6. O supervisor deve conseguir auditar alterações.

## Telas da Fase 1

### Motorista
- Login
- Viagens do dia
- Detalhe da viagem
- Iniciar viagem
- Finalizar viagem
- Registrar ocorrência

### Supervisor
- Lista de viagens
- Cadastro de viagem
- Atribuição de motorista
- Atribuição de veículo
- Relatório básico

## Prioridade técnica

1. Banco local SQLite
2. Modelos Dart
3. Repositórios
4. Telas básicas
5. Sync posterior