# Roadmap - Plataforma Territorial Integrada de Saude Municipal

## Visao

Evoluir o ACE de um aplicativo de campo para uma plataforma operacional municipal offline-first, integrando vigilancia, transporte sanitario, pacientes, farmacia, mapas, rastreamento e sincronizacao multi-dispositivo.

## Fase 1 - Base modular offline

Objetivo: criar a fundacao sem quebrar o ACE existente.

- Auditoria tecnica.
- Estrutura modular em `lib/modules`.
- Migrations iniciais para transportes, pacientes, farmacia, dashboard, sync e mapa territorial.
- Navegacao inicial para novos modulos.
- Dashboard local com indicadores basicos.
- Modelos principais com UUID, timestamps, municipio e `sync_status`.
- Base generica de sync e logs locais.
- Compatibilidade com SQLite existente.

## Fase 2 - Operacao territorial municipal

- Cadastro de pacientes territoriais com geolocalizacao.
- Cadastro de motoristas, veiculos, viagens e passageiros.
- Cadastro de medicamentos, estoque, validade e movimentacoes.
- Camadas ativaveis no mapa: focos, pacientes, rotas, unidades e veiculos.
- Indicadores locais por municipio, unidade e perfil.
- Permissoes locais por papel: ACE, ACS, Motorista, Coordenador, Administrador, Farmacia e Gestao.

## Fase 3 - Sincronizacao distribuida

- Sync incremental por entidade e municipio.
- Download de alteracoes do servidor.
- Resolucao inicial de conflitos por `updated_at`, `version` e prioridade de papel.
- Retry com backoff.
- Logs auditaveis de sync.
- Integridade por checksum.
- Contrato HTTP versionado com backend Node.js.

## Fase 4 - Backend municipal

- Node.js com banco persistente.
- Autenticacao e autorizacao.
- Painel web municipal.
- API por municipio.
- Recebimento de fila offline.
- Exportacoes oficiais.
- Auditoria administrativa.

## Fase 5 - Inteligencia operacional

- Roteirizacao.
- Clusters e heatmaps.
- Historico temporal territorial.
- Alertas de vencimento de medicamentos.
- Alertas de pacientes prioritarios.
- Monitoramento de veiculos.
- Relatorios para gestao.

## Regras permanentes

- Toda operacao salva primeiro no SQLite.
- Internet nunca e pre-requisito para registro em campo.
- Entidades novas usam UUID local.
- Entidades novas usam `created_at`, `updated_at` e `sync_status`.
- Nenhuma tabela antiga sera removida sem migration de compatibilidade.
- Modulos novos devem separar dados, servicos, controladores e UI.
