# AuditAgent

## Objetivo

O `AuditAgent` centraliza o registro de eventos importantes do app, mantendo auditoria local mesmo quando o aparelho esta offline.

## Eventos auditados

- abertura do app;
- login;
- logout;
- inicio de viagem;
- conclusao de viagem;
- alteracao de status;
- checklist iniciado;
- checklist concluido;
- ocorrencia registrada;
- acesso aos indicadores;
- atualizacao dos indicadores;
- acesso aos relatorios;
- geracao de relatorio;
- tentativa de sincronizacao;
- sincronizacao concluida;
- falha de sincronizacao;
- sincronizacao ignorada por falta de conexao.

## Estrutura do log

Cada `AuditLog` possui:

- `id`;
- `type`;
- `severity`;
- `description`;
- `origin`;
- `entityType`;
- `entityId`;
- `metadataJson`;
- `syncStatus`;
- `createdAt`.

## Regras de privacidade

O servico de auditoria remove dados sensiveis antes de persistir logs:

- senha;
- password;
- token;
- CPF completo;
- chaves de metadados contendo dados sensiveis.

O objetivo e permitir diagnostico operacional sem expor credenciais ou documentos pessoais desnecessarios.

## Persistencia

A Fase 9 usa repositario local baseado em `SharedPreferences`, com alternativa em memoria para testes.

## Filtros disponiveis

- periodo inicial;
- periodo final;
- tipo de evento;
- severidade.

## Limitacoes atuais

- Sem envio dos logs ao servidor.
- Sem exportacao PDF.
- Sem criptografia dedicada dos logs locais.
- Sem retencao automatica por prazo.

## Proximos passos

- Integrar auditoria local com fila de sincronizacao quando a API oficial estiver pronta.
- Adicionar retencao configuravel.
- Adicionar assinatura/imutabilidade de logs criticos.
- Criar exportacao controlada para auditoria municipal.
