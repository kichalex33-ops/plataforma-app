# Identidade Visual Andrade

## Objetivo

Padronizar a demo com a identidade Andrade Gestão em Saúde, usando a marca enviada como referência principal, com visual institucional, fundo azul acinzentado escuro e detalhes dourados.

## Paleta

- Azul acinzentado: `#505674`
- Azul escuro: `#30364D`
- Azul profundo: `#20263A`
- Dourado: `#C9A96E`
- Dourado claro: `#F3E3B3`
- Fundo claro: `#F4F6FA`
- Branco/cards: `#FFFFFF`
- Texto forte: `#20263A`
- Texto secundário: `#6B7280`
- Erro/emergência: `#C62828`
- Sucesso/sincronizado: `#2E7D32`
- Pendente: `#E4A11B`

## Assets

Estrutura criada:

- `assets/images/andrade_logo.png`
- `assets/images/andrade_logo_horizontal.png`
- `assets/icons/app_icon.png`

O `pubspec.yaml` registra `assets/images/` e `assets/icons/`.

## Ícone do app

O ícone Android foi gerado a partir da marca Andrade e aplicado em:

- `android/app/src/main/res/mipmap-mdpi/ic_launcher.png`
- `android/app/src/main/res/mipmap-hdpi/ic_launcher.png`
- `android/app/src/main/res/mipmap-xhdpi/ic_launcher.png`
- `android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png`
- `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png`

## Telas atualizadas

- Login da demo.
- Seleção de módulos.
- Intro God Mode.
- Wrappers visíveis de Logística e ACE.
- Tokens de tema da cópia local de Logística.
- Tokens de tema da cópia local de ACE.

## Credenciais

Demo normal:

- Login: `Alex`
- Senha: `1234`

God Mode:

- Login: `Alexkich`
- Senha: `@l3xk1cH`

## God Mode

Ao autenticar com as credenciais God Mode, o app abre uma tela especial antes da seleção de módulos.

A animação MVP contém:

- Fundo azul acinzentado escuro.
- Logo Andrade com fade e scale.
- Linhas douradas animadas ao redor.
- Brilho/pulso dourado discreto.
- Texto `GOD MODE ATIVADO`.
- Texto `Acesso total liberado`.
- Navegação automática para seleção de módulos.

Limitação atual:

- A animação ainda não redesenha vetorialmente o símbolo Andrade traço por traço. Essa versão fica para uma etapa posterior.

## Próximos ajustes visuais

- Refinar splash screen nativa.
- Criar ícone adaptativo Android com foreground/background separados.
- Adicionar variações compactas da logo.
- Padronizar componentes compartilhados se a demo evoluir para app único real.
