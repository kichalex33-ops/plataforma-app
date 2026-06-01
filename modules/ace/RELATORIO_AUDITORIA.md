# Relatorio de Auditoria - Projeto ACE

Data da auditoria: 2026-05-26

## 1. Estrutura atual

O projeto e um aplicativo Flutter multi-plataforma com Android, iOS, web, Windows, Linux e macOS. A base principal esta em `lib/`.

Estrutura funcional observada:

- `lib/main.dart`: entrada do app, dashboard principal, drawer, navegacao e boa parte da composicao da tela inicial.
- `lib/database/database_helper.dart`: criacao do SQLite, migrations, seeds, consultas e operacoes de escrita.
- `lib/models/`: modelos de ACE, PE, visitas, BTI, ovitrampas, quarteiroes, territorio e sync.
- `lib/screens/`: telas operacionais antigas, quase todas ligadas diretamente ao `DatabaseHelper`.
- `lib/repositories/`: repositorios mais novos para territorio operacional e fila de sync.
- `lib/services/`: GPS, tema, device id, sync legado e processamento da fila.
- `lib/modules/mapa/`: modulo territorial ja separado parcialmente.
- `servidor_corrigido/`: servidor Node.js local de apoio, em memoria.

Tambem existem artefatos empacotados junto ao projeto, como APKs e diretorios de build/cache. Eles nao devem guiar a arquitetura.

## 2. Arquitetura usada

A arquitetura atual e hibrida:

- Padrao Flutter tradicional com telas StatefulWidget.
- Persistencia SQLite local via `sqflite`.
- Offline-first parcial: registros sao salvos localmente antes da tentativa de envio.
- Sync legado por colunas `sincronizado`, `sincronizado_em`, `erro_sincronizacao`.
- Sync mais novo por `sync_queue`, com UUID, checksum, device_id, retry e status.
- Repositorios existem para parte territorial nova, mas muitos fluxos antigos ainda chamam `DatabaseHelper.instance` diretamente.

Nao ha uma Clean Architecture completa. O projeto esta em transicao entre uma arquitetura monolitica local e uma arquitetura modular.

## 3. Padroes existentes reutilizaveis

- Uso de SQLite como fonte primaria local.
- Uso de UUID em entidades territoriais novas.
- `sync_queue` com status `pending`, `processing`, `synced`, `failed` e preparo para `conflict`.
- `DeviceIdService` para identificacao local do aparelho.
- Repositorios territoriais com enfileiramento de sync.
- Separacao visual de cores/espacamentos em `core/theme`.
- Modulo de mapa ja iniciado em `lib/modules/mapa`.
- Tela de configuracao de servidor e central de sincronizacao.
- Persistencia de configuracoes em `app_config`.

## 4. Inconsistencias detectadas

- O servidor padrao no codigo esta como `http://10.10.11.52:3000`, enquanto a diretriz atual exige `http://10.0.0.3:3000`.
- Convivem dois contratos de sync: `sincronizado` numerico e `sync_status` textual.
- Parte das tabelas usa `INTEGER AUTOINCREMENT`; outra parte usa UUID em `TEXT PRIMARY KEY`.
- Nem todas as tabelas antigas possuem `created_at` e `updated_at`.
- Muitas telas contem logica de negocio, validacao e persistencia diretamente na UI.
- Nomes e textos aparecem com problema de codificacao em alguns pontos.
- Mapa usa tiles online do OpenStreetMap; offline completo depende de cache futuro.
- Fotos sao guardadas por caminho local, sem estrategia robusta de sincronizacao de arquivo.

## 5. Riscos arquiteturais

- `database_helper.dart` tem mais de 1600 linhas e acumula responsabilidades de migration, DAO, regra de negocio, seed e relatorio.
- `main.dart` tambem esta grande e concentra dashboard, navegacao e estado operacional.
- Sync legado envia tabela a tabela sem contrato generico de operacao.
- O servidor local atual usa memoria temporaria; nao e uma fonte confiavel para producao.
- Ausencia de controle de permissao por perfil, embora os papeis futuros estejam claros.
- Falta de estrategia formal de conflito entre dispositivos.
- Migracoes estao embutidas em `if (oldVersion < n)` no helper central, dificultando evolucao longa.

## 6. Duplicacoes

- Contadores e consultas de dashboard aparecem na UI.
- Normalizacao de payload por tabela fica concentrada no `SyncService`.
- Campos de sync e metadados aparecem em modelos novos, mas nao em todos os modelos antigos.
- Fluxos de cadastro repetem padroes de carregar configuracao, capturar GPS, inserir e tentar sync.
- Drawer, menu de modulos e bottom navigation repetem entradas de navegacao.

## 7. Problemas de sync/offline

- `reservarTubitos` depende do servidor para reserva global; em campo offline precisa de estrategia local com faixa pre-alocada ou reconciliacao.
- Nem todas as operacoes enfileiram `sync_queue`.
- Operacoes antigas marcam `sincronizado`, mas nao registram operacao, checksum, device_id ou retry granular.
- Falhas ficam por registro, porem sem logs historicos suficientes.
- Nao ha sync incremental de entrada vindo do servidor.
- Nao ha resolucao de conflito por `updated_at`, versao ou merge por entidade.

## 8. Acoplamentos perigosos

- UI acoplada diretamente a `DatabaseHelper.instance`.
- `SyncService` conhece detalhes de payload de muitas tabelas.
- Banco conhece modelos, seeds e operacoes de negocio.
- Mapa real chama banco diretamente e tambem cria ponto BTI.
- Autenticacao local e perfil ACE ainda estao no mesmo banco/configuracao operacional.

## 9. Pontos reutilizaveis

- SQLite local e migrations existentes.
- `sync_queue`, `SyncQueueRepository`, `SyncManager` e `DeviceIdService`.
- Modelos territoriais com `SyncFields`.
- `TerritorialMapPreview` e `MapaRealPage`.
- Tema visual centralizado.
- Central de sincronizacao e configuracao de servidor.
- Repositorios territoriais recentes como referencia para os novos modulos.

## 10. Divida tecnica prioritaria

1. Modularizar banco em migrations versionadas.
2. Migrar entidades novas para UUID, `created_at`, `updated_at` e `sync_status`.
3. Unificar sync em fila generica, mantendo compatibilidade com legado.
4. Extrair logica das telas para repositories/controllers.
5. Criar contrato de multi-municipio em todas as entidades novas.
6. Preparar papeis e permissoes sem bloquear uso offline.
7. Criar logs locais de sync.
8. Criar cache/estrategia offline para mapas.

## Decisao da Fase 1

A evolucao deve ser incremental. Nao sera removida nenhuma tabela antiga nesta etapa. Novos modulos serao criados com UUID, timestamps e `sync_status`, usando SQLite local como fonte primaria e `sync_queue` como base de sincronizacao futura.
