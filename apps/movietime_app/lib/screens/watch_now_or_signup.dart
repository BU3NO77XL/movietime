import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/app_update_service.dart';
import '../widgets/intro_shared.dart';
import '../widgets/motion_blur_local.dart';
import 'sign_in.dart';
import 'sign_up.dart';

/// Página estabilizada após o loading ([Intro]).
///
/// Corresponde ao frame "Intro2" do Figma (390×844):
/// - Imagem de fundo com blur (390×586, y=31)
/// - Logo MovieTime no topo (x=136, y=114)
/// - Título "Entertainment made easy." + subtítulo
/// - Dois botões: "Watching now" (gradiente) e "Sign up" (outline)
class Intro2 extends StatefulWidget {
  const Intro2({super.key});

  @override
  State<Intro2> createState() => _Intro2State();
}

class _Intro2State extends State<Intro2> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkForUpdate());
  }

  Future<void> _checkForUpdate() async {
    final update = await const AppUpdateService().check();
    if (!mounted || update == null) return;

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Nova versão disponível'),
        content: Text(
          update.notes.isEmpty
              ? 'A versão ${update.versionName} já está disponível.'
              : 'A versão ${update.versionName} já está disponível.\n\n${update.notes}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Agora não'),
          ),
          FilledButton(
            onPressed: () async {
              final url = update.downloadUrl ?? update.releaseUrl;
              await launchUrl(url, mode: LaunchMode.externalApplication);
              if (context.mounted) Navigator.of(context).pop();
            },
            child: const Text('Baixar atualização'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Desativa o escalonamento de fonte do sistema neste frame pixel-perfect:
    // o layout foi desenhado para tamanhos fixos no Figma (390×844) e qualquer
    // aumento de fonte estouraria os containers, causando overflow.
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: Scaffold(
        backgroundColor: const Color(0xFF0D0D0D),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = Size(constraints.maxWidth, constraints.maxHeight);
              final transform = DesignTransform.fromSize(size);
              // O carrossel ocupa a largura fÃ­sica inteira. Em telas mais largas
              // que o frame de design, nÃ£o usamos o offset horizontal do frame,
              // pois isso criaria espaÃ§os entre os posters laterais e as bordas.
              final carouselDesignWidth = size.width / transform.scale;

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
                          imageFilter: ImageFilter.blur(
                            sigmaX: 100,
                            sigmaY: 100,
                          ),
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
                    // Cada poster é envolvido por MotionBlur e animado em loop
                    // (deslocamento horizontal sutil) para gerar o motion blur.
                    Positioned(
                      left: 0,
                      top: transform.mapY(202),
                      child: Transform.scale(
                        scale: transform.scale,
                        alignment: Alignment.topLeft,
                        // Carrossel estático (sem animação de motion blur).
                        child: SizedBox(
                          width: carouselDesignWidth,
                          height: 220,
                          child: Stack(
                            clipBehavior: Clip.hardEdge,
                            children: [
                              // Retângulo esquerdo (Rectangle 395045) - x=-333.96, overlay 40%
                              Positioned(
                                left: -333.96,
                                top: 0,
                                child: MotionBlurLocal(
                                  enabled: false,
                                  intensity: 1.2,
                                  child: _CarouselImage(
                                    image:
                                        'assets/images/rectangle-395045-fc8f71de.png',
                                    width: 352.25,
                                    height: 220,
                                    overlayOpacity: 0.4,
                                  ),
                                ),
                              ),
                              // Retângulo central (Rectangle 395043) - x=33.29, y=9, destaque
                              Positioned(
                                left: (carouselDesignWidth - 323.43) / 2,
                                top: 9,
                                child: MotionBlurLocal(
                                  enabled: false,
                                  intensity: 1.2,
                                  child: _CarouselImage(
                                    image:
                                        'assets/images/rectangle-395043-573e42d4.png',
                                    width: 323.43,
                                    height: 202,
                                    overlayOpacity: 0,
                                  ),
                                ),
                              ),
                              // Retângulo direito (Rectangle 395044) - x=371.71, overlay 50%
                              Positioned(
                                left: carouselDesignWidth - 18.29,
                                top: 0,
                                child: MotionBlurLocal(
                                  enabled: false,
                                  intensity: 1.2,
                                  child: _CarouselImage(
                                    image:
                                        'assets/images/rectangle-395044-cd287cf5.png',
                                    width: 352.25,
                                    height: 220,
                                    overlayOpacity: 0.5,
                                  ),
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
                                        fontFamily: 'Netflix Sans',
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
                                        fontFamily: 'Netflix Sans',
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
                                      label: 'Assistir agora',
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
        ),
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
                fontFamily: 'Netflix Sans',
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
                fontFamily: 'Netflix Sans',
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
/// ~8.65px da base) e cantos arredondados.
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

/// Recorta a imagem no formato exato do vetor "Rectangle 395043" do Figma.
///
/// O path do Figma (fillGeometry) tem:
/// - Cantos arredondados com raio 15 (curvas cúbicas, não arcos)
/// - Borda superior com curva suave até ~9.65px no centro
/// - Borda inferior com curva suave até ~193.35px no centro
///
/// O path é normalizado para caber em qualquer tamanho (323.427×202).
class _CurvedPosterClipper extends CustomClipper<Path> {
  const _CurvedPosterClipper();

  // Dimensões originais do vetor no Figma.
  static const double _dw = 323.427;
  static const double _dh = 202.0;

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;

    // Normaliza uma coordenada X do Figma para o tamanho atual.
    double nx(double x) => x / _dw * w;
    // Normaliza uma coordenada Y do Figma para o tamanho atual.
    double ny(double y) => y / _dh * h;

    // Reproduz exatamente o fillGeometry do Figma:
    // M0 17.8261 C0 8.51677 8.37622 1.31892 17.6207 2.41519
    // C41.7148 5.27241 90.2655 9.64607 161.713 9.64607
    // C233.161 9.64607 281.712 5.27241 305.806 2.41519
    // C315.051 1.31892 323.427 8.51677 323.427 17.8261
    // L323.427 184.713
    // C323.427 193.838 315.335 200.932 306.257 199.994
    // C281.539 197.44 231.145 193.354 161.713 193.354
    // C92.2815 193.354 41.8882 197.44 17.1697 199.994
    // C8.09245 200.932 0 193.838 0 184.713
    // L0 17.8261 Z
    final path = Path()
      // Canto superior esquerdo (curva cúbica)
      ..moveTo(nx(0), ny(17.8261))
      ..cubicTo(
        nx(0),
        ny(8.51677),
        nx(8.37622),
        ny(1.31892),
        nx(17.6207),
        ny(2.41519),
      )
      // Borda superior (curva até o centro)
      ..cubicTo(
        nx(41.7148),
        ny(5.27241),
        nx(90.2655),
        ny(9.64607),
        nx(161.713),
        ny(9.64607),
      )
      // Borda superior (curva do centro até o canto direito)
      ..cubicTo(
        nx(233.161),
        ny(9.64607),
        nx(281.712),
        ny(5.27241),
        nx(305.806),
        ny(2.41519),
      )
      // Canto superior direito (curva cúbica)
      ..cubicTo(
        nx(315.051),
        ny(1.31892),
        nx(323.427),
        ny(8.51677),
        nx(323.427),
        ny(17.8261),
      )
      // Lateral direita
      ..lineTo(nx(323.427), ny(184.713))
      // Canto inferior direito (curva cúbica)
      ..cubicTo(
        nx(323.427),
        ny(193.838),
        nx(315.335),
        ny(200.932),
        nx(306.257),
        ny(199.994),
      )
      // Borda inferior (curva até o centro)
      ..cubicTo(
        nx(281.539),
        ny(197.44),
        nx(231.145),
        ny(193.354),
        nx(161.713),
        ny(193.354),
      )
      // Borda inferior (curva do centro até o canto esquerdo)
      ..cubicTo(
        nx(92.2815),
        ny(193.354),
        nx(41.8882),
        ny(197.44),
        nx(17.1697),
        ny(199.994),
      )
      // Canto inferior esquerdo (curva cúbica)
      ..cubicTo(
        nx(8.09245),
        ny(200.932),
        nx(0),
        ny(193.838),
        nx(0),
        ny(184.713),
      )
      // Lateral esquerda
      ..lineTo(nx(0), ny(17.8261))
      ..close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
