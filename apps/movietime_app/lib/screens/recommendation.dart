import 'dart:ui';

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

import '../widgets/intro_shared.dart';
import 'choose_your_picture.dart';

/// Tela "Control_Recomendation" do Figma (390×844).
///
/// - Fundo preto #0d0d0d com glow cinza no topo (Ellipse 1500, blur 300)
/// - Barra de progresso com 3 segmentos (1º ativo)
/// - Título "Customize your recommendation feed" + subtítulo "Choose at least 3 genres"
/// - Grid 2×3 de cards de gênero (imagem + nome)
/// - Botão "Next" com gradiente roxo + texto "Skip"
class ControlRecomendation extends StatefulWidget {
  const ControlRecomendation({super.key});

  @override
  State<ControlRecomendation> createState() => _ControlRecomendationState();
}

class _ControlRecomendationState extends State<ControlRecomendation> {
  final Set<int> _selected = {};
  late final PageController _genrePageController;
  int _genrePage = 0;

  @override
  void initState() {
    super.initState();
    _genrePageController = PageController();
  }

  @override
  void dispose() {
    _genrePageController.dispose();
    super.dispose();
  }

  void _toggle(int index) {
    setState(() {
      if (_selected.contains(index)) {
        _selected.remove(index);
      } else {
        _selected.add(index);
      }
    });
  }

  void _goToProfile() {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        reverseTransitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, _, _) => const ControlProfile(),
        transitionsBuilder: (_, animation, secondaryAnimation, child) {
          return SharedAxisTransition(
            animation: animation,
            secondaryAnimation: secondaryAnimation,
            transitionType: SharedAxisTransitionType.vertical,
            child: child,
          );
        },
      ),
    );
  }

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

                    // Glow cinza (Ellipse 1500, x=215, y=-144, 350×350, blur 300)
                    Positioned(
                      left: transform.mapX(215),
                      top: transform.mapY(-144),
                      child: Transform.scale(
                        scale: transform.scale,
                        alignment: Alignment.topLeft,
                        child: ImageFiltered(
                          imageFilter: ImageFilter.blur(
                            sigmaX: 300,
                            sigmaY: 300,
                          ),
                          child: Container(
                            width: 350,
                            height: 350,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF2C2C2C),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Barra de progresso (x=24, y=80, 342×3)
                    Positioned(
                      left: transform.mapX(24),
                      top: transform.mapY(80),
                      child: Transform.scale(
                        scale: transform.scale,
                        alignment: Alignment.topLeft,
                        child: const SizedBox(
                          width: 342,
                          height: 3,
                          child: Row(
                            children: [
                              // Segmento 1 ativo (111px, branco com sombra roxa)
                              _ProgressSegment(width: 111, active: true),
                              SizedBox(width: 5),
                              // Segmento 2 (110px, branco 20%)
                              _ProgressSegment(width: 110, active: false),
                              SizedBox(width: 5),
                              // Segmento 3 (111px, branco 20%)
                              _ProgressSegment(width: 111, active: false),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Título + subtítulo (x=65, y=123, 260×95)
                    Positioned(
                      left: transform.mapX(65),
                      top: transform.mapY(123),
                      child: Transform.scale(
                        scale: transform.scale,
                        alignment: Alignment.topLeft,
                        child: const SizedBox(
                          width: 260,
                          height: 95,
                          child: Column(
                            children: [
                              Text(
                                'Personalize seu feed',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontFamily: 'Netflix Sans',
                                  fontWeight: FontWeight.w600,
                                  height: 1.4167, // 34/24
                                  letterSpacing: 0,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                'Escolha pelo menos 3 gêneros',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color(0xFF9E9E9E),
                                  fontSize: 14,
                                  fontFamily: 'Netflix Sans',
                                  fontWeight: FontWeight.w400,
                                  height: 1.5714, // 22/14
                                  letterSpacing: 0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Grid de cards de gênero
                    Positioned(
                      left: 0,
                      top: transform.mapY(220),
                      child: Transform.scale(
                        scale: transform.scale,
                        alignment: Alignment.topLeft,
                        child: SizedBox(
                          width: size.width / transform.scale,
                          height:
                              593, // área de rolagem: y=251 até y=844 (sob o fade)
                          child: ShaderMask(
                            // Máscara superior temporariamente desativada.
                            // Para reativar, troque BlendMode.dst por BlendMode.dstIn.
                            // blendMode: BlendMode.dstIn,
                            blendMode: BlendMode.dst,
                            shaderCallback: (bounds) => const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black,
                                Colors.black,
                              ],
                              // O fade termina logo antes do primeiro card
                              // (padding superior de 100px), sem cobrir o grid.
                              stops: [0.0, 0.14, 1.0],
                            ).createShader(bounds),
                            child: PageView(
                              controller: _genrePageController,
                              clipBehavior: Clip.hardEdge,
                              physics: const PageScrollPhysics(),
                              onPageChanged: (page) =>
                                  setState(() => _genrePage = page),
                              children: [
                                _GenrePage(
                                  topPadding: 0,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _GenreCard(
                                          label: 'Marvel',
                                          image:
                                              'assets/images/rectangle-395047-8b3ec893.png',
                                          selected: _selected.contains(0),
                                          onTap: () => _toggle(0),
                                        ),
                                        const SizedBox(width: 22),
                                        _GenreCard(
                                          label: 'Ficção Científica',
                                          image:
                                              'assets/images/rectangle-395047-fc8f71de.png',
                                          selected: _selected.contains(1),
                                          onTap: () => _toggle(1),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 22),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _GenreCard(
                                          label: 'Suspense',
                                          image:
                                              'assets/images/rectangle-395047-d712f5e6.png',
                                          selected: _selected.contains(2),
                                          onTap: () => _toggle(2),
                                        ),
                                        const SizedBox(width: 22),
                                        _GenreCard(
                                          label: 'Crime',
                                          image:
                                              'assets/images/rectangle-395047-44b1c56e.png',
                                          selected: _selected.contains(3),
                                          onTap: () => _toggle(3),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                _GenrePage(
                                  topPadding: 0,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _GenreCard(
                                          label: 'Marvel',
                                          image:
                                              'assets/images/img-bd4a2b95.png',
                                          selected: _selected.contains(4),
                                          onTap: () => _toggle(4),
                                        ),
                                        const SizedBox(width: 22),
                                        _GenreCard(
                                          label: 'Marvel',
                                          image:
                                              'assets/images/f87d8559b051e037278ee52175df4f0ceb0616668d8ee129263fa27addf0f2c0.png',
                                          selected: _selected.contains(5),
                                          onTap: () => _toggle(5),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Fade inferior (Rectangle 395053 em cima de 390×191 → y 653 até 844)
                    Positioned(
                      left: transform.mapX(0),
                      top: transform.mapY(653),
                      child: Transform.scale(
                        scale: transform.scale,
                        alignment: Alignment.topLeft,
                        child: Container(
                          width: 390,
                          height: 191,
                          decoration: const BoxDecoration(
                            // Fade do Figma (Rectangle 395003):
                            // - começa transparente (0x0D0D0D com alpha 0) no topo
                            // do retângulo e vai ficando opaco até logo abaixo do
                            // meio do botão "Next" (y=738), com a parte escura daí até a base.
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0x000D0D0D), Color(0xFF0D0D0D)],
                              stops: [0.0, 0.444],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Botão "Next" (x=24, y=709, 342×50)
                    Positioned(
                      left: 0,
                      right: 0,
                      top: transform.mapY(680),
                      child: Transform.scale(
                        scale: transform.scale,
                        alignment: Alignment.topCenter,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _GenrePageDot(active: _genrePage == 0),
                            const SizedBox(width: 8),
                            _GenrePageDot(active: _genrePage == 1),
                          ],
                        ),
                      ),
                    ),

                    Positioned(
                      left: transform.mapX(24),
                      top: transform.mapY(709),
                      child: Transform.scale(
                        scale: transform.scale,
                        alignment: Alignment.topLeft,
                        child: _NextButton(
                          enabled: _selected.length >= 3,
                          onTap: _goToProfile,
                        ),
                      ),
                    ),

                    // Texto "Skip" (x=181, y=777, 29×22)
                    /*
                Positioned(
                  left: transform.mapX(181),
                  top: transform.mapY(777),
                  child: Transform.scale(
                    scale: transform.scale,
                    alignment: Alignment.topLeft,
                    child: GestureDetector(
                      onTap: _goToProfile,
                      child: const Text(
                        'Pular',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF525252),
                          fontSize: 14,
                          fontFamily: 'Netflix Sans',
                          fontWeight: FontWeight.w500,
                          height: 1.5714, // 22/14
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ),
                ),
                */
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

/// Segmento da barra de progresso.
class _ProgressSegment extends StatelessWidget {
  const _ProgressSegment({required this.width, required this.active});

  final double width;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 3,
      decoration: BoxDecoration(
        color: active ? Colors.white : Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(3),
        boxShadow: active
            ? const [
                BoxShadow(
                  color: Color(0x80A259FF), // roxo 50%
                  blurRadius: 10,
                  offset: Offset(0, 6),
                ),
              ]
            : null,
      ),
    );
  }
}

/// Botão "Next" (342×50, gradiente roxo + borda), desabilitado até 3 gêneros.
class _NextButton extends StatelessWidget {
  const _NextButton({required this.enabled, this.onTap});

  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 342,
      height: 50,
      decoration: BoxDecoration(
        gradient: enabled
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFA259FF), Color(0xFF562199)],
              )
            : const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF3A3A3A), Color(0xFF2C2C2C)],
              ),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(
          color: enabled ? const Color(0xFFC49EFF) : const Color(0xFF2C2C2C),
          width: 1,
        ),
        boxShadow: enabled
            ? const [
                BoxShadow(
                  color: Color(0x33A259FF), // roxo 20%
                  blurRadius: 10,
                  offset: Offset(0, 10),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(40),
          child: Center(
            child: Text(
              'Próximo',
              style: TextStyle(
                color: enabled ? Colors.white : const Color(0xFF9E9E9E),
                fontSize: 14,
                fontFamily: 'Netflix Sans',
                fontWeight: FontWeight.w500,
                height: 1.5714, // 22/14
                letterSpacing: 0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Card de gênero (160×200, raio 20, gradiente + borda).
class _GenrePageDot extends StatelessWidget {
  const _GenrePageDot({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: active ? 20 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _GenrePage extends StatelessWidget {
  const _GenrePage({required this.topPadding, required this.children});

  final double topPadding;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: topPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: children,
      ),
    );
  }
}

class _GenreCard extends StatelessWidget {
  const _GenreCard({
    required this.label,
    required this.image,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String image;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        height: 200,
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A1A1A),
              Color(0x330D0D0D), // #0d0d0d 20%
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? const Color(0xFFA259FF) : const Color(0xFF2C2C2C),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            // Imagem 140×140, raio 15
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.asset(
                image,
                width: 140,
                height: 140,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 11),
            // Nome do gênero
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontFamily: 'Netflix Sans',
                fontWeight: FontWeight.w500,
                height: 1.5714, // 22/14
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
