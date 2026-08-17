import 'dart:ui';

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

import '../services/avatar_catalog.dart';
import '../widgets/local_avatar_image.dart';
import '../widgets/intro_shared.dart';
import 'choose_your_plan.dart';

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
  bool _showAllAvatars = false;

  void _goToPlan() {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        reverseTransitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, _, _) => const ControlPlan(),
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

  static const List<int> _thumbImages = [0, 1, 2, 3, 4];

  // Espaçamentos entre as miniaturas (ordem da esquerda para a direita)
  static const List<double> _thumbGaps = [11.427, 13.0, 12.912, 12.522];

  @override
  Widget build(BuildContext context) {
    // MantÃ©m o texto dentro do frame de design antes que ele seja reduzido
    // para telas menores. Assim, fontes de acessibilidade nÃ£o estouram os
    // containers fixos do layout e a tela continua sendo escalada inteira.
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
                                'Escolha sua foto',
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
                                'Sem compromissos, cancele quando quiser.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color(0xFF9E9E9E),
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
                                LocalAvatarImage(
                                  avatarIndex: _selectedThumb,
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

                    // Miniaturas (Group 2085663462, x=24.427, y=601, 382.138×93)
                    // A miniatura selecionada (1ª) é maior: 73.146×93 com opacity 1.
                    // As demais: 64.783×82.366 com opacity 0.5.
                    // Gaps: 11.427, 13.0, 12.912, 12.522.
                    // Carousel finito: rola até o último avatar (mostrado completo
                    // graças ao padding final) e para, no estilo clássico, sem
                    // voltar ao primeiro item.
                    Positioned(
                      left: transform.mapX(24.427),
                      top: transform.mapY(601),
                      child: Transform.scale(
                        scale: transform.scale,
                        alignment: Alignment.topLeft,
                        child: SizedBox(
                          width: 382.138,
                          height: 93,
                          child: _AvatarCarousel(
                            avatarIndexes: _thumbImages,
                            gaps: _thumbGaps,
                            selected: _selectedThumb,
                            onSelect: (index) =>
                                setState(() => _selectedThumb = index),
                          ),
                        ),
                      ),
                    ),

                    // Seletor Avatar/Upload (Frame 2147224313, x=102, y=513, 186×60)
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
                          child: Row(
                            children: [
                              const _ModeButton(label: 'Avatar', active: true),
                              const SizedBox(width: 10),
                              GestureDetector(
                                onTap: () =>
                                    setState(() => _showAllAvatars = true),
                                child: const _ModeButton(
                                  label: 'Ver todos',
                                  active: false,
                                ),
                              ),
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
                        child: _NextButton(onPressed: _goToPlan),
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
                          onTap: _goToPlan,
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
                    if (_showAllAvatars)
                      Positioned.fill(
                        child: _AllAvatarsModal(
                          selectedAvatar: _selectedThumb,
                          onClose: () =>
                              setState(() => _showAllAvatars = false),
                          onSelect: (index) {
                            setState(() {
                              _selectedThumb = index;
                              _showAllAvatars = false;
                            });
                          },
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

/// Miniatura de foto. A selecionada é maior (73.146×93, opacity 1);
/// as demais são 64.783×82.366 com opacity 0.5. Raio 10.
class _Thumb extends StatelessWidget {
  const _Thumb({
    required this.avatarIndex,
    required this.selected,
    required this.onTap,
  });

  final int avatarIndex;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: selected ? 73.146 : 64.783,
        height: selected ? 93 : 82.366,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? const Color(0xFFA259FF) : Colors.transparent,
            width: 1.263,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Opacity(
            opacity: selected ? 1.0 : 0.5,
            child: LocalAvatarImage(
              avatarIndex: avatarIndex,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
}

/// Carousel horizontal finito de avatares.
///
/// Rola da esquerda para a direita até o último avatar (mostrado completo
/// graças ao padding final) e para ali, no estilo clássico — sem loop que
/// volte ao primeiro item. O clipBehavior: Clip.none permite que os avatares
/// se estendam até a borda da tela sem serem recortados pelo container.
class _AvatarCarousel extends StatelessWidget {
  const _AvatarCarousel({
    required this.avatarIndexes,
    required this.gaps,
    required this.selected,
    required this.onSelect,
  });

  final List<int> avatarIndexes;
  final List<double> gaps;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    // Padding inicial: recua os primeiros avatares (metade do primeiro gap).
    const double leadingPadding = 5.7135; // 11.427 / 2

    // Padding final: garante que o último avatar seja mostrado completo.
    const double trailingPadding = 64.783;

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      // Bouncing em todas as plataformas: permite "puxar" o primeiro avatar
      // para o lado contrário e rebater suavemente no último.
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: const EdgeInsets.only(
        left: leadingPadding,
        right: trailingPadding,
      ),
      itemCount: avatarIndexes.length,
      itemBuilder: (context, index) {
        final avatarIndex = avatarIndexes[index];
        final isSelected = avatarIndex == selected;
        // Cada item inclui o avatar + o gap seguinte para manter o espaçamento.
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Thumb(
              avatarIndex: avatarIndex,
              selected: isSelected,
              onTap: () => onSelect(avatarIndex),
            ),
            SizedBox(width: gaps[index % gaps.length]),
          ],
        );
      },
    );
  }
}

/// Botão de modo Avatar/Upload. "Avatar" (ativo) tem 74×40 com gradiente
/// #1a1a1a→#2c2c2c (stops 0.7404→1.0); "Upload" tem 78×40 sem fill.
class _ModeButton extends StatelessWidget {
  const _ModeButton({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: active ? 74 : 92,
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        gradient: active
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1A1A1A), Color(0xFF2C2C2C)],
                stops: [0.7404, 1.0],
              )
            : null,
        borderRadius: BorderRadius.circular(10),
        border: active
            ? Border.all(color: const Color(0xFF2C2C2C), width: 1)
            : null,
      ),
      alignment: Alignment.center,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          label,
          maxLines: 1,
          style: TextStyle(
            color: active ? Colors.white : const Color(0xFF9E9E9E),
            fontSize: 14,
            fontFamily: 'Netflix Sans',
            fontWeight: FontWeight.w500,
            height: 1.5714, // 22/14
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

class _AllAvatarsModal extends StatelessWidget {
  const _AllAvatarsModal({
    required this.selectedAvatar,
    required this.onClose,
    required this.onSelect,
  });

  final int selectedAvatar;
  final VoidCallback onClose;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onClose,
              child: Container(color: const Color(0xCC0D0D0D)),
            ),
          ),
          Center(
            child: Container(
              width: 330,
              height: 520,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF2C2C2C)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Escolha seu avatar',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontFamily: 'Netflix Sans',
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: onClose,
                        child: const Icon(
                          Icons.close_rounded,
                          color: Color(0xFF9E9E9E),
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: totalRemoteAvatars,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            mainAxisExtent: 64,
                          ),
                      itemBuilder: (context, index) {
                        final isSelected = index == selectedAvatar;
                        return GestureDetector(
                          onTap: () => onSelect(index),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFFA259FF)
                                    : const Color(0xFF2C2C2C),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            padding: EdgeInsets.all(isSelected ? 2 : 0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LocalAvatarImage(
                                avatarIndex: index,
                                width: 64,
                                height: 64,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Botão "Next" (342×50, gradiente roxo + borda).
class _NextButton extends StatelessWidget {
  const _NextButton({required this.onPressed});

  final VoidCallback onPressed;

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
          onTap: onPressed,
          borderRadius: BorderRadius.circular(40),
          child: const Center(
            child: Text(
              'Próximo',
              style: TextStyle(
                color: Colors.white,
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
