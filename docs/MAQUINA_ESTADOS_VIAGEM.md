# Máquina de Estados da Viagem

## Objetivo

Definir o fluxo sequencial da viagem sanitária no módulo Logística, garantindo que o motorista registre as etapas essenciais mesmo offline, com validações locais e eventos preparados para sincronização futura.

## Estado atual

O módulo Logística atual usa uma lista simples de status:

- `rascunho`
- `agendada`
- `em_andamento`
- `concluida`
- `cancelada`

Esse modelo é suficiente para uma viagem genérica, mas ainda não representa o fluxo sanitário completo de saída, ida, espera, retorno, encerramento, auditoria e sincronização.

## Estados planejados para o MVP

## Estados implementados na etapa 2

A etapa 2 implementa o início operacional da viagem:

- `aguardando`
- `preparacao`
- `saida_confirmada`
- `em_transito_ida`

O fluxo local agora registra preparação, confirma saída com validações obrigatórias e cria evento de início da rota de ida. A persistência utiliza `status_operacional` em `transportes_viagens`, registros em `viagem_preparacoes` e eventos na fila offline.

### `aguardando`

Viagem atribuída ao motorista, ainda não iniciada.

Entrada:

- Viagem recebida do painel futuro.
- Viagem criada localmente para teste.

Saídas permitidas:

- `preparacao`
- `erro_sincronizacao`, somente em contexto de sincronização.

Dados mínimos:

- Origem.
- Destino principal.
- Data/hora prevista.
- Motorista.
- Veículo, quando disponível.
- Lista de pacientes, quando disponível.

### `preparacao`

Motorista iniciou a preparação da viagem.

Entrada:

- Botão `Iniciar Preparação`.

Saídas permitidas:

- `saida_confirmada`
- `aguardando`, se preparação for cancelada antes da saída.

Validações:

- KM de saída deve ser informado.
- Checklist pré-uso deve ser preenchido.
- Motorista e veículo devem estar confirmados.
- Implementado na etapa 2 por `ViagemPreparacaoService.validarSaida`.

### `saida_confirmada`

Saída liberada localmente.

Entrada:

- Botão `Confirmar Saída`.

Saídas permitidas:

- `em_transito_ida`
- `pendente_sincronizacao`

Eventos:

- `checklist_saida_confirmado`
- `saida_confirmada`
- `km_saida_registrado`
- Implementado na etapa 2 como evento offline `saida_confirmada`, contendo KM inicial e checklist no payload.

### `em_transito_ida`

Veículo está em deslocamento para consultas, exames ou destino principal.

Entrada:

- Início da rota de ida.

Saídas permitidas:

- `em_espera`
- `reembarque_retorno`, quando não houver espera formal.
- `finalizacao`, em viagem sem retorno ou encerramento excepcional.

Ações:

- Confirmar desembarque.
- Registrar paciente ausente/desistente.
- Abrir Waze ou Google Maps.
- Registrar ocorrência.
- Acionar botão de pânico simples.

### `em_espera`

Motorista está aguardando consultas, exames ou liberação dos pacientes.

Entrada:

- Desembarque de ida concluído.

Saídas permitidas:

- `reembarque_retorno`
- `finalizacao`, em caso excepcional justificado.

Ações:

- Cronômetro de espera.
- Registrar abastecimento/despesa.
- Registrar ocorrência.
- Registrar alerta de espera prolongada.

Regra:

- Se o tempo de espera ultrapassar o horário previsto mais tolerância, criar alerta local.

### `reembarque_retorno`

Motorista está confirmando pacientes para retorno.

Entrada:

- Botão `Iniciar Reembarque de Retorno`.

Saídas permitidas:

- `em_transito_volta`
- `em_espera`, se retorno ainda não puder iniciar.

Validações:

- Todos os pacientes devem estar marcados como embarcados ou justificados.
- Paciente sem retorno deve ter justificativa.

### `em_transito_volta`

Veículo está no trajeto de retorno/desembarque final.

Entrada:

- Reembarque validado.

Saídas permitidas:

- `finalizacao`

Ações:

- Confirmar desembarque.
- Abrir navegação externa.
- Registrar ocorrência.
- Acionar botão de pânico simples.

### `finalizacao`

Motorista está encerrando a viagem.

Entrada:

- Rota de volta concluída.
- Encerramento excepcional justificado.

Saídas permitidas:

- `concluida`
- `pendente_sincronizacao`

Validações:

- KM final obrigatório.
- KM final não pode ser menor que KM inicial.
- Divergência absurda de KM não deve bloquear emergência, mas deve marcar a viagem como pendente de revisão.

### `concluida`

Viagem encerrada localmente com todos os registros mínimos.

Entrada:

- Encerramento validado.

Saídas permitidas:

- `pendente_sincronizacao`
- `sincronizada`

Dados de resumo:

- Horário de saída.
- Horário de retorno.
- Total de KM.
- Total de despesas.
- Pacientes transportados.
- Ocorrências.
- Revisão de KM, se houver.

### `pendente_sincronizacao`

Viagem ou eventos aguardam envio.

Entrada:

- Qualquer evento registrado offline.
- Encerramento local sem confirmação remota.

Saídas permitidas:

- `sincronizada`
- `erro_sincronizacao`

Ações:

- Mostrar contador de eventos pendentes.
- Permitir `Forçar sincronização`.

### `sincronizada`

Todos os eventos obrigatórios foram enviados e confirmados.

Entrada:

- Confirmação da fila de sincronização futura.

Saídas permitidas:

- Nenhuma no fluxo normal.

### `erro_sincronizacao`

Falha no envio de um ou mais eventos.

Entrada:

- Erro de API.
- Falha de rede.
- Conflito de versão.

Saídas permitidas:

- `pendente_sincronizacao`
- `sincronizada`, após reenvio bem-sucedido.

## Eventos mínimos por transição

| Transição | Evento local | Obrigatório |
| --- | --- | --- |
| `aguardando -> preparacao` | `preparacao_iniciada` | Sim |
| `preparacao -> saida_confirmada` | `saida_confirmada` | Sim |
| `saida_confirmada -> em_transito_ida` | `rota_ida_iniciada` | Sim |
| `em_transito_ida -> em_espera` | `ida_concluida` | Sim |
| `em_espera -> reembarque_retorno` | `reembarque_iniciado` | Sim |
| `reembarque_retorno -> em_transito_volta` | `retorno_iniciado` | Sim |
| `em_transito_volta -> finalizacao` | `volta_concluida` | Sim |
| `finalizacao -> concluida` | `viagem_concluida` | Sim |
| qualquer estado operacional -> `pendente_sincronizacao` | `evento_pendente_sync` | Automático |
| `pendente_sincronizacao -> sincronizada` | `sync_confirmado` | Automático |
| `pendente_sincronizacao -> erro_sincronizacao` | `sync_falhou` | Automático |

## Regras críticas

### KM

- KM inicial é obrigatório antes da saída.
- KM final é obrigatório no encerramento.
- KM final não pode ser menor que KM inicial.
- Diferença de KM muito acima do previsto deve marcar `pendente_revisao_km`.
- Em emergência, não bloquear encerramento; registrar auditoria.

### Checklist

- Checklist pré-uso é obrigatório para confirmar saída.
- Checklist pós-uso pode entrar no encerramento como evolução do MVP.

### Passageiros

- Não iniciar volta sem todos os pacientes embarcados ou justificados.
- Passageiro ausente/desistente deve gerar ocorrência.
- Paciente com acessibilidade deve gerar alerta visual.

### Offline

- Toda transição deve ser salva localmente.
- Cada evento deve receber `sync_status = pending`.
- A tela deve seguir funcionando sem backend.

### Alteração de rota offline

- O app mantém a rota atual local.
- Ao voltar conexão, deve buscar alterações pendentes.
- A central futura deve ver `alteração pendente de recebimento`.
- O app deve confirmar `rota atualizada` quando receber a nova rota.

## Compatibilidade com status atuais

Mapeamento inicial recomendado:

| Status atual | Novo estado sugerido |
| --- | --- |
| `rascunho` | `aguardando` |
| `agendada` | `aguardando` |
| `em_andamento` | estado operacional mais recente salvo em eventos |
| `concluida` | `concluida` ou `pendente_sincronizacao` |
| `cancelada` | manter fora do fluxo principal, com motivo e auditoria |

## Critério de aceite da máquina de estados

- O motorista não consegue confirmar saída sem KM inicial e checklist.
- O motorista não consegue iniciar retorno sem marcar todos os pacientes.
- O motorista não consegue encerrar com KM final menor que KM inicial.
- O app registra eventos mesmo offline.
- A viagem mostra claramente o estado atual.
- Erros de sincronização não impedem o uso local.
