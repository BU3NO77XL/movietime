import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../widgets/intro_shared.dart';
import 'forgot_password.dart';
import 'sign_up.dart';

/// Tela "Sign in" do Figma (390×844).
///
/// - Fundo preto com dois glows: roxo (topo, blur 300) e ciano (baixo, blur 300)
/// - Título "Welcome back!" + subtítulo "Please login with your number"
/// - Campo de telefone com bandeira (+44), campo de email e campo de senha
/// - Botão "Sign in" (gradiente roxo)
/// - Link "Forgot password?"
class SignIn extends StatefulWidget {
  const SignIn({super.key});

  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  bool _showErrorAlert = true;

  late final TapGestureRecognizer _goToSignUp = TapGestureRecognizer()
    ..onTap = () {
      Navigator.of(context).push(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 450),
          reverseTransitionDuration: const Duration(milliseconds: 450),
          pageBuilder: (_, _, _) => const SignUp(),
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

  late final TapGestureRecognizer _goToForgotPassword = TapGestureRecognizer()
    ..onTap = () {
      Navigator.of(context).push(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 450),
          reverseTransitionDuration: const Duration(milliseconds: 450),
          pageBuilder: (_, _, _) => const ForgotPassword(),
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
    _goToForgotPassword.dispose();
    _goToSignUp.dispose();
    super.dispose();
  }

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

                // Alerta de erro superior (x=24, y=78, 342×50)
                if (_showErrorAlert)
                  Positioned(
                    left: transform.mapX(24),
                    top: transform.mapY(78),
                    child: Transform.scale(
                      scale: transform.scale,
                      alignment: Alignment.topLeft,
                      child: SizedBox(
                        width: 342,
                        height: 50,
                        child: _ErrorAlert(
                          onClose: () =>
                              setState(() => _showErrorAlert = false),
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
                            'Bem-vindo de volta!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                              height: 1.4167, // 34/24
                              letterSpacing: 0,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Entre com seu e-mail e senha',
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

                // Formulário (x=20, y=245)
                Positioned(
                  left: transform.mapX(20),
                  top: transform.mapY(245),
                  child: Transform.scale(
                    scale: transform.scale,
                    alignment: Alignment.topLeft,
                    child: SizedBox(
                      width: 342,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Campo de telefone (desativado/comentado)
                          // _FieldLabel(label: 'Mobile number'),
                          // SizedBox(height: 20),
                          // _PhoneField(),
                          // SizedBox(height: 30),
                          // Email e senha (placeholders internos)
                          const _TextField(
                            hint: 'Ex.: email@example.com',
                            error: true,
                          ),
                          const SizedBox(height: 18),
                          const _PasswordField(),
                          const SizedBox(height: 12),
                          // "Forgot password?" alinhado à direita
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text.rich(
                              TextSpan(
                                text: 'Esqueceu a senha?',
                                style: const TextStyle(
                                  color: Color(0xFF525252),
                                  fontSize: 12,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w500,
                                  height: 1.3333, // 16/12
                                  letterSpacing: 0,
                                ),
                                recognizer: _goToForgotPassword,
                              ),
                            ),
                          ),
                          const SizedBox(height: 26),
                          // Divisor elegante com OR
                          const _OrDivider(),
                          const SizedBox(height: 26),
                          const SocialButton(
                            label: 'Entrar com a Apple',
                            icon: AppleIcon(),
                          ),
                          const SizedBox(height: 13),
                          const SocialButton(
                            label: 'Entrar com o Google',
                            icon: GoogleIcon(),
                          ),
                          const SizedBox(height: 26),
                          // Botão Sign in (342×50)
                          const SizedBox(
                            width: 342,
                            height: 50,
                            child: _SignInButton(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // "Don't have an account? Sign Up" (x=84, y=774)
                Positioned(
                  left: transform.mapX(84),
                  top: transform.mapY(774),
                  child: Transform.scale(
                    scale: transform.scale,
                    alignment: Alignment.topLeft,
                    child: Text.rich(
                      TextSpan(
                        children: [
                          const TextSpan(
                            text: 'Não tem uma conta? ',
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
                            text: 'Cadastre-se',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w500,
                              height: 1.5714, // 22/14
                              letterSpacing: 0,
                            ),
                            recognizer: _goToSignUp,
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

// Label dos campos (removido — placeholders dentro dos inputs).

/// Alerta de erro superior (fundo vermelho #ad2536, raio 10).
class _ErrorAlert extends StatelessWidget {
  const _ErrorAlert({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: const Color(0xFFAD2536),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFAD2536), width: 1.5),
      ),
      child: Row(
        children: [
          // Ícone info-circle (stroke branco)
          const Icon(Icons.info_outline, size: 20, color: Colors.white),
          const SizedBox(width: 10),
          // Texto do alerta
          const Expanded(
            child: Text(
              'Alerta de erro - verifique!',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
                height: 1.3333,
                letterSpacing: 0,
              ),
            ),
          ),
          // Ícone x (fechar)
          InkWell(
            onTap: onClose,
            borderRadius: BorderRadius.circular(10),
            child: const Padding(
              padding: EdgeInsets.all(2),
              child: Icon(Icons.close, size: 20, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

/// Campo de texto genérico (email) editável com placeholder.
class _TextField extends StatefulWidget {
  const _TextField({required this.hint, this.error = false});

  final String hint;
  final bool error;

  @override
  State<_TextField> createState() => _TextFieldState();
}

class _TextFieldState extends State<_TextField> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 342,
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: widget.error ? _fieldErrorDecoration() : _fieldDecoration(),
      alignment: Alignment.centerLeft,
      child: TextField(
        controller: _controller,
        style: TextStyle(
          color: widget.error ? const Color(0xFFAD2536) : Colors.white,
          fontSize: 12,
          fontFamily: 'Inter',
          fontWeight: FontWeight.w500,
          height: 1.3333,
          letterSpacing: 0,
        ),
        keyboardType: TextInputType.emailAddress,
        cursorColor: widget.error ? const Color(0xFFAD2536) : Colors.white,
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          hintText: widget.hint,
          hintStyle: const TextStyle(
            color: Color(0xFF9E9E9E),
            fontSize: 12,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
            height: 1.3333,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

/// Campo de senha com toggle de visibilidade (eye/eye-off).
class _PasswordField extends StatefulWidget {
  const _PasswordField();

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  final TextEditingController _controller = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 342,
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: _fieldDecoration(),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              obscureText: _obscure,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
                height: 1.3333,
                letterSpacing: 0,
              ),
              cursorColor: Colors.white,
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                hintText: 'Senha',
                hintStyle: TextStyle(
                  color: Color(0xFF9E9E9E),
                  fontSize: 12,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                  height: 1.3333,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
          InkWell(
            onTap: () => setState(() => _obscure = !_obscure),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Icon(
                _obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 20,
                color: Colors.white70,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Decoração compartilhada dos campos: fundo #0d0d0d 50%, borda #1a1a1a 1.5,
/// raio 15.
BoxDecoration _fieldDecoration() {
  return BoxDecoration(
    color: const Color(0x800D0D0D), // #0d0d0d 50%
    borderRadius: BorderRadius.circular(15),
    border: Border.all(color: const Color(0xFF1A1A1A), width: 1.5),
  );
}

/// Decoração do campo em estado de erro: borda vermelha #ad2536 1.5, raio 15.
BoxDecoration _fieldErrorDecoration() {
  return BoxDecoration(
    color: const Color(0x800D0D0D), // #0d0d0d 50%
    borderRadius: BorderRadius.circular(15),
    border: Border.all(color: const Color(0xFFAD2536), width: 1.5),
  );
}

/// Divisor elegante com texto "OR" no centro (linha 1px + label).
class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 342,
      child: Row(
        children: [
          const Expanded(child: Divider(color: Color(0xFF2C2C2C), height: 1)),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 18),
            child: Text(
              'OU',
              style: TextStyle(
                color: Color(0xFF525252),
                fontSize: 12,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
                height: 1.3333, // 16/12
                letterSpacing: 0,
              ),
            ),
          ),
          const Expanded(child: Divider(color: Color(0xFF2C2C2C), height: 1)),
        ],
      ),
    );
  }
}

/// Botão primário "Sign in" (gradiente roxo + sombra).
class _SignInButton extends StatelessWidget {
  const _SignInButton();

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
          'Entrar',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
            height: 1.57,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}
