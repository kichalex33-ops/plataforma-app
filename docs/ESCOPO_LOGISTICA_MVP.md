# Escopo do MVP Logística

## Objetivo

Transformar o módulo Logística da demo em um app profissional de transporte sanitário, mantendo a base atual reaproveitada da Logística e evoluindo por etapas para um fluxo sequencial de viagem, operação offline-first, controle de pacientes, frota, despesas, auditoria e sincronização futura com uma central.

Nesta etapa, este documento define o planejamento técnico. Não há implementação de código neste ciclo.

## Escopo desta etapa

- Trabalhar apenas o módulo Logística.
- Não alterar ACE, ACS, IA ou backend.
- Não reescrever o módulo interno.
- Não trocar a arquitetura da demo.
- Preservar o login `Alex / 1234` e a tela de seleção de módulos.
- Documentar o MVP, as lacunas e a ordem de implementação.

## Base atual identificada

O módulo Logística copiado para `modules/logistica` já possui uma fundação importante:

- Banco local SQLite em `modules/logistica/lib/database/database_helper.dart`.
- Tabelas de viagens, motoristas, veículos e passageiros.
- Tabelas de pacientes, rastreamento de viagem, mensagens e checklists.
- Fila local de sincronização `sync_queue`.
- Logs de sincronização e auditoria.
- Tela de login própria do motorista dentro do módulo original.
- Tela inicial do motorista em `motorista/home/motorista_home_page.dart`.
- Tela de viagens atribuídas em `motorista/minhas_viagens/minhas_viagens_page.dart`.
- Tela de detalhe da viagem em `motorista/viagem_atual/viagem_detalhe_page.dart`.
- Tela de passageiros por viagem em `motorista/passageiros/passageiros_viagem_page.dart`.
- Registro local de eventos operacionais em `motorista/eventos`.
- Painel de sincronização do motorista.
- API client preparado para endpoints futuros.

## Funcionalidades que já existem

### Etapa 2 implementada

- Tela de viagens atribuídas com origem, destino principal, prioridade, tipo visual, pacientes, acompanhantes, acessibilidade, status e botão `Iniciar Preparação`.
- Tela de preparação da viagem com motorista logado, veículo, lista de pacientes, acompanhantes, necessidades especiais, observações da central e checklist pré-uso.
- Check-in de saída com horário automático, KM inicial obrigatório, checklist obrigatório e botão `Confirmar Saída`.
- Salvamento local da preparação em `viagem_preparacoes`.
- Atualização local da viagem com `status_operacional`, `km_saida` e `horario_saida_confirmada`.
- Geração de eventos offline para `preparacao_iniciada`, `saida_confirmada` e `rota_ida_iniciada`.
- Testes unitários para carregamento lógico da viagem, preparação, validações de saída e transição de estado.

### Etapa 5 implementada

- Checklist pré-uso configurável no fluxo de check-in, com itens de veículo, documentação, equipamentos e saúde.
- Checklist pós-uso obrigatório antes do encerramento da viagem.
- Tela de abastecimento com posto, litros, valor total, foto do cupom, observação e cálculo de valor por litro.
- Registro de despesas gerais para pedágio, estacionamento, alimentação autorizada, manutenção emergencial e outro.
- Tela de ocorrências tipadas, com descrição, horário automático, localização descritiva e foto opcional.
- Botão de pânico criando ocorrência local, horário, localização quando disponível e item de fila offline com mensagem para a central.
- Captura local de comprovante SUS por passageiro/paciente, permitindo múltiplas fotos e campo preparado para assinatura digital futura.
- Paciente ausente ou desistente passa a ser retirado do retorno por status `nao_retornou` e gera ocorrência automática.
- Histórico da viagem com abas para checklists, despesas, ocorrências, comprovantes e eventos de sincronização.
- Auditoria local para criação de checklists, despesas, ocorrências e comprovantes.
- Testes cobrindo checklist obrigatório, abastecimento, custo por km, custo por paciente, paciente ausente, ocorrência, pânico e comprovantes.

### Login e sessão do motorista

- Existe fluxo de login no módulo original.
- A demo principal já autentica com `Alex / 1234` antes de abrir os módulos.
- O módulo Logística possui modelo de motorista e sessão local.

### Viagens atribuídas

- Existe tela `MinhasViagensPage`.
- A tela lista viagens por motorista.
- Exibe origem, destino, horário, status, finalidade e status de sincronização.
- Permite abrir o detalhe da viagem.

### Detalhe da viagem

- Existe tela `ViagemDetalhePage`.
- Exibe resumo da rota, status, motorista, veículo e observações.
- Possui ações operacionais genéricas:
  - Aceitar viagem.
  - Iniciar viagem.
  - Ver passageiros.
  - Registrar ocorrência.
  - Encerrar viagem.

### Passageiros

- Existe tela `PassageirosViagemPage`.
- Lista passageiros vinculados à viagem.
- Exibe origem de embarque, destino de desembarque, necessidade especial e observações.
- Permite registrar:
  - Embarque confirmado.
  - Chegada confirmada.
  - Passageiro ausente.
  - Observação rápida.

### Offline-first inicial

- Existe banco local.
- Existem registros com `sync_status`.
- Existe fila `sync_queue`.
- Existem eventos operacionais locais.
- Existe painel de sincronização.

### Auditoria e sincronização

- Existem tabelas de auditoria e logs de sincronização.
- Existem repositórios para fila de sincronização e eventos.
- Existem endpoints futuros configurados no client de API.

## Funcionalidades faltantes para o MVP sanitário

### Máquina de estados profissional

O status atual é simples:

- `rascunho`
- `agendada`
- `em_andamento`
- `concluida`
- `cancelada`

O MVP deve evoluir para:

- `aguardando`
- `preparacao`
- `saida_confirmada`
- `em_transito_ida`
- `em_espera`
- `reembarque_retorno`
- `em_transito_volta`
- `finalizacao`
- `concluida`
- `pendente_sincronizacao`
- `sincronizada`
- `erro_sincronizacao`

### Check-in de saída

Implementado na etapa 2:

- KM de saída obrigatório.
- Checklist pré-uso estruturado.
- Validação impedindo início sem KM inicial e checklist.
- Registro automático do horário de saída.
- Confirmação explícita de veículo e motorista.
- Persistência offline e evento na fila local.

### Rota de ida

Faltam:

- Lista ordenada de paradas.
- Botão para Waze ou Google Maps.
- Confirmação de desembarque por paciente/parada.
- Registro formal de paciente ausente ou desistente.
- Botão de pânico simples nas telas de rota.

### Acessibilidade

Hoje existe o campo genérico `necessidade_especial`. O MVP deve separar:

- Cadeirante.
- Usa muletas.
- Dificuldade de locomoção.
- Acompanhante.
- Observações de embarque.
- Alerta visual quando houver necessidade especial.

### Comprovante de presença

Implementado na etapa 5:

- Registro local de foto/caminho do comprovante ou canhoto.
- Vinculação do comprovante ao paciente.
- Vinculação do comprovante à viagem.
- Estrutura preparada para assinatura digital futura.

### Status de espera

Faltam:

- Tela específica `Em Espera`.
- Cronômetro de espera.
- Lista de horários de consulta.
- Registro rápido de abastecimento ou despesa durante espera.
- Alerta de espera prolongada.

### Reembarque de retorno

Faltam:

- Lista de pacientes para retorno.
- Checkbox de embarque.
- Justificativa para paciente que não retornou.
- Regra impedindo volta sem todos os pacientes marcados como embarcados ou justificados.

### Rota de volta

Faltam:

- Lista de desembarque.
- Botão `Desembarque Concluído`.
- Navegação externa.
- Botão de pânico simples.

### Encerramento

Faltam:

- KM final obrigatório.
- Cálculo de total de KM.
- Resumo da viagem.
- Total de despesas.
- Total de pacientes transportados.
- Lista de ocorrências.
- Validação de KM final maior que KM inicial.
- Marcação de divergência de KM como pendente de revisão.

### Abastecimentos e despesas

Implementado na etapa 5:

- Viagem.
- Veículo.
- Motorista.
- Posto/local.
- Tipo.
- Litros.
- Valor.
- Foto do cupom.
- Observação.
- Cálculo de valor por litro.
- Cálculo de custo por km.
- Cálculo de custo por paciente.

### Ocorrências

Implementado na etapa 5 com tipos:

- Paciente ausente.
- Desistência.
- Pane mecânica.
- Pneu furado.
- Acidente.
- Paciente passou mal.
- Emergência.
- Atraso.
- Pânico.
- Outro.

Cada ocorrência registra horário, descrição, foto opcional, localização quando disponível e status de sincronização.

### Botão de pânico simples

Implementado na etapa 5:

- Botão vermelho acessível nas telas de rota.
- Evento `PANICO`.
- Horário.
- Localização, se disponível.
- Entrada na fila de sincronização.
- Mensagem: `Central será notificada quando houver conexão`.

### Sincronização pendente

Já existe base de sync, mas falta uma visualização operacional simples:

- Verde: tudo sincronizado.
- Amarelo: pendências.
- Vermelho: erro de envio.
- Botão `Forçar sincronização`.
- Contagem de eventos pendentes.

### Perfil e histórico do motorista

Faltam:

- Veículo atual.
- Viagens realizadas.
- KM acumulado.
- Abastecimentos.
- Ocorrências.
- Botão sair contextual ao perfil.

### Avisos da central

Existe tabela de mensagens, mas falta tela operacional:

- Lista de avisos recebidos.
- Título.
- Mensagem.
- Data/hora.
- Prioridade.
- Fonte mock/local nesta fase.

## MVP de 3 meses

Cabe no MVP:

- Máquina de estados local.
- Viagens atribuídas do dia com prioridade e acessibilidade.
- Check-in de saída com KM inicial e checklist.
- Rota de ida com passageiros, ausências, desembarque e navegação externa.
- Estado de espera com cronômetro.
- Reembarque de retorno com validação.
- Rota de volta e desembarque.
- Encerramento com KM final, resumo, despesas e ocorrências.
- Abastecimento/despesa básica.
- Ocorrências tipadas.
- Botão de pânico simples.
- Card de sincronização pendente.
- Perfil/histórico básico do motorista.
- Avisos da central mockados/local.

## Versão 2.0

Deve ficar para a versão 2.0:

- Modo emergência avançado com GPS a cada 3 a 5 segundos.
- Assinatura digital completa na tela.
- QR Code/código de barras para material/carga sanitária.
- Confirmação central em tempo real.
- Reotimização automática de rota.
- Chat completo base/motorista.
- Painel web real integrado.
- Sincronização completa com resolução de conflitos no backend.
- Integração com ACS, ACE e IA operacional.

## Riscos técnicos

- Evoluir a máquina de estados sem quebrar status existentes.
- Garantir migração segura do banco local.
- Evitar duplicidade de eventos em modo offline.
- Validar KM sem bloquear encerramentos de emergência.
- Tratar imagens de comprovante/cupom sem aumentar demais o banco local.
- Manter compatibilidade com dados mockados e futuros dados de API.
- Isolar erros de sincronização para não travar o fluxo do motorista.
- Definir claramente quais eventos são obrigatórios antes de cada transição.

## Ordem de implementação recomendada

1. Atualizar modelos e banco local para viagem sanitária.
2. Criar máquina de estados e validações.
3. Implementar tela de viagens do dia.
4. Implementar check-in de saída.
5. Implementar rota de ida e passageiros.
6. Implementar espera e reembarque.
7. Implementar rota de volta e encerramento.
8. Implementar abastecimentos/despesas.
9. Implementar ocorrências e botão de pânico.
10. Implementar painel simples de sincronização pendente.
11. Implementar perfil/histórico do motorista.
12. Implementar avisos da central mockados.
