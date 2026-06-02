# Roadmap Logística - 3 Meses

## Objetivo

Organizar a evolução do módulo Logística para um MVP profissional de transporte sanitário em três meses, sem reescrever o módulo atual e sem depender de backend para o funcionamento local.

## Princípios

- Preservar a demo atual.
- Trabalhar apenas Logística nesta fase.
- Evoluir por incrementos pequenos e testáveis.
- Priorizar o fluxo real do motorista.
- Registrar tudo offline primeiro.
- Preparar sincronização futura sem bloquear uso local.
- Separar MVP de versão 2.0.

## Mês 1 - Fundação operacional

### Semana 1 - Modelagem e máquina de estados

Objetivo:

- Criar a base técnica do fluxo sequencial da viagem.

Entregas:

- Modelo de estados da viagem.
- Mapeamento entre status atual e status sanitário.
- Eventos mínimos por transição.
- Validações locais iniciais.
- Planejamento de migração do banco.

Arquivos prováveis:

- `modules/logistica/lib/modules/transportes/models/viagem_status.dart`
- `modules/logistica/lib/modules/transportes/models/viagem_model.dart`
- `modules/logistica/lib/motorista/viagem_atual/`
- `modules/logistica/lib/database/database_helper.dart`

Risco:

- Médio, pois altera a interpretação de status.

Critério de aceite:

- Fluxo de estados documentado em código.
- Estados antigos ainda compatíveis.
- Nenhum módulo fora de Logística alterado.

### Semana 2 - Viagens do dia e preparação

Objetivo:

- Melhorar a tela inicial operacional do motorista.

Entregas:

- Lista de viagens do dia.
- Origem e destino principal.
- Número de pacientes.
- Indicador de acessibilidade.
- Prioridade da viagem.
- Botão `Iniciar Preparação`.

Arquivos prováveis:

- `modules/logistica/lib/motorista/home/motorista_home_page.dart`
- `modules/logistica/lib/motorista/minhas_viagens/minhas_viagens_page.dart`
- `modules/logistica/lib/motorista/minhas_viagens/minhas_viagens_controller.dart`
- `modules/logistica/lib/modules/transportes/repositories/transportes_repository.dart`

Risco:

- Baixo a médio.

Critério de aceite:

- Motorista entende claramente qual viagem deve executar.
- Viagens continuam disponíveis offline.

### Semana 3 - Check-in de saída

Objetivo:

- Garantir saída segura com KM e checklist.

Entregas:

- Tela de preparação.
- KM de saída obrigatório.
- Checklist pré-uso.
- Horário automático.
- Confirmação de veículo e motorista.
- Bloqueio local sem KM e checklist.

Arquivos prováveis:

- `modules/logistica/lib/motorista/viagem_atual/`
- `modules/logistica/lib/database/database_helper.dart`
- `modules/logistica/lib/motorista/eventos/`

Risco:

- Médio, pois cria gargalo obrigatório antes da viagem.

Critério de aceite:

- Não inicia viagem sem KM inicial e checklist.
- Evento fica salvo offline.

### Semana 4 - Rota de ida e passageiros

Objetivo:

- Executar a ida com paradas, pacientes e ocorrências básicas.

Entregas:

- Lista ordenada de paradas.
- Lista de pacientes por parada.
- Botão para Waze/Google Maps.
- Confirmar desembarque.
- Paciente ausente/desistiu.
- Alerta visual de acessibilidade.

Arquivos prováveis:

- `modules/logistica/lib/motorista/passageiros/`
- `modules/logistica/lib/motorista/viagem_atual/`
- `modules/logistica/lib/modules/transportes/models/passageiro_model.dart`

Risco:

- Médio.

Critério de aceite:

- Passageiro pode ser marcado como embarcado, ausente e desembarcado.
- Necessidade especial fica visível na viagem.

## Mês 2 - Retorno, encerramento e auditoria

### Semana 5 - Espera

Objetivo:

- Registrar o período de espera do motorista.

Entregas:

- Estado `em_espera`.
- Cronômetro de espera.
- Lista de horários de consulta.
- Botão para despesa/abastecimento.
- Alerta local de espera prolongada.

Risco:

- Médio.

Critério de aceite:

- Tempo de espera fica registrado e auditável.

### Semana 6 - Reembarque de retorno

Objetivo:

- Garantir controle dos pacientes no retorno.

Entregas:

- Lista de pacientes.
- Checkbox para embarcado.
- Opção `não retornou/justificado`.
- Foto de comprovante.
- Regra impedindo retorno sem todos marcados ou justificados.

Risco:

- Médio.

Critério de aceite:

- Volta só inicia com todos os pacientes tratados.

### Semana 7 - Rota de volta

Objetivo:

- Controlar desembarque final e rota de retorno.

Entregas:

- Lista de desembarque.
- Botão `Desembarque Concluído`.
- Navegação externa.
- Botão de pânico simples.

Risco:

- Médio.

Critério de aceite:

- Todos os desembarques finais ficam registrados offline.

### Semana 8 - Encerramento

Objetivo:

- Encerrar a viagem com resumo, KM e auditoria.

Entregas:

- KM final obrigatório.
- Resumo da viagem.
- Total de KM.
- Total de despesas.
- Pacientes transportados.
- Ocorrências.
- Validação de KM final.
- Marcação de pendência de revisão de KM.

Risco:

- Alto, pois concentra regras de auditoria.

Critério de aceite:

- Não encerra com KM final menor que KM inicial.
- Divergência absurda gera revisão, sem bloquear emergência.

## Mês 3 - Despesas, ocorrências, sincronização e perfil

### Semana 9 - Abastecimentos e despesas

Objetivo:

- Registrar custos da viagem.

Entregas:

- Tela de abastecimento/despesa.
- Posto/local.
- Tipo.
- Litros.
- Valor.
- Foto do cupom.
- Valor por litro.
- Custo por km.
- Custo por paciente.

Risco:

- Médio.

Critério de aceite:

- Despesa fica vinculada à viagem, veículo e motorista.

### Semana 10 - Ocorrências e pânico

Objetivo:

- Estruturar eventos críticos de rota.

Entregas:

- Ocorrências tipadas.
- Foto opcional.
- Status de sincronização.
- Botão de pânico simples.
- Evento `PANICO`.
- Mensagem de notificação futura da central.

Risco:

- Médio a alto por envolver localização e urgência operacional.

Critério de aceite:

- Botão de pânico salva evento local e entra na fila de sincronização.

### Semana 11 - Sincronização pendente e avisos

Objetivo:

- Dar clareza ao motorista sobre pendências offline.

Entregas:

- Card verde/amarelo/vermelho.
- Contagem de eventos pendentes.
- Botão `Forçar sincronização`.
- Tela de avisos da central com dados mock/local.

Risco:

- Médio.

Critério de aceite:

- Motorista entende quando há pendências e erros.

### Semana 12 - Perfil, histórico e estabilização

Objetivo:

- Fechar o MVP com histórico básico e revisão geral.

Entregas:

- Perfil do motorista.
- Veículo atual.
- Viagens realizadas.
- KM acumulado.
- Abastecimentos.
- Ocorrências.
- Botão sair.
- Testes de navegação e fluxo principal.

Risco:

- Baixo a médio.

Critério de aceite:

- MVP consegue demonstrar uma viagem sanitária completa offline.

## O que cabe no MVP de 3 meses

- Viagem do dia.
- Preparação.
- KM inicial.
- Checklist pré-uso.
- Rota de ida.
- Acessibilidade.
- Paciente ausente/desistente.
- Comprovante por foto.
- Espera.
- Reembarque.
- Rota de volta.
- Encerramento com KM final.
- Abastecimentos/despesas.
- Ocorrências tipadas.
- Botão de pânico simples.
- Sincronização pendente visual.
- Perfil/histórico básico.
- Avisos mockados/local.

## O que deve ficar para versão 2.0

- GPS intensivo de emergência a cada 3 a 5 segundos.
- Assinatura digital completa.
- Material/carga sanitária com QR Code/código de barras.
- Roteirização avançada.
- Chat completo com central.
- Regras complexas de conflito entre app e central.
- Dashboard web real.
- Integração com ACS, ACE e IA.

## Gargalos obrigatórios

### Alteração de rota com motorista offline

- App deve manter rota atual local.
- Quando voltar internet, deve baixar alterações pendentes.
- Central futura deve mostrar `alteração pendente de recebimento`.
- App deve confirmar `rota atualizada`.

### Divergência de KM

- Validar localmente KM final maior que KM inicial.
- Se KM destoar muito do esperado, marcar como pendente de revisão.
- Não bloquear encerramento em emergência.
- Registrar evento de auditoria.

### Espera prolongada

- Se `em_espera` passar do horário previsto mais tolerância, registrar alerta local.
- Futuramente enviar alerta para central.

## Métricas de sucesso

- Percentual de viagens concluídas com KM inicial/final.
- Percentual de viagens com checklist pré-uso.
- Quantidade de eventos pendentes.
- Tempo médio em espera.
- Despesas por km.
- Despesas por paciente.
- Ocorrências por tipo.
- Viagens com necessidade especial atendida.
