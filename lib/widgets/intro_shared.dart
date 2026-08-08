import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Design Figma / SVG: viewBox 0 0 390 844
const double introDesignWidth = 390;
const double introDesignHeight = 844;

/// Escala o frame 390×844 com o mesmo critério do BoxFit.cover.
class DesignTransform {
  const DesignTransform({required this.scale, required this.offset});

  final double scale;
  final Offset offset;

  factory DesignTransform.fromSize(Size size) {
    final scale = math.max(
      size.width / introDesignWidth,
      size.height / introDesignHeight,
    );
    final offset = Offset(
      (size.width - introDesignWidth * scale) / 2,
      (size.height - introDesignHeight * scale) / 2,
    );
    return DesignTransform(scale: scale, offset: offset);
  }

  double mapX(double x) => offset.dx + x * scale;
  double mapY(double y) => offset.dy + y * scale;
}

/// Logomarca MovieTime (ícone + texto), posicionável via DesignTransform.
class IntroLogoMark extends StatelessWidget {
  const IntroLogoMark({super.key});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/icons/vector-64-1307.svg',
      width: 27.29,
      height: 27.29,
    );
  }
}

/// Texto "MovieTime" do logotipo (reaproveitável).
class MovieTimeLabel extends StatelessWidget {
  const MovieTimeLabel({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text(
      'MovieTime',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Colors.white,
        fontSize: 15,
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w500,
        height: 1.81923,
        letterSpacing: 0,
      ),
    );
  }
}

/// Decoração superior esquerda (flor com gradiente), 255×321.
class TopLeftRingsMark extends StatelessWidget {
  const TopLeftRingsMark({super.key});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/icons/decorative-rings.svg',
      width: 255,
      height: 321,
      fit: BoxFit.none,
    );
  }
}

/// Camadas de fundo compartilhadas entre as telas de intro:
/// preto base + gradiente (aurora) + grão + decoração superior.
///
/// [progress] controla a "respiração" do gradiente. Se vier fixo (ex.: 0.5),
/// a tela estabilizada fica estática; se vier de um AnimationController,
/// a tela de loading anima.
class IntroBackground extends StatelessWidget {
  const IntroBackground({
    super.key,
    required this.size,
    required this.transform,
    this.progress,
    this.showNoise = true,
    this.showRings = true,
  });

  final Size size;
  final DesignTransform transform;
  final double? progress;
  final bool showNoise;
  final bool showRings;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        const ColoredBox(color: Color(0xFF0D0D0D)),
        GradientBlobs(
          progress: progress ?? 0.5,
          size: size,
        ),
        if (showNoise)
          Positioned.fill(
            child: IgnorePointer(child: CustomPaint(painter: NoisePainter())),
          ),
        if (showRings)
          Positioned(
            left: transform.mapX(0),
            top: transform.mapY(0),
            child: Transform.scale(
              scale: transform.scale,
              alignment: Alignment.topLeft,
              child: const IgnorePointer(
                child: SizedBox(
                  width: 255,
                  height: 321,
                  child: TopLeftRingsMark(),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Fundo refeito para igualar a imagem, ponto a ponto:
/// - Glow roxo com pico próximo à borda esquerda, ~46% da altura.
/// - Glow ciano (blob inferior) suave.
class GradientBlobs extends StatelessWidget {
  const GradientBlobs({
    super.key,
    required this.progress,
    required this.size,
  });

  final double progress; // 0.0 → 1.0
  final Size size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: size,
      painter: AuroraPainter(progress: progress),
    );
  }
}

class AuroraPainter extends CustomPainter {
  AuroraPainter({required this.progress});

  final double progress; // 0.0 → 1.0, pulso sutil

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Base: preto quase puro (amostrado da imagem)
    canvas.drawRect(rect, Paint()..color = const Color(0xFF0D0D0D));

    final double pulse = 1.0 + (progress * 0.06); // respiração bem sutil

    // --- Glow roxo ---
    final Offset purpleCenter = Offset(size.width * -0.02, size.height * 0.46);
    final double purpleRadius = size.height * 0.47 * pulse;
    final Paint purplePaint = Paint()
      ..shader = ui.Gradient.radial(
        purpleCenter,
        purpleRadius,
        const [
          Color(0xFF3A2455), // pico (~57,35,84)
          Color(0xFF34214E),
          Color(0xFF2A1D3D),
          Color(0xFF1D1628),
          Color(0xFF141018),
          Color(0xFF0D0D0D), // preto OPACO, igual ao fundo — sem halo
        ],
        const [0.0, 0.22, 0.42, 0.62, 0.8, 1.0],
      );
    canvas.drawRect(rect, purplePaint);

    // --- Glow ciano (blob inferior) ---
    final Offset cyanCenter = Offset(size.width * 0.80, size.height * 0.87);
    final double cyanRadius = size.height * 0.48 * pulse;
    final Paint cyanPaint = Paint()
      ..shader = ui.Gradient.radial(
        cyanCenter,
        cyanRadius,
        const [
          Color(0x265CE1E6), // pico ~15%
          Color(0x145CE1E6),
          Color(0x085CE1E6),
          Color(0x005CE1E6), // transparente — não apaga o roxo ao redor
        ],
        const [0.0, 0.4, 0.7, 1.0],
      );
    canvas.drawRect(rect, cyanPaint);
  }

  @override
  bool shouldRepaint(covariant AuroraPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Textura de grão sutil (film grain).
class NoisePainter extends CustomPainter {
  const NoisePainter();

  static final math.Random _rng = math.Random(7);
  static final List<Offset> _lightDots = List.generate(
    4200,
    (_) => Offset(_rng.nextDouble(), _rng.nextDouble()),
  );
  static final List<Offset> _darkDots = List.generate(
    4200,
    (_) => Offset(_rng.nextDouble(), _rng.nextDouble()),
  );
  static final List<Offset> _coarseDots = List.generate(
    900,
    (_) => Offset(_rng.nextDouble(), _rng.nextDouble()),
  );

  @override
  void paint(Canvas canvas, Size size) {
    final Float32List lightPoints = Float32List(_lightDots.length * 2);
    for (var i = 0; i < _lightDots.length; i++) {
      lightPoints[i * 2] = _lightDots[i].dx * size.width;
      lightPoints[i * 2 + 1] = _lightDots[i].dy * size.height;
    }

    final Float32List darkPoints = Float32List(_darkDots.length * 2);
    for (var i = 0; i < _darkDots.length; i++) {
      darkPoints[i * 2] = _darkDots[i].dx * size.width;
      darkPoints[i * 2 + 1] = _darkDots[i].dy * size.height;
    }

    final Float32List coarsePoints = Float32List(_coarseDots.length * 2);
    for (var i = 0; i < _coarseDots.length; i++) {
      coarsePoints[i * 2] = _coarseDots[i].dx * size.width;
      coarsePoints[i * 2 + 1] = _coarseDots[i].dy * size.height;
    }

    canvas.drawRawPoints(
      ui.PointMode.points,
      lightPoints,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.16)
        ..blendMode = BlendMode.overlay
        ..strokeWidth = 1.0
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawRawPoints(
      ui.PointMode.points,
      darkPoints,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.09)
        ..strokeWidth = 1.0
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawRawPoints(
      ui.PointMode.points,
      coarsePoints,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.14)
        ..blendMode = BlendMode.overlay
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant NoisePainter oldDelegate) => false;
}