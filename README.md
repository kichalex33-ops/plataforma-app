# Plataforma Logistica

Aplicativo mobile Flutter para operacao logistica municipal, com foco em transporte sanitario, viagens, motoristas, veiculos, passageiros, checklists, ocorrencias, comprovantes e sincronizacao offline-first.

## Escopo Atual

- App mobile Flutter.
- Modulo ativo: Logistica.
- Login unico por usuario cadastrado no painel.
- Roteamento por perfil para a area logistica permitida.
- Base preparada para inclusao futura de novos modulos, sem dependencias ativas de outros dominios.

## Credenciais de Teste

Usuarios simulados do painel:

- Login: `Alexk`, `Barbara` ou `Gilyan`
- Senha: `1234`
- Perfil: `MOTORISTA`
- Modulo: `Logistica`

GOD MODE:

- Login: `GODMODE`
- Senha: `app2026`

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

```powershell
git clone https://github.com/kichalex33-ops/plataforma-app.git
cd plataforma-app
C:\flutter\bin\flutter.bat pub get
C:\flutter\bin\flutter.bat run
```

## Integracao com Servidor

O app deve permanecer alinhado ao servidor localizado em:

```text
C:\dev\plataforma\app\server
```

Rotas principais usadas pelo app:

- `GET /api/status`
- `POST /api/driver/login`
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
