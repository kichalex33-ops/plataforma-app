# SPEC Fase 1 - Offline-First

## Objetivo da Fase 1

A Fase 1 tem como objetivo estabilizar a base operacional offline do app Plataforma Territorial Epidemiológica.

Nesta fase, o app deve permitir que o ACE registre dados de campo sem internet, mantenha tudo salvo localmente no SQLite e sincronize posteriormente com o servidor municipal quando houver rede disponível.

## Estado Atual da Sincronização

O app já possui uma base funcional de sincronização, ainda em evolução.

Existem dois mecanismos convivendo:

- colunas legadas de sincronização em tabelas operacionais;
- fila `sync_queue` para entidades sincronizáveis mais novas.

As colunas legadas usadas em várias tabelas são:

```text
sincronizado
sincronizado_em
erro_sincronizacao
```

A fila `sync_queue` é usada para transportar eventos/alterações de entidades com UUID e metadados de dispositivo.

## Arquivos Envolvidos

Banco local:

```text
lib/database/database_helper.dart
```

Serviço de sincronização legado e configuração do servidor:

```text
lib/services/sync_service.dart
```

Processamento da fila de sincronização:

```text
lib/services/sync_manager.dart
```

Repositório da fila:

```text
lib/repositories/sync_queue_repository.dart
```

Identificação local do dispositivo:

```text
lib/services/device_id_service.dart
```

Tela de transparência operacional da sincronização:

```text
lib/screens/sync_center_page.dart
```

Configuração do endereço do servidor:

```text
lib/screens/server_config_page.dart
```

## Tabela sync_queue

A tabela `sync_queue` registra operações pendentes de envio ao servidor.

Campos esperados:

```text
id
entity_type
entity_id
operation
payload
checksum
status
retry_count
device_id
version
created_at
updated_at
last_attempt_at
error_message
```

A fila possui índice por status para facilitar busca de registros pendentes, falhos ou em processamento.

## Statuses de Sincronização

Statuses previstos:

```text
pending
processing
synced
failed
conflict
```

Significado operacional:

- `pending`: aguardando envio.
- `processing`: envio em andamento.
- `synced`: enviado com sucesso.
- `failed`: falha no envio, aguardando nova tentativa.
- `conflict`: conflito detectado, aguardando resolução futura.

## Servidor Configurável

O endereço do servidor é configurável no app e salvo localmente.

Servidor padrão documentado para esta fase:

```text
http://10.0.0.3:3000
```

O app deve continuar funcionando mesmo quando esse servidor estiver desligado, fora da rede ou inacessível.

## Central de Sincronização

A Central de Sincronização deve dar transparência operacional ao usuário.

Ela deve mostrar:

- status do servidor;
- endereço do servidor;
- última sincronização;
- quantidade de registros `pending`;
- quantidade de registros `synced`;
- quantidade de registros `failed`;
- quantidade de registros `conflict`;
- botão para sincronizar agora;
- botão para reenviar falhas;
- lista resumida das operações recentes.

## Critérios de Validação

Para considerar a Fase 1 estável:

- O app abre normalmente sem internet.
- O login/perfil local funciona sem internet.
- PE pode ser criado offline.
- Visita PE pode ser registrada offline.
- Visita domiciliar pode ser registrada offline.
- BTI pode ser registrado offline.
- Ovitrampa pode ser registrada offline.
- LIRA/LIA pode ser registrado offline.
- Mapa territorial continua abrindo.
- Central de Sincronização mostra pendências.
- Ao voltar a rede, registros pendentes podem ser enviados.
- Falha de servidor não trava o app.
- Reiniciar o app não apaga a fila local.

## Riscos Conhecidos

- Existem dois mecanismos de sync convivendo: colunas legadas e `sync_queue`.
- Nem todos os módulos usam a `sync_queue` ainda.
- Algumas tabelas antigas ainda usam `INTEGER AUTOINCREMENT`.
- Algumas entidades sincronizáveis novas já usam UUID, mas nem todos os módulos antigos foram migrados.
- Fotos são salvas localmente por caminho de arquivo; o envio/visualização no servidor ainda precisa ser validado em campo.
- OpenStreetMap usa tiles online; sem internet, o mapa pode depender do cache do aparelho.
- O servidor local precisa estar acessível na mesma rede ou por conexão configurada.
- O tratamento de conflitos ainda é inicial.

## Testes Manuais Recomendados

1. Criar PE offline.
2. Editar PE offline, quando a tela permitir edição.
3. Registrar visita PE offline.
4. Registrar visita domiciliar offline.
5. Registrar BTI offline.
6. Registrar ovitrampa offline.
7. Criar registro LIRA/LIA offline.
8. Reiniciar o app e verificar se os dados continuam salvos.
9. Reiniciar o app e verificar se a fila/pendências continuam visíveis.
10. Alternar servidor online/offline.
11. Sincronizar depois de religar o servidor.
12. Verificar que PE, BTI, visitas, ovitrampas e mapa continuam funcionando após tentativa de sync.
13. Validar que falha de rede não trava o app.
14. Validar que a Central de Sincronização mostra falhas e permite nova tentativa.
