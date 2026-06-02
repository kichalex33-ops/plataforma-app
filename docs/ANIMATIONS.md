# Animações do App

## Objetivo

Centralizar a forma como o app executa animações premium de abertura e transições especiais, sem acoplar as telas aos formatos de arquivo.

## Arquivos

- `assets/animations/app_intro.mp4`
- `assets/animations/god_mode_activation.mp4`
- `lib/core/animations/animation_type.dart`
- `lib/core/animations/universal_animation_screen.dart`
- `lib/screens/app_intro_screen.dart`
- `lib/screens/god_mode_activation_screen.dart`

## Formatos Suportados

- MP4 por `video_player`
- Lottie por `lottie`
- Rive por `rive`

## Comportamento

- A abertura do app usa `app_intro.mp4`.
- A ativação do GOD MODE usa `god_mode_activation.mp4`.
- As telas são exibidas em modo imersivo.
- Ao terminar a animação, o fluxo chama `onFinished`.
- Se o vídeo falhar, o app mostra um fallback visual e continua o fluxo.
- O GOD MODE permite vibração e flash final.

## Regras

- Não colocar lógica de negócio dentro do player de animação.
- Não bloquear o app se um asset falhar.
- Manter os arquivos de animação em `assets/animations/`.
- Registrar novos assets no `pubspec.yaml`.

## Pendências Futuras

- Criar variações leves para aparelhos mais antigos.
- Permitir alternar animações por município ou ambiente.
- Adicionar testes visuais manuais em aparelho físico.
