import 'dart:ui';

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

import '../widgets/intro_shared.dart';
import 'home.dart';

/// Tela "highlights" do Figma (390×844).
///
/// - Fundo preto #0d0d0d
/// - Imagem hero de fundo (390×612, blur 100) com overlay preto 50%
/// - Header com logo "MovieTime" + "Continuar >" à direita
/// - Título "Bem-vindo!" + subtítulo "Veja os destaques de hoje."
/// - Carousel horizontal com 3 cards de filme (central destacado)
/// - Indicador de página (barra + bolinhas)
class Highlights extends StatefulWidget {
  const Highlights({super.key});

  @override
  State<Highlights> createState() => _HighlightsState();
}

class _HighlightsState extends State<Highlights> {
  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: Scaffold(
        backgroundColor: const Color(0xFF0D0D0D),
        body: SafeArea(
          child: LayoutBuilder(
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

                    // Imagem hero de fundo (x=0, y=0, 390×612, blur 100)
                    // com overlay #0d0d0d 50%
                    Positioned(
                      left: transform.mapX(0),
                      top: transform.mapY(0),
                      child: Transform.scale(
                        scale: transform.scale,
                        alignment: Alignment.topLeft,
                        child: SizedBox(
                          width: 390,
                          height: 612,
                          child: ImageFiltered(
                            imageFilter: ImageFilter.blur(
                              sigmaX: 100,
                              sigmaY: 100,
                            ),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.asset(
                                  'assets/images/rectangle-395047-44b1c56e.png',
                                  fit: BoxFit.cover,
                                ),
                                // Overlay #0d0d0d 50%
                                const ColoredBox(color: Color(0x800D0D0D)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Header (Frame 61:5261, x=24, y=64, 342×27.29)
                    Positioned(
                      left: transform.mapX(24),
                      top: transform.mapY(64),
                      child: Transform.scale(
                        scale: transform.scale,
                        alignment: Alignment.topLeft,
                        child: SizedBox(
                          width: 342,
                          height: 27.29,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Logo MovieTime (ícone + texto)
                              const SizedBox(
                                width: 117.84,
                                height: 27.29,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    IntroLogoMark(),
                                    SizedBox(width: 8.69),
                                    // Texto "MovieTime" com "Movie" branco e
                                    // "Time" cinza #9e9e9e (Poppins 14.88)
                                    _MovieTimeBrand(),
                                  ],
                                ),
                              ),
                              // "Continuar >" à direita - navega para Home
                              GestureDetector(
                                onTap: () {
                                  Navigator.of(context).push(
                                    PageRouteBuilder(
                                      transitionDuration: const Duration(
                                        milliseconds: 450,
                                      ),
                                      reverseTransitionDuration: const Duration(
                                        milliseconds: 450,
                                      ),
                                      pageBuilder: (_, _, _) => const Home(),
                                      transitionsBuilder:
                                          (
                                            _,
                                            animation,
                                            secondaryAnimation,
                                            child,
                                          ) {
                                            return SharedAxisTransition(
                                              animation: animation,
                                              secondaryAnimation:
                                                  secondaryAnimation,
                                              transitionType:
                                                  SharedAxisTransitionType
                                                      .horizontal,
                                              child: child,
                                            );
                                          },
                                    ),
                                  );
                                },
                                behavior: HitTestBehavior.opaque,
                                child: const Text(
                                  'Continuar >',
                                  textAlign: TextAlign.left,
                                  style: TextStyle(
                                    color: Color(0xFF9E9E9E),
                                    fontSize: 12,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w500,
                                    height: 1.3333, // 16/12
                                    letterSpacing: 0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Título "Bem-vindo!" (x=24, y=125, 342×34)
                    Positioned(
                      left: transform.mapX(24),
                      top: transform.mapY(125),
                      child: Transform.scale(
                        scale: transform.scale,
                        alignment: Alignment.topLeft,
                        child: const SizedBox(
                          width: 342,
                          height: 34,
                          child: Text(
                            'Bem-vindo!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                              height: 1.4167, // 34/24
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Subtítulo "Veja os destaques de hoje." (x=24, y=159, 342×24)
                    Positioned(
                      left: transform.mapX(24),
                      top: transform.mapY(159),
                      child: Transform.scale(
                        scale: transform.scale,
                        alignment: Alignment.topLeft,
                        child: const SizedBox(
                          width: 342,
                          height: 24,
                          child: Text(
                            'Veja os destaques de hoje.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF9E9E9E),
                              fontSize: 14,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w500,
                              height: 1.5714, // 22/14
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Carousel de destaques (Frame 61:5260, x=0, y=237.29, 390×396).
                    // 3 cards dispostos horizontalmente; o central (Mobland) é
                    // o destaque com opacity 1.0. Os laterais (The Gorge e
                    // Adolescence) aparecem parcialmente nas bordas com 0.6.
                    Positioned(
                      left: transform.mapX(0),
                      top: transform.mapY(237.29),
                      child: Transform.scale(
                        scale: transform.scale,
                        alignment: Alignment.topLeft,
                        child: SizedBox(
                          width: 390,
                          height: 396,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: const [
                              // Card 1 — The Gorge (x=-152, opacity 0.6)
                              Positioned(
                                left: -152,
                                top: 0,
                                child: _MovieCard(
                                  title: 'The Gorge',
                                  year: '2025',
                                  rating: '7.2',
                                  image:
                                      'assets/images/rectangle-395047-8b3ec893.png',
                                  opacity: 0.6,
                                ),
                              ),
                              // Card 2 — Mobland (x=86, central, opacity 1.0)
                              Positioned(
                                left: 86,
                                top: 0,
                                child: _MovieCard(
                                  title: 'Mobland',
                                  year: '2025',
                                  rating: '7.2',
                                  image:
                                      'assets/images/rectangle-395047-44b1c56e.png',
                                  opacity: 1.0,
                                ),
                              ),
                              // Card 3 — Adolescence (x=324, opacity 0.6)
                              Positioned(
                                left: 324,
                                top: 0,
                                child: _MovieCard(
                                  title: 'Adolescence',
                                  year: '2025',
                                  rating: '8.0',
                                  image:
                                      'assets/images/rectangle-395047-d712f5e6.png',
                                  opacity: 0.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Indicador de página (Group 61:5310, x=149.5, y=736.29, 91×6):
                    // barra branca ativa + 6 bolinhas #2c2c2c
                    Positioned(
                      left: transform.mapX(149.5),
                      top: transform.mapY(736.29),
                      child: Transform.scale(
                        scale: transform.scale,
                        alignment: Alignment.topLeft,
                        child: const _PageIndicator(),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Marca "MovieTime" com "Movie" branco e "Time" cinza #9e9e9e.
class _MovieTimeBrand extends StatelessWidget {
  const _MovieTimeBrand();

  @override
  Widget build(BuildContext context) {
    return const Text.rich(
      TextSpan(
        text: 'Movie',
        style: TextStyle(
          color: Colors.white,
          fontSize: 14.88,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w500,
          height: 1.8333, // 27.29/14.88
          letterSpacing: 0,
        ),
        children: [
          TextSpan(
            text: 'Time',
            style: TextStyle(color: Color(0xFF9E9E9E)),
          ),
        ],
      ),
      maxLines: 1,
    );
  }
}

/// Card de destaque de filme (218×396, raio 20).
///
/// Preenchimento #1a1a1a 70% com borda #2c2c2c. Internamente tem padding 10,
/// imagem do cartaz (198×305.7, raio 15) com badge de nota, e rodapé com
/// título + ano à esquerda e botão "Trailer" à direita.
class _MovieCard extends StatelessWidget {
  const _MovieCard({
    required this.title,
    required this.year,
    required this.rating,
    required this.image,
    required this.opacity,
  });

  final String title;
  final String year;
  final String rating;
  final String image;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Container(
        width: 218,
        height: 396,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xB31A1A1A), // #1a1a1a 70%
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF2C2C2C), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Imagem do cartaz (198×305.7, raio 15) com badge
            SizedBox(
              width: 198,
              height: 305.7,
              child: Stack(
                children: [
                  // Imagem do filme
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.asset(image, fit: BoxFit.cover),
                    ),
                  ),
                  // Badge de nota (Frame 2147224296, x=9, y=11, 59×30, raio 20)
                  Positioned(
                    left: 9,
                    top: 11,
                    child: Container(
                      width: 59,
                      height: 30,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xB30D0D0D), // #0d0d0d 70%
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF262626),
                          width: 1,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Estrela amarela #FFC24B
                          const Icon(
                            Icons.star_rounded,
                            size: 16,
                            color: Color(0xFFFFC24B),
                          ),
                          const SizedBox(width: 2.2),
                          // Nota
                          Text(
                            rating,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w500,
                              height: 1.3333, // 16/12
                              letterSpacing: 0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Rodapé (Frame 2085663704, 198×60)
            SizedBox(
              height: 60,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Título + ano (Frame 2085663702, 128×48)
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500,
                            height: 1.5, // 24/16
                            letterSpacing: 0,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          year,
                          style: const TextStyle(
                            color: Color(0xFF9E9E9E),
                            fontSize: 12,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500,
                            height: 1.3333, // 16/12
                            letterSpacing: 0,
                          ),
                        ),
                      ],
                    ),
                    ),
                  ),
                  const SizedBox(width: 1),
                  // Botão "Trailer" (69×30, gradiente + borda)
                  Container(
                    width: 69,
                    height: 30,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFF1A1A1A),
                          Color(0x330D0D0D), // preto 20%
                        ],
                      ),
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(color: const Color(0xFF262626)),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'Trailer',
                      maxLines: 1,
                      style: TextStyle(
                        color: Color(0xFF9E9E9E),
                        fontSize: 12,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                        height: 1.3333, // 16/12
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Indicador de página: barra branca ativa (13×6, raio 3) + 6 bolinhas
/// #2c2c2c 70% (6×6), espaçadas por 7px.
class _PageIndicator extends StatelessWidget {
  const _PageIndicator();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Barra branca ativa
        Container(
          width: 13,
          height: 6,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(2.995),
          ),
        ),
        const SizedBox(width: 7),
        // 6 bolinhas #2c2c2c 70%
        for (var i = 0; i < 6; i++) ...[
          if (i > 0) const SizedBox(width: 7),
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: const Color(0xB32C2C2C), // #2c2c2c 70%
              shape: BoxShape.circle,
            ),
          ),
        ],
      ],
    );
  }
}
