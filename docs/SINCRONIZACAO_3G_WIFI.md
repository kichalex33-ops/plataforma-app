# Sincronizacao 3G, 4G e Wi-Fi

## Objetivo

O app mobile da Plataforma Logistica deve funcionar com servidor local em desenvolvimento, URL publica em homologacao e HTTPS obrigatorio em producao.

## Configuracao por ambiente

Desenvolvimento local:

```powershell
C:\flutter\bin\flutter.bat run --dart-define=APP_ENV=dev --dart-define=API_BASE_URL=http://10.0.0.4:3000
```

Homologacao:

```powershell
C:\flutter\bin\flutter.bat run --dart-define=APP_ENV=homologacao --dart-define=API_BASE_URL=https://homologacao.seudominio.com
```

Producao:

```powershell
C:\flutter\bin\flutter.bat run --dart-define=APP_ENV=producao --dart-define=API_BASE_URL=https://api.seudominio.com
```

## Regras

- `APP_ENV=dev` pode usar HTTP local.
- `APP_ENV=homologacao` deve usar URL publica configurada.
- `APP_ENV=producao` exige HTTPS.
- Falhas de conexao devem retornar lista vazia, `null` ou `false`, sem quebrar o app.
- Tokens futuros devem ser enviados no cabecalho `Authorization: Bearer`.

## Build release

APK local para teste no servidor do notebook:

```powershell
C:\flutter\bin\flutter.bat build apk --release --dart-define=APP_ENV=dev --dart-define=API_BASE_URL=http://10.0.0.4:3000
```

APK de producao:

```powershell
C:\flutter\bin\flutter.bat build apk --release --dart-define=APP_ENV=producao --dart-define=API_BASE_URL=https://api.seudominio.com
```
