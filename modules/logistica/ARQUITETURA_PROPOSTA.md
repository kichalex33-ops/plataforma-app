# Arquitetura Proposta

## Principio central

O SQLite local e a fonte primaria de operacao. O backend futuro e um destino de sincronizacao, auditoria e consolidacao municipal, nao uma dependencia para trabalhar em campo.

## Estrutura modular

Cada modulo novo deve seguir:

```text
lib/modules/<modulo>/
  models/
  repositories/
  services/
  database/
  screens/
  widgets/
  controllers/
```

Modulos iniciais:

- `logistica`
- `transportes`
- `farmacia`
- `pacientes`
- `dashboard`
- `sync`
- `auth`
- `mapas_territoriais`

## Camadas

### Models

Representam entidades locais e fazem conversao simples para `Map<String, dynamic>`.

### Repositories

Responsaveis por ler e gravar no SQLite. Toda escrita nova deve:

1. gerar UUID local;
2. preencher `created_at` e `updated_at`;
3. salvar no SQLite;
4. enfileirar operacao na `sync_queue`;
5. retornar sucesso local mesmo sem internet.

### Services

Orquestram casos de uso tecnicos, como sync, GPS, calculo de indicadores e validacoes reutilizaveis.

### Controllers

Controlam estado das telas e chamam repositories/services.

### Screens e Widgets

Devem exibir e coletar dados. Logica de negocio deve ficar fora das telas sempre que possivel.

## Banco local

Manter o `DatabaseHelper` atual por compatibilidade, mas iniciar migracoes versionadas por modulo. A Fase 1 adiciona novas tabelas sem remover tabelas antigas.

Campos obrigatorios para entidades novas:

- `id TEXT PRIMARY KEY`
- `municipio_id TEXT NOT NULL`
- `created_at TEXT NOT NULL`
- `updated_at TEXT NOT NULL`
- `sync_status TEXT NOT NULL DEFAULT 'pending'`

Campos recomendados:

- `device_id TEXT`
- `version INTEGER NOT NULL DEFAULT 1`
- `observacoes TEXT`
- latitude/longitude quando houver territorio.

## Sync

O modelo alvo e uma fila generica:

- `pending`: aguardando envio.
- `processing`: envio em andamento.
- `synced`: enviado.
- `failed`: falhou e pode tentar novamente.
- `conflict`: conflito detectado para tratamento futuro.

Fluxo:

1. Repository salva no SQLite.
2. Repository adiciona item em `sync_queue`.
3. `SyncManager` tenta enviar quando acionado.
4. Falhas nao bloqueiam o uso local.
5. Logs locais registram tentativas e erros relevantes.

## Multi-municipio

Entidades novas carregam `municipio_id`. O login/perfil local atual pode continuar aceitando nome de municipio, mas a arquitetura deve preparar IDs estaveis para consolidacao futura.

## Mapa territorial

O modulo novo `mapas_territoriais` deve reaproveitar `lib/modules/mapa` e preparar:

- camadas ativaveis;
- clusters;
- heatmaps;
- rotas;
- unidades de saude;
- veiculos;
- historico temporal.

Na Fase 1, o mapa continua reaproveitando a tela existente e ganha um ponto de entrada modular.

## Permissoes

Preparar enum/contrato futuro para:

- ACE
- ACS
- Motorista
- Coordenador
- Administrador
- Farmacia
- Gestao

A aplicacao nao deve depender do servidor para permitir trabalho local do usuario autenticado previamente.
