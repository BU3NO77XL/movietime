import 'dart:ui';

import 'package:flutter/material.dart';

import '../widgets/intro_shared.dart';

/// Tela "Forgot password" do Figma (390×844).
///
/// - Fundo preto com dois glows: roxo (topo, blur 300) e ciano (baixo, blur 300)
/// - Botão voltar (chevron-left) + título "Forgot password"
/// - Título "Set password" + subtítulo "Let's create your profile"
/// - Campos: New password, Confirm new password (com eye-off)
/// - Botão "Continue" (gradiente roxo) + link "Cancel"
class ForgotPassword extends StatelessWidget {
  const ForgotPassword({super.key});

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: Scaffold(
        backgroundColor: const Color(0xFF0D0D0D),
        resizeToAvoidBottomInset: false,
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
                          imageFilter: ImageFilter.blur(
                            sigmaX: 300,
                            sigmaY: 300,
                          ),
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
                          imageFilter: ImageFilter.blur(
                            sigmaX: 300,
                            sigmaY: 300,
                          ),
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

                    // Botão voltar (x=24, y=74, 40×40)
                    Positioned(
                      left: transform.mapX(24),
                      top: transform.mapY(74),
                      child: Transform.scale(
                        scale: transform.scale,
                        alignment: Alignment.topLeft,
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF1A1A1A), Color(0x330D0D0D)],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.chevron_left,
                              size: 20,
                              color: Color(0xFF9E9E9E),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Título "Forgot password" (x=131, y=82)
                    Positioned(
                      left: transform.mapX(131),
                      top: transform.mapY(82),
                      child: Transform.scale(
                        scale: transform.scale,
                        alignment: Alignment.topLeft,
                        child: const Text(
                          'Esqueceu a senha',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontFamily: 'Netflix Sans',
                            fontWeight: FontWeight.w500,
                            height: 1.5, // 24/16
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                    ),

                    // Título central (x=95, y=171.465, 200×61)
                    Positioned(
                      left: transform.mapX(95),
                      top: transform.mapY(171.465),
                      child: Transform.scale(
                        scale: transform.scale,
                        alignment: Alignment.topLeft,
                        child: const SizedBox(
                          width: 200,
                          child: Column(
                            children: [
                              Text(
                                'Definir senha',
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
                                'Vamos criar o seu perfil',
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

                    // Formulário (x=24, y=313, 342×218)
                    Positioned(
                      left: transform.mapX(24),
                      top: transform.mapY(313),
                      child: Transform.scale(
                        scale: transform.scale,
                        alignment: Alignment.topLeft,
                        child: const SizedBox(
                          width: 342,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // New password
                              _FieldLabel(label: 'Nova senha'),
                              SizedBox(height: 10),
                              _PasswordField(),
                              SizedBox(height: 10),
                              Text(
                                'Digite pelo menos 8 caracteres',
                                style: TextStyle(
                                  color: Color(0xFF525252),
                                  fontSize: 10,
                                  fontFamily: 'Netflix Sans',
                                  fontWeight: FontWeight.w400,
                                  height: 1.6, // 16/10
                                  letterSpacing: 0,
                                ),
                              ),
                              SizedBox(height: 20),
                              // Confirm new password
                              _FieldLabel(label: 'Confirmar nova senha'),
                              SizedBox(height: 10),
                              _PasswordField(),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Botão Continue (x=24, y=706, 342×50)
                    Positioned(
                      left: transform.mapX(24),
                      top: transform.mapY(706),
                      child: Transform.scale(
                        scale: transform.scale,
                        alignment: Alignment.topLeft,
                        child: const SizedBox(
                          width: 342,
                          height: 50,
                          child: _ContinueButton(),
                        ),
                      ),
                    ),

                    // "Cancel" (x=172, y=774)
                    Positioned(
                      left: transform.mapX(172),
                      top: transform.mapY(774),
                      child: Transform.scale(
                        scale: transform.scale,
                        alignment: Alignment.topLeft,
                        child: const Text(
                          'Cancelar',
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

/// Label dos campos (branco, Inter Medium 12).
class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontFamily: 'Netflix Sans',
        fontWeight: FontWeight.w500,
        height: 1.3333, // 16/12
        letterSpacing: 0,
      ),
    );
  }
}

/// Campo de senha com eye-off.
class _PasswordField extends StatelessWidget {
  const _PasswordField();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 342,
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF2C2C2C), width: 1),
      ),
      child: const Row(
        children: [
          Expanded(
            child: Text(
              '••••••••',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontFamily: 'Netflix Sans',
                fontWeight: FontWeight.w500,
                height: 1.3333,
                letterSpacing: 0,
              ),
            ),
          ),
          Icon(Icons.visibility_off_outlined, size: 20, color: Colors.white70),
        ],
      ),
    );
  }
}

/// Botão "Continue" com gradiente roxo e sombra.
class _ContinueButton extends StatelessWidget {
  const _ContinueButton();

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: const Center(
        child: Text(
          'Continuar',
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
    );
  }
}
