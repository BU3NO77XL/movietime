import 'dart:ui';

import 'package:flutter/material.dart';

import '../widgets/intro_shared.dart';

/// Tela "Control_Profile" do Figma (390×844).
///
/// - Fundo preto #0d0d0d com glow cinza no topo (Ellipse 1500, blur 300)
/// - Barra de progresso com 3 segmentos (2º ativo)
/// - Título "Choose your picture" + subtítulo "No commitments, Cancel anytime."
/// - Seletor Avatar/Upload (container #1a1a1a, raio 20)
/// - Imagem principal 150×220 + 5 miniaturas de foto
/// - Botão "Next" com gradiente roxo + texto "Skip"
class ControlProfile extends StatefulWidget {
  const ControlProfile({super.key});

  @override
  State<ControlProfile> createState() => _ControlProfileState();
}

class _ControlProfileState extends State<ControlProfile> {
  int _selectedThumb = 0;

  // Imagens das miniaturas (ordem da esquerda para a direita no Figma)
  static const List<String> _thumbImages = [
    'assets/images/control_profile/images/rectangle-395048-72a84d89.png',
    'assets/images/control_profile/images/rectangle-395048-4d7c7301.png',
    'assets/images/control_profile/images/rectangle-395048-400d326e.png',
    'assets/images/control_profile/images/rectangle-395048-e2a7c4c6.png',
    'assets/images/control_profile/images/rectangle-395048-e872905c.png',
  ];

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

                // Glow cinza (Ellipse 1500, x=215, y=-144, 350×350, blur 300)
                Positioned(
                  left: transform.mapX(215),
                  top: transform.mapY(-144),
                  child: Transform.scale(
                    scale: transform.scale,
                    alignment: Alignment.topLeft,
                    child: ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: 300, sigmaY: 300),
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
                          // Segmento 1 (110px, branco 20%)
                          _ProgressSegment(width: 110, active: false),
                          SizedBox(width: 5),
                          // Segmento 2 ativo (111px, branco com sombra roxa)
                          _ProgressSegment(width: 111, active: true),
                          SizedBox(width: 5),
                          // Segmento 3 (111px, branco 20%)
                          _ProgressSegment(width: 111, active: false),
                        ],
                      ),
                    ),
                  ),
                ),

                // Título + subtítulo (x=65, y=123, 260×61)
                Positioned(
                  left: transform.mapX(65),
                  top: transform.mapY(123),
                  child: Transform.scale(
                    scale: transform.scale,
                    alignment: Alignment.topLeft,
                    child: const SizedBox(
                      width: 260,
                      height: 61,
                      child: Column(
                        children: [
                          Text(
                            'Choose your picture',
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
                          SizedBox(height: 5),
                          Text(
                            'No commitments, Cancel anytime.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF9E9E9E),
                              fontSize: 14,
                              fontFamily: 'Inter',
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

                // Imagem principal (x=120, y=260, 150×220, raio 21.645)
                Positioned(
                  left: transform.mapX(120),
                  top: transform.mapY(260),
                  child: Transform.scale(
                    scale: transform.scale,
                    alignment: Alignment.topLeft,
                    child: Container(
                      width: 150,
                      height: 220,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(21.645),
                        border: Border.all(
                          color: const Color(0xFF262626),
                          width: 1.557,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(21.645),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.asset(
                              _thumbImages[_selectedThumb],
                              fit: BoxFit.cover,
                            ),
                            // Overlay #0d0d0d 20%
                            const ColoredBox(color: Color(0x330D0D0D)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Miniaturas (y=601, 5 fotos 64.78×82.37, raio 10)
                Positioned(
                  left: transform.mapX(24.43),
                  top: transform.mapY(601),
                  child: Transform.scale(
                    scale: transform.scale,
                    alignment: Alignment.topLeft,
                    child: SizedBox(
                      width: 382.14,
                      height: 93,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Thumb(
                            image: _thumbImages[0],
                            selected: _selectedThumb == 0,
                            onTap: () => setState(() => _selectedThumb = 0),
                          ),
                          const SizedBox(width: 20.77),
                          _Thumb(
                            image: _thumbImages[1],
                            selected: _selectedThumb == 1,
                            onTap: () => setState(() => _selectedThumb = 1),
                          ),
                          const SizedBox(width: 13),
                          _Thumb(
                            image: _thumbImages[2],
                            selected: _selectedThumb == 2,
                            onTap: () => setState(() => _selectedThumb = 2),
                          ),
                          const SizedBox(width: 13),
                          _Thumb(
                            image: _thumbImages[3],
                            selected: _selectedThumb == 3,
                            onTap: () => setState(() => _selectedThumb = 3),
                          ),
                          const SizedBox(width: 13),
                          _Thumb(
                            image: _thumbImages[4],
                            selected: _selectedThumb == 4,
                            onTap: () => setState(() => _selectedThumb = 4),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Seletor Avatar/Upload (x=102, y=513, 186×60)
                Positioned(
                  left: transform.mapX(102),
                  top: transform.mapY(513),
                  child: Transform.scale(
                    scale: transform.scale,
                    alignment: Alignment.topLeft,
                    child: Container(
                      width: 186,
                      height: 60,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          _ModeButton(label: 'Avatar', active: true),
                          SizedBox(width: 10),
                          _ModeButton(label: 'Upload', active: false),
                        ],
                      ),
                    ),
                  ),
                ),

                // Botão "Next" (x=24, y=709, 342×50)
                Positioned(
                  left: transform.mapX(24),
                  top: transform.mapY(709),
                  child: Transform.scale(
                    scale: transform.scale,
                    alignment: Alignment.topLeft,
                    child: const _NextButton(),
                  ),
                ),

                // Texto "Skip" (x=181, y=777, 29×22)
                Positioned(
                  left: transform.mapX(181),
                  top: transform.mapY(777),
                  child: Transform.scale(
                    scale: transform.scale,
                    alignment: Alignment.topLeft,
                    child: GestureDetector(
                      onTap: () {},
                      child: const Text(
                        'Skip',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF525252),
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

                // Home indicator (x=130, y=827, 130×4)
                Positioned(
                  left: transform.mapX(130),
                  top: transform.mapY(827),
                  child: Transform.scale(
                    scale: transform.scale,
                    alignment: Alignment.topLeft,
                    child: Container(
                      width: 130,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(3),
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

/// Miniatura de foto (64.78×82.37, raio 10).
class _Thumb extends StatelessWidget {
  const _Thumb({
    required this.image,
    required this.selected,
    required this.onTap,
  });

  final String image;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64.78,
        height: 82.37,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? const Color(0xFFA259FF) : Colors.transparent,
            width: 1.26,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Opacity(
            opacity: selected ? 1.0 : 0.5,
            child: Image.asset(image, fit: BoxFit.cover),
          ),
        ),
      ),
    );
  }
}

/// Botão de modo Avatar/Upload (74×40, raio 10).
class _ModeButton extends StatelessWidget {
  const _ModeButton({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 78,
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        gradient: active
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1A1A1A), Color(0xFF2C2C2C)],
              )
            : null,
        borderRadius: BorderRadius.circular(10),
        border: active
            ? Border.all(color: const Color(0xFF2C2C2C), width: 1)
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: active ? Colors.white : const Color(0xFF9E9E9E),
          fontSize: 14,
          fontFamily: 'Inter',
          fontWeight: FontWeight.w500,
          height: 1.5714, // 22/14
          letterSpacing: 0,
        ),
      ),
    );
  }
}

/// Botão "Next" (342×50, gradiente roxo + borda).
class _NextButton extends StatelessWidget {
  const _NextButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 342,
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
            color: Color(0x33A259FF), // roxo 20%
            blurRadius: 10,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(40),
          child: const Center(
            child: Text(
              'Next',
              style: TextStyle(
                color: Colors.white,
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
    );
  }
}
