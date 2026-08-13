import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../widgets/intro_shared.dart';
import 'sign_in.dart';
import 'sign_up_email.dart';

/// Tela "Sign up" do Figma (390×844).
///
/// - Fundo preto com dois glows: roxo (topo, blur 300) e ciano (baixo, blur 300)
/// - Título "Sign up" + subtítulo "Please login with your number"
/// - Botões sociais: "Sign up with Apple", "Sign up with Google", "Continue with Email"
/// - Link "Already have an account? Sign In"
class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  late final TapGestureRecognizer _goToSignIn = TapGestureRecognizer()
    ..onTap = () {
      Navigator.of(context).push(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 450),
          reverseTransitionDuration: const Duration(milliseconds: 450),
          pageBuilder: (_, _, _) => const SignIn(),
          transitionsBuilder: (_, animation, _, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
              reverseCurve: Curves.easeInOut,
            );
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.06),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            );
          },
        ),
      );
    };

  @override
  void dispose() {
    _goToSignIn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // O frame Ã© escalado pelo DesignTransform para caber na tela. O texto
    // tambÃ©m precisa participar desse mesmo sistema de escala; caso o
    // escalonamento de acessibilidade seja aplicado antes do transform, os
    // textos deixam de caber nos containers do frame e provocam overflow.
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.noScaling,
      ),
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

                // Glow roxo (Ellipse 1500, x=-145, y=-155, blur 300, roxo 20%)
                Positioned(
                  left: transform.mapX(-145),
                  top: transform.mapY(-155),
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
                          color: Color(0x33A259FF), // #a259ff 20%
                        ),
                      ),
                    ),
                  ),
                ),

                // Glow ciano (Ellipse 1501, x=138, y=580, blur 300, ciano 10%)
                Positioned(
                  left: transform.mapX(138),
                  top: transform.mapY(580),
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
                          color: Color(0x1A5CE1E6), // #5ce1e6 10%
                        ),
                      ),
                    ),
                  ),
                ),

                // Título central (x=95, y=171.47, 200×61)
                Positioned(
                  left: transform.mapX(95),
                  top: transform.mapY(171.465),
                  child: Transform.scale(
                    scale: transform.scale,
                    alignment: Alignment.topLeft,
                    child: const SizedBox(
                      width: 200,
                      height: 61,
                      child: Column(
                        children: [
                          Text(
                            'Cadastre-se',
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
                            'Crie sua conta em segundos',
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

                // Botões sociais (x=24, y=317, 342×210)
                Positioned(
                  left: transform.mapX(24),
                  top: transform.mapY(317),
                  child: Transform.scale(
                    scale: transform.scale,
                    alignment: Alignment.topLeft,
                    child: SizedBox(
                      width: 342,
                      height: 210,
                      child: Column(
                        children: [
                          const SocialButton(
                            label: 'Cadastre-se com a Apple',
                            icon: AppleIcon(),
                          ),
                          const SizedBox(height: 15),
                          const SocialButton(
                            label: 'Cadastre-se com o Google',
                            icon: GoogleIcon(),
                          ),
                          const SizedBox(height: 15),
                          _EmailButton(
                            label: 'Continuar com e-mail',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const SignUpEmail(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // "Already have an account? Sign In" (y=774)
                // Centralizado horizontalmente: usa a largura útil da tela
                // (342px, de x=24 a x=366) com textAlign: TextAlign.center,
                // garantindo que o texto fique perfeitamente centralizado
                // independentemente da largura real renderizada.
                Positioned(
                  left: transform.mapX(24),
                  top: transform.mapY(774),
                  child: Transform.scale(
                    scale: transform.scale,
                    alignment: Alignment.topLeft,
                    child: SizedBox(
                      width: 342,
                      child: Text.rich(
                        textAlign: TextAlign.center,
                        TextSpan(
                          children: [
                            const TextSpan(
                              text: 'Já tem uma conta? ',
                              style: TextStyle(
                                color: Color(0xFF525252),
                                fontSize: 14,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w500,
                                height: 1.5714, // 22/14
                                letterSpacing: 0,
                              ),
                            ),
                            TextSpan(
                              text: 'Entrar',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w500,
                                height: 1.5714, // 22/14
                                letterSpacing: 0,
                              ),
                              recognizer: _goToSignIn,
                            ),
                          ],
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

/// Botão social com fundo #0d0d0d 50%, borda #1a1a1a, raio 20.
class SocialButton extends StatelessWidget {
  const SocialButton({super.key, required this.label, required this.icon});

  final String label;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 342,
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 60),
      decoration: BoxDecoration(
        color: const Color(0x800D0D0D), // #0d0d0d 50%
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1A1A1A), width: 1),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(width: 13),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontFamily: 'Inter',
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

/// Botão "Continue with Email" com fundo #1a1a1a, borda #2c2c2c.
class _EmailButton extends StatelessWidget {
  const _EmailButton({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 342,
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2C2C2C), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: const TextStyle(
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
      ),
    );
  }
}

/// Ícone da Apple (15×18, branco).
class AppleIcon extends StatelessWidget {
  const AppleIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/icons/vector-i66-1790-65-1632.svg',
      width: 15,
      height: 18,
    );
  }
}

/// Logo do Google (SVG completo, 17×17).
class GoogleIcon extends StatelessWidget {
  const GoogleIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/icons/google-logo.svg',
      width: 17,
      height: 17,
    );
  }
}
