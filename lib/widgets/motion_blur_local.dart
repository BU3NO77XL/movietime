import 'package:flutter/material.dart';
import 'package:flutter_shaders/flutter_shaders.dart';

/// Widget de motion blur local, usando o shader corrigido
/// (`assets/shaders/motion_blur.frag`) compatível com o backend Vulkan
/// do Impeller. Substitui o pacote `motion_blur` (cujo shader original
/// falha na compilação para Vulkan).
///
/// O blur é calculado a partir do deslocamento do widget entre frames.
class MotionBlurLocal extends StatefulWidget {
  const MotionBlurLocal({
    super.key,
    this.intensity = 1.0,
    this.enabled = true,
    required this.child,
  });

  final Widget child;

  /// Intensidade do motion blur (1.0 = interpolação exata entre frames).
  final double intensity;

  /// Se o shader deve ser aplicado.
  final bool enabled;

  @override
  State<MotionBlurLocal> createState() => _MotionBlurLocalState();
}

class _MotionBlurLocalState extends State<MotionBlurLocal> {
  Size? _prevSize;
  Offset? _prevPosition;

  @override
  void didUpdateWidget(covariant MotionBlurLocal oldWidget) {
    if (oldWidget.child != widget.child ||
        oldWidget.intensity != widget.intensity ||
        oldWidget.enabled != widget.enabled) {
      setState(() {});
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    return ShaderBuilder(
      (context, shader, child) {
        return AnimatedSampler(
          (frame, size, canvas) {
            final box = context.findRenderObject() as RenderBox?;
            final position =
                box?.localToGlobal(Offset.zero) ?? Offset.zero;
            final deltaPosition = (_prevPosition ?? position) - position;

            shader
              ..setFloat(0, size.width)
              ..setFloat(1, size.height)
              ..setFloat(2, (_prevSize ?? size).width)
              ..setFloat(3, (_prevSize ?? size).height)
              ..setFloat(4, deltaPosition.dx)
              ..setFloat(5, deltaPosition.dy)
              ..setFloat(6, widget.intensity)
              ..setImageSampler(0, frame);

            canvas.drawRect(Offset.zero & size, Paint()..shader = shader);

            _prevSize = size;
            _prevPosition = position;
          },
          child: child ?? widget.child,
        );
      },
      assetKey: 'assets/shaders/motion_blur.frag',
      child: widget.child,
    );
  }
}
