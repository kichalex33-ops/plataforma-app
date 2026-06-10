# Pareamento QR do Motorista

## Fluxo operacional

1. Operador cadastra o motorista no painel.
2. Painel gera um QR Code de pareamento para o motorista/dispositivo.
3. Motorista abre o app e toca em `Parear com QR Code`.
4. App le o QR Code, confirma o token no servidor e grava o servidor/login pareado.
5. Painel retorna login e senha inicial gerados.
6. App preenche login e senha inicial, e o motorista toca em `Entrar`.
7. O login normal chama `POST /api/driver/login`.
8. Apos login valido, a sessao/token fica salva em armazenamento seguro.

## Formatos aceitos pelo QR

JSON:

```json
{
  "token": "token-pareamento",
  "server_url": "http://10.0.0.4:3000",
  "pairing_id": "id-opcional"
}
```

URL:

```text
plataforma-logistica://pair?token=token-pareamento&server_url=http://10.0.0.4:3000
```

Token puro:

```text
token-pareamento
```

## Endpoint esperado

`POST /api/driver/pairing/confirm`

Payload enviado pelo app:

```json
{
  "token": "token-pareamento",
  "pairing_id": "id-opcional",
  "platform": "android"
}
```

Resposta esperada:

```json
{
  "ok": true,
  "data": {
    "login": "motorista.login",
    "senha_inicial": "senha-gerada-no-painel",
    "server_url": "http://10.0.0.4:3000"
  },
  "message": "Aparelho pareado com sucesso."
}
```

Resposta opcional com sessao imediata:

```json
{
  "ok": true,
  "data": {
    "login": "motorista.login",
    "senha_inicial": "senha-gerada-no-painel",
    "token": "jwt",
    "refresh_token": "refresh",
    "motorista": {
      "id": "motorista-1",
      "nome": "Nome do Motorista",
      "login": "motorista.login",
      "municipio": "Municipio",
      "funcao": "Motorista",
      "perfil": "motorista",
      "modulos_permitidos": ["logistica"],
      "ativo": true,
      "primeiro_acesso": true
    }
  }
}
```

## Regras de seguranca

- O app nao cria usuario local.
- O app nao grava a senha inicial em armazenamento seguro.
- O app grava apenas servidor pareado, login pareado e sessao/token apos login valido.
- QR expirado, cancelado ou invalido deve retornar erro HTTP 400/401/410.
- O servidor deve invalidar o token de pareamento apos uso.

## Arquivos do app

- `lib/screens/login_demo_page.dart`
- `lib/screens/qr_pairing_screen.dart`
- `lib/core/auth/driver_pairing_service.dart`
- `lib/core/auth/secure_session_storage.dart`
- `lib/core/auth/auth_api_service.dart`
