import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/auth_service.dart';
import '../widgets/intro_shared.dart';
import 'home.dart';
import 'screen_transitions.dart';
import 'watch_now_or_signup.dart';

/// Tela de loading inicial: mostra o fundo aurora pulsando com o logo,
/// e após um breve tempo navega para a tela estabilizada ([Intro2]).
class Intro extends StatefulWidget {
  const Intro({super.key, this.loadingDuration = const Duration(seconds: 3)});

  final Duration loadingDuration;

  @override
  State<Intro> createState() => _IntroState();
}

class _IntroState extends State<Intro> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();

    // Bloqueia a rotação: trava a tela em retrato enquanto o Intro
    // estiver visível.
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    _ctrl = AnimationController(
      vsync: this,
      // Duração aumentada para criar um pulso de luz bem lento e natural
      duration: const Duration(seconds: 15),
    )..repeat(reverse: true);

    _scheduleNavigation();
  }

  Future<void> _scheduleNavigation() async {
    // Mantém splash por no mínimo [loadingDuration] e em paralelo
    // verifica se já existe sessão válidaPersistida.
    final sessionFuture = _authService.isLoggedIn();
    final delayFuture = Future.delayed(widget.loadingDuration);

    bool isLoggedIn = false;
    try {
      // Aguarda ambos (delay + validação). Timeout de 4s na validação
      // para não prender splash se rede estiver lenta.
      final results = await Future.wait([
        sessionFuture.timeout(
          const Duration(seconds: 4),
          onTimeout: () async {
            // fallback otimista: se timeout mas há token local, mantém logado
            try {
              return await _authService.hasValidLocalSession();
            } catch (_) {
              return false;
            }
          },
        ),
        delayFuture,
      ]);
      isLoggedIn = results[0] as bool;
    } catch (_) {
      isLoggedIn = false;
    }

    if (!mounted) return;

    if (isLoggedIn) {
      debugPrint('Intro: sessão válida encontrada -> navegando para Home');
      Navigator.of(context).pushReplacement(cinematicPageRoute(const Home()));
    } else {
      debugPrint('Intro: sem sessão -> navegando para Intro2 após ${widget.loadingDuration}');
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, animation, secondaryAnimation) => const Intro2(),
          transitionsBuilder: (_, animation, secondaryAnimation, child) {
            // Fade suave entre loading e tela estabilizada.
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _authService.close();

    // Libera a rotação de volta ao normal ao sair desta tela.
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);

    super.dispose();
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
                AnimatedBuilder(
                  animation: _ctrl,
                  builder: (_, _) => IntroBackground(
                    progress: _ctrl.value,
                    size: size,
                    transform: transform,
                  ),
                ),

                // Logo (coordenadas do design × BoxFit.cover)
                Positioned(
                  left: transform.mapX(136),
                  top: transform.mapY(408),
                  child: Transform.scale(
                    scale: transform.scale,
                    alignment: Alignment.topLeft,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
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
