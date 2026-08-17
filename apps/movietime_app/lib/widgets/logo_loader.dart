import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_shaders/flutter_shaders.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Loader giratório com o logo MovieTime.
///
/// Projetado para que a chegada de dados do backend não trave a animação:
///
/// - O logo é rasterizado **uma única vez** num [ui.Image]; o SVG não é
///   re-traçado a cada frame.
/// - A cada frame apenas um [CustomPaint] pequeno é repintado, sem reconstruir
///   nenhum widget: o [CustomPaint.repaint] é o próprio [AnimationController].
/// - O loader fica isolado num [RepaintBoundary]. Assim, rebuilds/repaints do
///   restante da tela (listas, imagens, dados chegando) não repintam a camada
///   do loader, e a repintura do loader não obriga a tela inteira a repintar.
///
/// O motion blur é **rotacional** (shader próprio) e não translacional: a
/// imagem é varrida ao longo do arco do giro usando o deslocamento angular do
/// último frame. Se um frame é perdido por trabalho pesado na main thread, o
/// ângulo varrido cresce e o desfoque mascara o salto, mantendo a percepção de
/// movimento contínuo em vez de um "travamento".
class LogoLoader extends StatefulWidget {
  const LogoLoader({
    super.key,
    this.size = 88,
    this.logoSize = 64,
    this.intensity = 1.2,
    this.duration = const Duration(milliseconds: 1100),
  });

  /// Tamanho total do box (logo + folga para o motion blur não ser cortado).
  final double size;

  /// Tamanho do logo em si.
  final double logoSize;

  /// Força do motion blur (0.0 = sem blur).
  final double intensity;

  /// Duração de uma volta completa.
  final Duration duration;

  static const String asset = 'assets/icons/vector-64-1307.svg';
  static const String shaderAsset =
      'assets/shaders/rotational_motion_blur.frag';

  static final Map<String, Future<ui.Image>> _imageCache = {};

  @override
  State<LogoLoader> createState() => _LogoLoaderState();
}

class _LogoLoaderState extends State<LogoLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  ui.Image? _logoImage;
  bool _started = false;
  double _lastTurns = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
    ShaderBuilder.precacheShader(LogoLoader.shaderAsset);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _rasterizeLogo();
    }
  }

  @override
  void didUpdateWidget(covariant LogoLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.size != widget.size ||
        oldWidget.logoSize != widget.logoSize) {
      _rasterizeLogo();
    }
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
    }
  }

  Future<void> _rasterizeLogo() async {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final box = widget.size;
    final logo = widget.logoSize;
    final px = (box * dpr).ceil();
    final key = '${LogoLoader.asset}@$box@$dpr';

    final future = LogoLoader._imageCache.putIfAbsent(key, () async {
      final info = await vg.loadPicture(SvgAssetLoader(LogoLoader.asset), null);
      final picture = info.picture;
      try {
        final svgSize = info.size;
        final scale =
            logo / math.max(math.max(svgSize.width, svgSize.height), 1.0);
        final offset = Offset((box - logo) / 2, (box - logo) / 2);
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        canvas.scale(dpr);
        canvas.translate(offset.dx, offset.dy);
        canvas.scale(scale, scale);
        canvas.drawPicture(picture);
        final recorded = recorder.endRecording();
        final image = await recorded.toImage(px, px);
        recorded.dispose();
        return image;
      } finally {
        picture.dispose();
      }
    });

    final image = await future;
    if (!mounted) return;
    setState(() => _logoImage = image);
  }

  @override
  Widget build(BuildContext context) {
    final fallback = Center(
      child: RotationTransition(
        turns: _controller,
        child: SvgPicture.asset(
          LogoLoader.asset,
          width: widget.logoSize,
          height: widget.logoSize,
        ),
      ),
    );

    return RepaintBoundary(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: ShaderBuilder(
          (context, shader, child) {
            final image = _logoImage;
            if (image == null) return child ?? const SizedBox.shrink();
            return CustomPaint(
              size: Size.square(widget.size),
              painter: _RotationalBlurPainter(
                shader: shader,
                image: image,
                state: this,
                intensity: widget.intensity,
              ),
            );
          },
          assetKey: LogoLoader.shaderAsset,
          child: fallback,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _RotationalBlurPainter extends CustomPainter {
  _RotationalBlurPainter({
    required this.shader,
    required this.image,
    required this._state,
    required this.intensity,
  }) : super(repaint: _state._controller);

  final ui.FragmentShader shader;
  final ui.Image image;
  final _LogoLoaderState _state;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    final turns = _state._controller.value;
    final rawDelta = turns - _state._lastTurns;
    final wrappedTurns = (rawDelta + 0.5) % 1.0 - 0.5;
    final angleDelta = wrappedTurns * 2 * math.pi;
    final angle = turns * 2 * math.pi;
    _state._lastTurns = turns;

    shader
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, angle)
      ..setFloat(3, angleDelta)
      ..setFloat(4, intensity)
      ..setImageSampler(0, image);

    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(covariant _RotationalBlurPainter oldDelegate) =>
      oldDelegate.image != image ||
      oldDelegate.intensity != intensity ||
      oldDelegate.shader != shader;
}