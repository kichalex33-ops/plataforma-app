# Plano de Melhorias da Demo

## Estado Atual

- A demo abre com identidade Andrade Gestão em Saúde.
- Login normal `Alex / 1234` libera a seleção de módulos.
- God Mode `Alexkich / @l3xk1cH` abre animação especial antes da seleção.
- A seleção exibe os módulos Logística e ACE.
- Os fluxos internos dos módulos foram preservados.
- A Logística já possui documentação de MVP, roadmap, dados e máquina de estados.

## Etapa 1.1 — Identidade Visual Andrade e God Mode

Objetivo:

- Padronizar visualmente a demo com a marca Andrade, sem alterar regras de negócio.

Entregas:

- Tema global em `lib/core/theme/`.
- Assets da marca em `assets/images/` e `assets/icons/`.
- Ícones Android atualizados em `android/app/src/main/res/mipmap-*`.
- Login com logo Andrade, fundo azul acinzentado e detalhes dourados.
- Seleção de módulos com cards institucionais.
- God Mode com animação MVP.
- Indicador discreto `God Mode` na seleção.
- Documentação em `docs/IDENTIDADE_VISUAL_ANDRADE.md`.

Risco:

- Baixo, pois a etapa altera aparência e fluxo de entrada, sem tocar nas regras internas.

## Etapa 2 — Logística operacional

Objetivo:

- Evoluir o módulo Logística para transporte sanitário offline-first.

Documentos:

- `docs/ESCOPO_LOGISTICA_MVP.md`
- `docs/ROADMAP_LOGISTICA_3_MESES.md`
- `docs/MAQUINA_ESTADOS_VIAGEM.md`
- `docs/PLANO_DADOS_LOGISTICA.md`

Prioridade:

- Alta.

## Etapa 3 — ACE preservado

Objetivo:

- Manter o ACE funcional e visualmente consistente, sem redesenho profundo.

Prioridade:

- Média.

## Etapa 4 — Unificação real futura

Objetivo:

- Preparar login real, perfis, permissões, banco único, sincronização, ACS e IA operacional.

Prioridade:

- Futura.
