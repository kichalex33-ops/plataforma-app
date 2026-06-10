# Fase 10 - Correcao de pre-homologacao

## Objetivo

Esta fase remove pontos de simulacao do caminho padrao do aplicativo e prepara o app para homologacao com o painel/servidor real, sem reescrever telas existentes.

## Autenticacao

- O login normal passa a usar `POST /api/driver/login`.
- O app espera receber dados do usuario/motorista, permissoes, modulos autorizados e token de sessao.
- A sessao autenticada e gravada em armazenamento seguro com `flutter_secure_storage`.
- Senhas fixas e usuarios fixos nao fazem parte do fluxo padrao de producao.
- Alteracao de senha usa `POST /api/driver/change-password` com token Bearer.

## GOD MODE

- O GOD MODE fica indisponivel por padrao.
- Em producao (`APP_ENV=producao`) o GOD MODE fica bloqueado mesmo se houver senha configurada.
- Para teste interno fora de producao, o build precisa informar:
  - `GOD_MODE_ENABLED=true`
  - `GOD_MODE_PASSWORD=<senha temporaria>`
- Nao existe senha GOD MODE fixa no codigo de producao.

## Sessao segura

Arquivos principais:

- `lib/core/auth/secure_session_storage.dart`
- `lib/core/auth/auth_api_service.dart`
- `lib/core/auth/panel_auth_service.dart`

Dados armazenados:

- usuario autenticado;
- token;
- refresh token, quando enviado pela API.

Nao sao armazenados:

- senha;
- CPF completo em logs;
- segredo fixo de API.

## Fila offline

- A fila principal de sincronizacao foi movida de `SharedPreferences` para SQLite.
- A tabela criada e `core_sync_queue_items`.
- Eventos continuam sendo gravados localmente antes de qualquer tentativa de envio.
- Falhas de conexao nao apagam dados locais.
- Itens com conflito HTTP 409 ficam marcados com erro `CONFLITO`.
- Reenvio possui limite controlado de tentativas.

Arquivos principais:

- `lib/core/sync/repositories/sqlite_sync_queue_repository.dart`
- `lib/core/sync/services/api_sync_dispatcher.dart`
- `lib/core/sync/services/sync_queue_service.dart`

## Dispatcher de sincronizacao

O dispatcher envia itens para a API conforme o tipo:

- GPS: `/api/driver/locations`
- Eventos operacionais: `/api/driver/events`
- Operacoes genericas: `/api/driver/sync`

O envio usa token Bearer da sessao segura.

## Ambientes

### Desenvolvimento

Usado para testes locais com o notebook/servidor na rede:

```bash
flutter run --dart-define=APP_ENV=dev --dart-define=API_BASE_URL=http://10.0.0.4:3000
```

### Homologacao

Deve apontar para endpoint de teste real. Pode habilitar ferramentas internas, mas nunca mascarar simulacao como producao.

### Producao

Exige HTTPS:

```bash
flutter build apk --release --dart-define=APP_ENV=producao --dart-define=API_BASE_URL=https://seu-dominio
```

## Testes adicionados/ajustados

- Login via API fake injetada.
- Sessao segura em memoria.
- Alteracao de senha via API.
- GOD MODE bloqueado por padrao.
- GOD MODE bloqueado em producao.
- Fila SQLite persistente.
- Reenvio com maximo de tentativas.
- Conflito de sincronizacao sem perda de payload.

## Pendencias para o backend

- Confirmar contrato final de `POST /api/driver/login`.
- Confirmar contrato de `POST /api/driver/change-password`.
- Confirmar endpoint generico `/api/driver/sync`.
- Padronizar payload de eventos enviados para `/api/driver/events`.
- Padronizar retorno de conflitos com HTTP 409.
- Implementar refresh token, caso seja exigido em producao.
