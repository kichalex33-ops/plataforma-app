# Analise da referencia LogiSaude

Data: 2026-05-27

## Arquivos analisados

- `ARQUIVOS_E_TERMOS_PARA_REMOVER.md`
- `REFATORACAO_LOGISAUDE.md`
- `database_platform.dart`
- `logisaude_database.dart`
- Projeto `controle_ace.rar` em `C:\Users\endem\OneDrive\Desktop\projeto`

## O que e util para o projeto

- A lista de termos a remover e util como checklist de limpeza do dominio ACE/endemia.
- O arquivo `logisaude_database.dart` e util como modelo de banco limpo para uma futura migracao de `DatabaseHelper` para `LogiSaudeDatabase`.
- A ideia de trocar `controle_ace.db` por `logisaude.db` e correta para evitar heranca conceitual do app antigo.
- A tabela `rastreamento_viagem` e altamente relevante para rastreio GPS real.
- As tabelas `usuarios`, `alertas_operacionais`, `regioes_logisticas` e `pontos_referencia_logistica` sao boas candidatas para a proxima fase.
- A regra de usar apenas `sync_queue` como padrao unico de sincronizacao deve ser adotada gradualmente.
- A orientacao de senha com hash e salt deve substituir o armazenamento local legado.

## O que nao deve ser copiado diretamente

- O `controle_ace.rar` de referencia e uma versao ACE antiga, com PE, visitas PE, BTI e ovitrampas. Isso nao deve voltar para o app logistico.
- O banco `logisaude_database.dart` nao foi copiado inteiro agora para evitar quebrar telas e repositories ja conectados ao `DatabaseHelper`.
- As tabelas antigas epidemiologicas ainda existentes no codigo herdado devem ser removidas por etapas, com migracao controlada.

## O que foi incorporado agora

- O modulo de Transportes recebeu fluxo mais completo de passageiros.
- A aba de Transportes agora tem quatro areas:
  - Viagens;
  - Motoristas;
  - Veiculos;
  - Passageiros.
- O cadastro de passageiro grava:
  - nome;
  - local de embarque;
  - destino;
  - necessidade especial.
- Se nao houver viagem cadastrada, o app cria automaticamente uma viagem local `UBS Centro -> destino informado`.
- A operacao continua offline-first: salva no SQLite e entra na `sync_queue`.

## Proximos passos recomendados

1. Criar `LogiSaudeDatabase` como banco novo em paralelo, sem apagar o banco atual de uma vez.
2. Migrar `ace_profiles` para `usuarios`.
3. Migrar `alertas_emergencia` para `alertas_operacionais`.
4. Criar tabela real `rastreamento_viagem` no banco atual ou migrar para o banco LogiSaude.
5. Remover imports e telas antigas de PE, BTI, ovitrampa, LIRA/LIA e risco epidemiologico.
6. Trocar senha local por hash com salt.
7. Padronizar sync apenas por `sync_queue`.

## Decisao arquitetural

A referencia e util como roteiro de refatoracao, mas o projeto atual deve absorver as ideias por etapas. A prioridade imediata continua sendo uma experiencia logistica funcional: viagens, passageiros, motorista, veiculo, rastreio e central de controle.
