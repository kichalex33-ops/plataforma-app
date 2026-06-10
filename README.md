# Plataforma Logistica

Aplicativo mobile Flutter para operacao logistica municipal, com foco em transporte sanitario, viagens, motoristas, veiculos, passageiros, checklists, ocorrencias, comprovantes e sincronizacao offline-first.

## Escopo Atual

- App mobile Flutter.
- Modulo ativo: Logistica.
- Login unico por usuario cadastrado no painel.
- Roteamento por perfil para a area logistica permitida.
- Base preparada para inclusao futura de novos modulos, sem dependencias ativas de outros dominios.

## Autenticacao

O app usa login unico integrado ao painel/servidor:

- primeiro acesso por `Parear com QR Code`;
- QR confirma `POST /api/driver/pairing/confirm`;
- `POST /api/driver/login`
- sessao/token em armazenamento seguro;
- roteamento por perfil e permissao;
- sem usuarios ou senhas fixas no fluxo padrao de producao.

O GOD MODE fica bloqueado por padrao e nao possui senha fixa no codigo. Fora de producao, testes internos exigem `GOD_MODE_ENABLED=true` e `GOD_MODE_PASSWORD` informado no build.

## Minhas Viagens

A tela **Minhas viagens** mostra apenas viagens atribuidas ao motorista pela plataforma. Quando nao houver viagem recebida do painel, o comportamento esperado e exibir:

`Nenhuma viagem atribuida`

O app nao cria viagens falsas automaticamente em producao.

## Homologacao

Para testar o fluxo operacional antes da plataforma enviar viagens reais, existe um seed opcional de homologacao. Ele fica desligado por padrao:

```dart
DEMO_SEED_ENABLED = false
```

Para ativar os dados locais de teste:

```powershell
C:\flutter\bin\flutter.bat run --dart-define=DEMO_SEED_ENABLED=true
```

## Como Rodar

Servidor local de desenvolvimento:

```powershell
git clone https://github.com/kichalex33-ops/plataforma-app.git
cd plataforma-app
C:\flutter\bin\flutter.bat pub get
C:\flutter\bin\flutter.bat run --dart-define=APP_ENV=dev --dart-define=API_BASE_URL=http://10.0.0.4:3000
```

Homologacao com URL publica:

```powershell
C:\flutter\bin\flutter.bat run --dart-define=APP_ENV=homologacao --dart-define=API_BASE_URL=https://homologacao.seudominio.com
```

Producao:

```powershell
C:\flutter\bin\flutter.bat run --dart-define=APP_ENV=producao --dart-define=API_BASE_URL=https://api.seudominio.com
```

## Integracao com Servidor

O app nao depende de IP fixo em producao. A URL da API deve ser informada por `API_BASE_URL`.

Em producao, `APP_ENV=producao` exige `API_BASE_URL` com HTTPS.

Rotas principais usadas pelo app:

- `GET /api/status`
- `POST /api/driver/pairing/confirm`
- `POST /api/driver/login`
- `POST /api/driver/change-password`
- `POST /api/driver/sync`
- `POST /api/driver/events`
- `POST /api/driver/locations`
- `GET /api/driver/trips?motorista_id=...`
- `GET /api/driver/notices`
- `POST /api/driver/trips/:id/checklist`
- `POST /api/driver/trips/:id/km-inicial`
- `POST /api/driver/trips/:id/flow`
- `POST /api/driver/trips/:id/finalizar`
- `POST /api/driver/panic`
- `POST /api/driver/proofs`
- `GET /api/viagens`
- `GET /api/motoristas`
- `GET /api/veiculos`
- `GET /api/pacientes`
- `GET /api/viagens/:id/passageiros`

## Validacao

```powershell
C:\flutter\bin\flutter.bat pub get
C:\flutter\bin\dart.bat analyze --no-fatal-warnings
C:\flutter\bin\flutter.bat test
```
