# Plataforma Territorial Epidemiológica - AGENTS.md

**Versão:** 1.0.0  
**Última atualização:** 2026-05-26

## Missão

Este é um app Flutter offline-first para Agentes de Combate às Endemias.

O app deve funcionar em campo, inclusive sem internet, com dados salvos localmente e sincronização eventual com servidor municipal.

## Ambiente

- Flutter: >= 3.19.0
- Dart: >= 3.3.0
- sqflite: ^2.3.3
- uuid: ^4.5.1

## Estado atual do app

O app já possui:
- Dashboard
- Pontos Estratégicos
- Visitas domiciliares
- BTI
- Ovitrampas
- LIRA/LIA
- Mapa territorial
- Relatórios
- SQLite local

## Regra principal

Não reescrever o app inteiro.  
Evoluir incrementalmente.  
Preservar funcionalidades existentes.

## Arquitetura obrigatória

- SQLite local obrigatório
- Offline-first real
- Nenhum dado operacional depende do servidor para existir
- Toda operação salva localmente primeiro
- Sincronização é eventual
- SyncManager apenas transporta dados
- Regras de negócio ficam fora do SyncManager

## Identificadores

Entidades sincronizáveis devem usar UUID v4.

Não usar INTEGER AUTOINCREMENT em entidades sincronizáveis.

## Campos obrigatórios para entidades sincronizáveis

- id
- device_id
- version
- updated_at
- sync_status

## sync_status válidos

- pending
- processing
- synced
- failed
- conflict

## sync_queue

A sync_queue deve registrar operações pendentes de sincronização.

Campos esperados:
- id UUID
- entity_type
- entity_id
- operation
- payload
- checksum SHA256
- status
- retry_count
- device_id
- version
- created_at
- updated_at
- last_attempt_at
- error_message

A sync_queue deve ter índice em status para buscas rápidas.

## DeviceIdService

O device_id deve ser gerado uma única vez e persistido em SharedPreferences.

Não armazenar device_id apenas em memória.

## SyncManager

O SyncManager deve possuir método público:

```dart
processQueue()
```
