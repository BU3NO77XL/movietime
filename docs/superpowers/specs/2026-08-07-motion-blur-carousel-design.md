# Design — Motion blur carrossel na Intro2

Data: 2026-08-07

## Objetivo

Transformar o carrossel de pôsteres da tela `Intro2` (390×220, `lib/screens/intro2.dart`)
de um `Stack` fixo (3 pôsteres: 1 central em destaque + 2 laterais) em um carrossel
animado em **loop contínuo** com **motion blur real** no deslizamento, preservando
o estilo visual atual (pôsteres curvos, overlays escuros, posições e dimensões).

## Contexto atual

- `lint/screens/intro2.dart` (Linhas 80-136): `Positioned` dentro de um `Stack`
  com 3 `_CarouselImage`:
  - Esquerda: `x=-333.96`, 352.25×220, overlay 0.4
  - Centro: `x=33.29`, `y=9`, 323.43×202, overlay 0
  - Direita: `x=371.71`, 352.25×220, overlay 0.5
- Cada pôster usa `_CurvedPosterClipper` (bordas superior/inferior curvas,
  normalizado para tamanho) + overlay `0x0D0D0D`.
- Imagens: `rectangle-395045-fc8f71de.png`, `rectangle-395043-573e42d4.png`,
  `rectangle-395044-cd287cf5.png`.

## Abordagem escolhida (aprovada pelo usuário)

Abordagem 1: faixa contínua em loop + pacote `motion_blur`.

## Dependências

- `motion_blur: ^0.0.2` (MIT, baseado em shader GLSL).
- Registrar o shader em `pubspec.yaml`:

```yaml
flutter:
  shaders:
    - packages/motion_blur/shaders/motion_blur.glsl
```

## Componentes / arquitetura

1. `Intro2` passa a ser um `StatefulWidget` (`_Intro2State` com
   `SingleTickerProviderStateMixin`).
2. `AnimationController` roda em loop contínuo (`..repeat()`), duração de ~8s.
   O valor `0..1` mapeia um deslocamento horizontal infinito da faixa de pôsteres.
3. A faixa é montada com as **mesmas 3 imagens repetidas 2×** (6 pôsteres),
   espaçadas de forma que o deslocamento contínuo revele
   continuamente o próximo pôster à direita e retorne ao início sem salto
   (wrap perfeito quando a faixa anda exatamente o tamanho do ciclo).
   Centrado: cada pôster é envolvido em `RepaintBoundary` para evitar
   revamp/re-rasterização quando o posicionamento se repete.
4. Cada pôster mantém o estilo atual:
   - `_CurvedPosterClipper` (clip curvado por pôster).
   - Overlay escuro: central sem overlay, laterais 0.4/0.5.
   - Mesmas dimensões: 352.25×220 (laterais), 323.43×202 (central).
5. `MotionBlur` (do pacote) envolve o pôster em movimento; o shader calcula
   o blur a partir do deslocamento entre o frame atual e o anterior.
   - requer `MotionBlur` ao redor do widget em movimento;
   - o blur não pode pintar além do tamanho do filho → é necessário padding
     lateral no widget em movimento (`padding: EdgeInsets.only(left/right: ~60px)`)
     dentro do `MotionBlur` para o efeito não ser cortado.

## Detalhes de comportamento

- Loop automático (sem interação do usuário), conforme decisão do usuário.
- O carrossel não bloqueia a interação com o restante da tela (sem gestos).
- Duração: ~8s por ciclo do loop (configurável para visual review).

## Plano de implementação

1. Adicionar `motion_blur` e o shader no `pubspec.yaml`.
2. Transformar `Intro2` em `StatefulWidget`.
3. Criar widget interno `_MotionCarousel` (faixa + controlador + `MotionBlur`).
4. Substituir o `Stack` estático de 3 pôsteres pelo `_MotionCarousel`.
5. `flutter analyze` e `flutter run` para validar visualmente.