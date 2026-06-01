# Plataforma Logistica Municipal

Aplicativo Flutter offline-first para operacao logistica municipal, com foco em transporte sanitario, pacientes, passageiros, rastreamento GPS e central de controle.

## Stack

- Flutter
- Dart
- SQLite/sqflite
- Node.js/Express no servidor local
- HTTP sync
- Operacao offline-first

## Modulos principais

- Painel logistico
- Transportes e viagens
- Motoristas
- Veiculos
- Passageiros e destinos
- Pacientes
- Rastreio GPS em tempo real
- Mapa de rota operacional
- Central de sincronizacao
- Auditoria

## Simulado operacional

O app inclui uma viagem simulada da UBS Centro ate um hospital de Porto Alegre. A tela mostra:

- posicao GPS progressiva do veiculo;
- lista de passageiros e destinos;
- experiencia do motorista;
- eventos salvos pelo app;
- acompanhamento pela central de controle.

## Offline-first

Toda operacao nova deve ser gravada primeiro no SQLite local. Quando houver rede, a fila `sync_queue` envia os registros para o servidor configurado.

Servidor padrao:

```text
http://10.0.0.3:3000
```

## Banco local

O banco principal segue em:

```text
lib/database/database_helper.dart
```

A versao 21 adiciona as tabelas logisticas:

- `transportes_motoristas`
- `transportes_veiculos`
- `transportes_viagens`
- `transportes_passageiros`
- `pacientes`
- `mapas_camadas`
- `sync_logs`

## Como validar

```bash
dart analyze
flutter test
```
