import 'dart:ui';

import 'package:flutter/material.dart';

import '../widgets/intro_shared.dart';
import 'signin.dart';
import 'signup.dart';

/// Página estabilizada após o loading ([Intro]).
///
/// Corresponde ao frame "Intro2" do Figma (390×844):
/// - Imagem de fundo com blur (390×586, y=31)
/// - Logo MovieTime no topo (x=136, y=114)
/// - Título "Entertainment made easy." + subtítulo
/// - Dois botões: "Watching now" (gradiente) e "Sign up" (outline)
class Intro2 extends StatelessWidget {
  const Intro2({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          final transform = DesignTransform.fromSize(size);

          return SizedBox(
            width: size.width,
            height: size.height,
            child: Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.none,
              children: [
                // Fundo preto base
                const ColoredBox(color: Color(0xFF0D0D0D)),

                // Imagem de fundo com blur (390×586, y=31)
                Positioned(
                  left: transform.mapX(0),
                  top: transform.mapY(31),
                  child: Transform.scale(
                    scale: transform.scale,
                    alignment: Alignment.topLeft,
                    child: ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                      child: Image.asset(
                        'assets/images/f87d8559b051e037278ee52175df4f0ceb0616668d8ee129263fa27addf0f2c0.png',
                        width: 390,
                        height: 586,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),

                // Logo MovieTime (x=136, y=114)
                Positioned(
                  left: transform.mapX(136),
                  top: transform.mapY(114),
                  child: Transform.scale(
                    scale: transform.scale,
                    alignment: Alignment.topLeft,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 27.29,
                          height: 27.29,
                          child: IntroLogoMark(),
                        ),
                        SizedBox(width: 8.69),
                        MovieTimeLabel(),
                      ],
                    ),
                  ),
                ),

                // Carrossel de imagens (Frame 2147224303, x=0, y=202, 390×220)
                // Posicionamento absoluto idêntico ao Figma: retângulos laterais
                // se estendem para fora do frame (clipsContent: false).
                // Clip.hardEdge corta o conteúdo que sai sem reportar overflow.
                Positioned(
                  left: transform.mapX(0),
                  top: transform.mapY(202),
                  child: Transform.scale(
                    scale: transform.scale,
                    alignment: Alignment.topLeft,
                    child: SizedBox(
                      width: 390,
                      height: 220,
                      child: Stack(
                        clipBehavior: Clip.hardEdge,
                        children: [
                          // Retângulo esquerdo (Rectangle 395045) - x=-333.96, overlay 40%
                          Positioned(
                            left: -333.96,
                            top: 0,
                            child: _CarouselImage(
                              image:
                                  'assets/images/rectangle-395045-fc8f71de.png',
                              width: 352.25,
                              height: 220,
                              overlayOpacity: 0.4,
                            ),
                          ),
                          // Retângulo central (Rectangle 395043) - x=33.29, y=9, destaque
                          Positioned(
                            left: 33.29,
                            top: 9,
                            child: _CarouselImage(
                              image:
                                  'assets/images/rectangle-395043-573e42d4.png',
                              width: 323.43,
                              height: 202,
                              overlayOpacity: 0,
                            ),
                          ),
                          // Retângulo direito (Rectangle 395044) - x=371.71, overlay 50%
                          Positioned(
                            left: 371.71,
                            top: 0,
                            child: _CarouselImage(
                              image:
                                  'assets/images/rectangle-395044-cd287cf5.png',
                              width: 352.25,
                              height: 220,
                              overlayOpacity: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Conteúdo central (x=24, y=483, 342×316)
                Positioned(
                  left: transform.mapX(24),
                  top: transform.mapY(483),
                  child: Transform.scale(
                    scale: transform.scale,
                    alignment: Alignment.topLeft,
                    child: SizedBox(
                      width: 342,
                      height: 316,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Título + subtítulo
                          SizedBox(
                            height: 157,
                            child: Column(
                              children: [
                                Text(
                                  'O entretenimento ficou mais fácil',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 40,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w500,
                                    height: 1.2,
                                    letterSpacing: 0,
                                  ),
                                ),
                                SizedBox(height: 10),
                                Text(
                                  'Descubra filmes e programas ilimitados, ao seu alcance',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Color(0xFF9E9E9E),
                                    fontSize: 16,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w500,
                                    height: 1.5,
                                    letterSpacing: 0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 44),
                          // Botões
                          SizedBox(
                            height: 115,
                            child: Column(
                              children: [
                                _GradientButton(
                                  label: 'Watching now',
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => const SignIn(),
                                      ),
                                    );
                                  },
                                ),
                                SizedBox(height: 15),
                                _OutlineButton(
                                  label: 'Cadastre-se',
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => const SignUp(),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Botão primário com gradiente roxo e sombra (42:797).
class _GradientButton extends StatelessWidget {
  const _GradientButton({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFA259FF), Color(0xFF562199)],
        ),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: const Color(0xFFC49EFF), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33A259FF),
            blurRadius: 10,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(40),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
                height: 1.57,
                letterSpacing: 0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Botão secundário com contorno roxo (42:798).
class _OutlineButton extends StatelessWidget {
  const _OutlineButton({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: const Color(0xFFA259FF), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(40),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFFA259FF),
                fontSize: 14,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
                height: 1.57,
                letterSpacing: 0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Imagem do carrossel com overlay escuro opcional (2623:1135/1136/1137).
///
/// Usa o caminho vetorial do "Rectangle 395043" (a imagem ativa): borda
/// superior e inferior com leve curva interna (pico ~9.65px do topo e
/// ~8.65px da base), em vez de um retângulo de cantos retos.
class _CarouselImage extends StatelessWidget {
  const _CarouselImage({
    required this.image,
    required this.width,
    required this.height,
    required this.overlayOpacity,
  });

  final String image;
  final double width;
  final double height;
  final double overlayOpacity;

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: const _CurvedPosterClipper(),
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(image, fit: BoxFit.cover),
            if (overlayOpacity > 0)
              ColoredBox(
                color: Color(0xFF0D0D0D).withValues(alpha: overlayOpacity),
              ),
          ],
        ),
      ),
    );
  }
}

/// Recorta a imagem no formato do vetor "Rectangle 395043".
///
/// O vetor do Figma é curvo: a aresta do topo desce suavemente até ~9.65%
/// da altura no centro e a da base sobe até ~95.72%, com as duas extremidades
/// terminando nos cantos 0/1. Aqui o caminho é normalizado para caber em
/// qualquer tamanho.
class _CurvedPosterClipper extends CustomClipper<Path> {
  const _CurvedPosterClipper();

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;

    // Ponto de controle relativo da forma original (323.427×390).
    const topDip = 9.646 / 202.0; // ≈ 0.0478
    const bottomDip = 193.354 / 202.0; // ≈ 0.9572

    final path = Path()
      ..moveTo(0, 0)
      // Topo: de (0,0) → (161.7, 9.65) com curva, control points em (55.6,9.65).
      ..cubicTo(
        0,
        0,
        (55.6056 / 323.427) * w,
        topDip * h,
        0.5 * w,
        topDip * h,
      )
      // Topo: (161.7, 9.65) → (323.4, 0).
      ..cubicTo(
        (267.82 / 323.427) * w,
        topDip * h,
        w,
        0,
        w,
        0,
      )
      // Lateral direita.
      ..lineTo(w, h)
      // Base: de (323.4, 202) → (161.7, 193.35) com curva.
      ..cubicTo(
        w,
        h,
        (262.71 / 323.427) * w,
        bottomDip * h,
        0.5 * w,
        bottomDip * h,
      )
      //canto: (161.7, 193.35) → (0, 202).
      ..cubicTo(
        (60.71 / 323.427) * w,
        bottomDip * h,
        0,
        h,
        0,
        h,
      )
      ..lineTo(0, 0)
      ..close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
