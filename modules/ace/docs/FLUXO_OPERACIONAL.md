# Fluxo Operacional

## 1. Criar viagem

O operador cria uma viagem com origem, destino e finalidade.

Estado inicial normal: `agendada`.

## 2. Adicionar passageiros

Todo passageiro deve ser vinculado a uma viagem.

Se nao existir viagem, o app pede confirmacao e cria uma viagem `rascunho`. Essa criacao nao e silenciosa.

## 3. Motorista

O motorista visualiza:

- viagem;
- origem;
- destino;
- passageiros;
- necessidade especial;
- status operacional.

## 4. Rastreio

No simulado atual, o app mostra a viagem UBS Centro ate Hospital de POA.

O rastreio e marcado na interface e no banco como `simulado`.

No rastreio real, cada ponto deve ser gravado com `origem_dado = gps_real`.

## 5. Central de controle

A central acompanha:

- status da viagem;
- linha do tempo;
- posicao GPS;
- passageiros;
- entrega no destino;
- pendencias de sincronizacao.

## 6. Sincronizacao

Toda operacao salva primeiro no SQLite.

Quando houver rede, a `sync_queue` envia as alteracoes para o servidor municipal.
