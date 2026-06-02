# Roadmap Logística - 3 Meses

## Situação após a etapa 3

A base técnica offline-first foi criada:

- Enums de estados, pacientes, ocorrências, acessibilidade e sync.
- Modelos locais de domínio.
- Tabelas SQLite `logistica_*`.
- Validações essenciais.
- Calculadora operacional.
- Fila offline tipada.
- Seed mockado realista.
- Testes unitários da base.

## Próxima ordem recomendada

### 1. Repositórios locais

Criar repositórios específicos para:

- Viagens.
- Pacientes.
- Passageiros.
- Abastecimentos.
- Ocorrências.
- Comprovantes.
- Avisos.
- Fila offline.

### 2. Tela de rota de ida

Usar os modelos novos para:

- Lista de paradas.
- Pacientes.
- Acessibilidade.
- Ausência/desistência.
- Eventos offline.

### 3. Espera e reembarque

Implementar:

- Estado `em_espera`.
- Tempo de espera.
- Reembarque de retorno.
- Validação de pacientes embarcados ou justificados.

### 4. Encerramento

Implementar:

- KM final.
- Cálculo de KM rodado.
- Divergência de KM.
- Total de despesas.
- Pacientes transportados.
- Ocorrências.

### 5. Sincronização futura

Evoluir:

- `logistica_sync_items`.
- Tentativas.
- Erros.
- Reenvio.
- Contrato de API futuro.

## Entregas já concluídas

- Etapa 2: viagens atribuídas, preparação e check-in de saída.
- Etapa 3: base técnica de modelos, estados e banco local.

## Pendências do MVP

- Telas de rota.
- Telas de espera.
- Telas de retorno.
- Encerramento real.
- Captura de comprovantes.
- Registro visual de abastecimentos.
- Registro visual de ocorrências.
- Painel de pendências de sync baseado em `logistica_sync_items`.
