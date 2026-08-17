import 'dart:ui';

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

import '../widgets/intro_shared.dart';
import 'highlights.dart';

/// Tela "ControlPlan" do Figma (390×844).
///
/// - Fundo preto #0d0d0d com glow cinza no topo (Ellipse 1500, blur 300)
/// - Barra de progresso com 3 segmentos (3º ativo)
/// - Título "Choose your plan" + subtítulo "No commitments, Cancel anytime."
/// - Carousel horizontal de cards de plano (ativo + inativo)
/// - Indicador de página (bolinhas) mostrando que é um slider
/// - Link "Cupom de desconto" sublinhado que abre um modal estilizado
class ControlPlan extends StatefulWidget {
  const ControlPlan({super.key});

  @override
  State<ControlPlan> createState() => _ControlPlanState();
}

class _ControlPlanState extends State<ControlPlan> {
  int _selectedPlan = 0;
  bool _eliteUnlocked = false;

  /// Largura do card (reduzida para mostrar levemente a borda do próximo).
  static const double _cardWidth = 280;

  /// Espaçamento entre cards.
  static const double _cardGap = 22.72;

  /// Passo entre cards: largura + espaçamento.
  static const double _cardStep = _cardWidth + _cardGap;

  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Atualiza a bolinha ativa conforme o usuário desliza o carousel.
  void _onScroll() {
    final index = (_scrollController.offset / _cardStep).round().clamp(0, 1);
    if (index != _selectedPlan) {
      setState(() => _selectedPlan = index);
    }
  }

  /// Abre o modal estilizado para digitar o cupom de desconto.
  Future<void> _showCouponModal() async {
    final couponController = TextEditingController();
    final coupon = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 12,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Alça de arraste do modal
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C2C2C),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Cupom de desconto',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontFamily: 'Netflix Sans',
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Digite seu cupom para ganhar desconto no plano.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF9E9E9E),
                    fontSize: 13,
                    fontFamily: 'Netflix Sans',
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: couponController,
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Ex: MOVIE10',
                    hintStyle: const TextStyle(color: Color(0xFF525252)),
                    filled: true,
                    fillColor: const Color(0xFF0D0D0D),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF2C2C2C)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF2C2C2C)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFA259FF)),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Botão aplicar
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFA259FF), Color(0xFF562199)],
                    ),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        FocusScope.of(context).unfocus();
                        Navigator.of(
                          context,
                        ).pop(couponController.text.trim().toUpperCase());
                      },
                      borderRadius: BorderRadius.circular(40),
                      child: const Center(
                        child: Text(
                          'Aplicar cupom',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontFamily: 'Netflix Sans',
                            fontWeight: FontWeight.w500,
                            height: 1.5714,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    // Aguarda a desmontagem completa do bottom sheet e do teclado antes de
    // descartar o controller e atualizar a tela principal.
    // Aguarda a desmontagem do bottom sheet e a animação do teclado antes
    // de inserir o widget nativo da animação de confetes.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    couponController.dispose();

    if (!mounted || coupon == null) return;
    if (coupon == 'WESKER') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _eliteUnlocked = true);
      });
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Cupom inválido.'),
          backgroundColor: Color(0xFFAD2536),
          behavior: SnackBarBehavior.floating,
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
                              // Segmento 1 (111px, branco 20%)
                              _ProgressSegment(width: 111, active: false),
                              SizedBox(width: 5),
                              // Segmento 2 (110px, branco 20%)
                              _ProgressSegment(width: 110, active: false),
                              SizedBox(width: 5),
                              // Segmento 3 ativo (111px, branco com sombra roxa)
                              _ProgressSegment(width: 111, active: true),
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
                                'Escolha seu plano',
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

                    // Carousel de cards de plano (x=24, y=254, 310×456).
                    Positioned(
                      left: transform.mapX(24),
                      top: transform.mapY(254),
                      child: Transform.scale(
                        scale: transform.scale,
                        alignment: Alignment.topLeft,
                        child: SizedBox(
                          width: 310,
                          height: 456,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            clipBehavior: Clip.none,
                            controller: _scrollController,
                            physics: const BouncingScrollPhysics(
                              parent: AlwaysScrollableScrollPhysics(),
                            ),
                            padding: const EdgeInsets.only(right: _cardGap),
                            children: [
                              _PlanCard(
                                width: _cardWidth,
                                active: _selectedPlan == 0,
                                eliteUnlocked: _eliteUnlocked,
                                onTap: () => setState(() => _selectedPlan = 0),
                              ),
                              const SizedBox(width: _cardGap),
                              _InactivePlanCard(
                                width: _cardWidth,
                                active: _selectedPlan == 1,
                                onTap: () => setState(() => _selectedPlan = 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Indicador de página (bolinhas)
                    Positioned(
                      left: 0,
                      right: 0,
                      top: transform.mapY(720),
                      child: Transform.scale(
                        scale: transform.scale,
                        alignment: Alignment.topCenter,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _PageDot(active: _selectedPlan == 0),
                            const SizedBox(width: 8),
                            _PageDot(active: _selectedPlan == 1),
                          ],
                        ),
                      ),
                    ),

                    // Link "Cupom de desconto" (rodapé, sublinhado)
                    Positioned(
                      left: transform.mapX(24),
                      top: transform.mapY(757),
                      child: Transform.scale(
                        scale: transform.scale,
                        alignment: Alignment.topLeft,
                        child: SizedBox(
                          width: 342,
                          child: GestureDetector(
                            onTap: _showCouponModal,
                            child: const Text(
                              'Cupom de desconto',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF9E9E9E),
                                fontSize: 14,
                                fontFamily: 'Netflix Sans',
                                fontWeight: FontWeight.w500,
                                height: 1.5714, // 22/14
                                letterSpacing: 0,
                                decoration: TextDecoration.underline,
                                decorationColor: Color(0xFF9E9E9E),
                              ),
                            ),
                          ),
                        ),
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

/// Bolinha do indicador de página. A ativa fica mais larga (pill) e roxa.
class _PageDot extends StatelessWidget {
  const _PageDot({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      width: active ? 20 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: active ? const Color(0xFFA259FF) : const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

/// Card de plano ativo (ULTIMATE R$14,99).
class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.width,
    required this.active,
    required this.eliteUnlocked,
    required this.onTap,
  });

  final double width;
  final bool active;
  final bool eliteUnlocked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: 454.41,
        padding: const EdgeInsets.only(
          top: 34.08,
          right: 22.72,
          bottom: 34.08,
          left: 22.72,
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0x33A259FF), // roxo 20%
              Color(0x330D0D0D), // preto 20%
            ],
          ),
          borderRadius: BorderRadius.circular(22.72),
          border: Border.all(
            color: const Color(0x80A259FF), // roxo 50%
            width: 1.136,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Título + preço
            SizedBox(
              width: 130,
              child: Column(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(width: 6),
                      const Text(
                        'ULTIMATE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontFamily: 'Netflix Sans',
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 11.36),
                  // FittedBox garante que "R$14,99" fique em uma linha só,
                  // mesmo no card mais estreito (largura 130 é suficiente).
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      r'R$14,99/mês',
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFA259FF),
                        fontSize: 27.26,
                        fontFamily: 'Netflix Sans',
                        fontWeight: FontWeight.w600,
                        height: 1.4167, // 38.625/27.26
                        letterSpacing: 0,
                        decoration: eliteUnlocked
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                    ),
                  ),
                  if (eliteUnlocked) ...[
                    const SizedBox(height: 2),
                    const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        r'R$0,00/mês',
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFFA259FF),
                          fontSize: 25,
                          fontFamily: 'Netflix Sans',
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 5),
                  const Text(
                    'Cancele quando quiser.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF9E9E9E),
                      fontSize: 11,
                      fontFamily: 'Netflix Sans',
                      fontWeight: FontWeight.w400,
                      height: 1.4,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // Features (espaçamento reduzido para caber no card mais estreito)
            const _FeatureRow(
              iconColor: Color(0xFF2C2C2C),
              label: 'Biblioteca de streaming',
            ),
            const SizedBox(height: 12),
            const _FeatureRow(
              iconColor: Color(0xFF2C2C2C),
              label: 'Até 4 perfis de usuário',
            ),
            const SizedBox(height: 12),
            const _FeatureRow(
              iconColor: Color(0xFF262626),
              label: 'Biblioteca de streaming',
            ),
            const SizedBox(height: 12),
            const _FeatureRow(
              iconColor: null, // gradiente roxo
              label: 'Sem anúncios',
            ),
            const SizedBox(height: 12),
            const _FeatureRow(
              iconColor: null, // gradiente roxo
              label: 'Baixe vídeos ilimitados',
            ),

            const Spacer(),

            // Botão "Get started"
            Container(
              width: 117,
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFA259FF), Color(0xFF562199)],
                ),
                borderRadius: BorderRadius.circular(40),
              ),
              alignment: Alignment.center,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    if (!eliteUnlocked) return;
                    Navigator.of(context).push(
                      PageRouteBuilder(
                        transitionDuration: const Duration(milliseconds: 450),
                        reverseTransitionDuration: const Duration(
                          milliseconds: 450,
                        ),
                        pageBuilder: (_, _, _) => const Highlights(),
                        transitionsBuilder:
                            (_, animation, secondaryAnimation, child) {
                              return SharedAxisTransition(
                                animation: animation,
                                secondaryAnimation: secondaryAnimation,
                                transitionType:
                                    SharedAxisTransitionType.vertical,
                                child: child,
                              );
                            },
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(40),
                  child: Center(
                    child: Text(
                      eliteUnlocked ? 'Acessar' : 'Assinar',
                      style: const TextStyle(
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
            ),
          ],
        ),
      ),
    );
  }
}

/// Card de plano inativo (vazio).
class _InactivePlanCard extends StatelessWidget {
  const _InactivePlanCard({
    required this.width,
    required this.active,
    required this.onTap,
  });

  final double width;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: 454.41,
        padding: const EdgeInsets.only(
          top: 34.08,
          right: 22.72,
          bottom: 34.08,
          left: 22.72,
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A1A1A),
              Color(0x330D0D0D), // preto 20%
            ],
          ),
          borderRadius: BorderRadius.circular(22.72),
          border: Border.all(color: const Color(0xFF262626), width: 1.136),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 130,
              child: Column(
                children: [
                  Text(
                    'LITE',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontFamily: 'Netflix Sans',
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 11.36),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      r'R$0,00/mês',
                      maxLines: 1,
                      style: TextStyle(
                        color: Color(0xFF9E9E9E),
                        fontSize: 27.26,
                        fontFamily: 'Netflix Sans',
                        fontWeight: FontWeight.w600,
                        height: 1.4167,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const _FeatureRow(
              iconColor: Color(0xFF2C2C2C),
              label: 'Acesso ao aplicativo',
            ),
            const SizedBox(height: 12),
            const _FeatureRow(
              iconColor: Color(0xFF2C2C2C),
              label: 'Catálogo gratuito',
            ),
            const SizedBox(height: 12),
            const _FeatureRow(
              iconColor: Color(0xFF262626),
              label: 'Com anúncios',
            ),
            const Spacer(),
            Container(
              width: 117,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2C),
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Text(
                'Usar grátis',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontFamily: 'Netflix Sans',
                  fontWeight: FontWeight.w500,
                  height: 1.5714,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Linha de feature com ícone de check.
class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.iconColor, required this.label});

  final Color? iconColor; // null = gradiente roxo
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Ícone circular com check
        Container(
          width: 24.99,
          height: 24.99,
          padding: const EdgeInsets.all(5.68),
          decoration: BoxDecoration(
            gradient: iconColor == null
                ? const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFA259FF), Color(0xFF562199)],
                  )
                : null,
            color: iconColor,
            shape: BoxShape.circle,
          ),
          child: CustomPaint(painter: _CheckPainter()),
        ),
        const SizedBox(width: 11.36),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF9E9E9E),
              fontSize: 15.9,
              fontFamily: 'Netflix Sans',
              fontWeight: FontWeight.w400,
              height: 1.5714, // 24.99/15.9
              letterSpacing: 0,
            ),
          ),
        ),
      ],
    );
  }
}

/// Desenha o ícone de check (traço branco).
class _CheckPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(size.width * 0.25, size.height * 0.5)
      ..lineTo(size.width * 0.45, size.height * 0.7)
      ..lineTo(size.width * 0.75, size.height * 0.3);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CheckPainter oldDelegate) => false;
}
