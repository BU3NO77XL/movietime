import 'dart:ui';

import 'package:animations/animations.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../widgets/intro_shared.dart';
import 'recommendation.dart';
import 'sign_in.dart';

/// Tela "Sign up-email" do Figma (390×844).
///
/// - Fundo preto com dois glows: roxo (topo, blur 300) e ciano (baixo, blur 300)
/// - Título "Sign up with Email" + subtítulo "Please login with your number"
/// - Campos: Full name, Email address, Password (com ícone eye-off)
/// - Checkbox de termos + botão "Sign up" (gradiente roxo)
/// - Link "Already have an account? Sign In"
class SignUpEmail extends StatefulWidget {
  const SignUpEmail({super.key});

  @override
  State<SignUpEmail> createState() => _SignUpEmailState();
}

class _SignUpEmailState extends State<SignUpEmail> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _agreeTerms = false;

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
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _goToSignIn.dispose();
    super.dispose();
  }

  void _simulateSignUp() {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    String? error;
    if (name.isEmpty && email.isEmpty && password.isEmpty) {
      error = 'Preencha seu nome completo, e-mail e senha.';
    } else if (name.isEmpty) {
      error = 'Digite seu nome completo.';
    } else if (email.isEmpty || !email.contains('@')) {
      error = 'Digite um endereço de e-mail válido.';
    } else if (password.isEmpty) {
      error = 'Digite uma senha.';
    } else if (!_agreeTerms) {
      error = 'Você deve concordar com os Termos de Serviço.';
    }

    if (error != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: const Color(0xFFAD2536),
            behavior: SnackBarBehavior.floating,
          ),
        );
      return;
    }

    // Conta simulada criada. Mostra um feedback rápido e segue o fluxo.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Conta "$name" criada com sucesso!'),
        backgroundColor: const Color(0xFF2E8B57),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1200),
      ),
    );

    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        reverseTransitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, _, _) => const ControlRecomendation(),
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
                            'Cadastre-se com e-mail',
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
                            'Crie sua conta com e-mail',
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

                // Formulário (x=24, y=287, 342×347)
                Positioned(
                  left: transform.mapX(24),
                  top: transform.mapY(287),
                  child: Transform.scale(
                    scale: transform.scale,
                    alignment: Alignment.topLeft,
                    child: SizedBox(
                      width: 342,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Campos
                          SizedBox(
                            width: 342,
                            child: Column(
                              children: [
                                _InputField(
                                  label: 'Nome completo',
                                  controller: _nameController,
                                ),
                                SizedBox(height: 15),
                                _InputField(
                                  label: 'Ex.: email@example.com',
                                  controller: _emailController,
                                  error: true,
                                  errorText:
                                      'O endereço de e-mail está incorreto.',
                                ),
                                SizedBox(height: 15),
                                _PasswordField(
                                  controller: _passwordController,
                                  error: true,
                                ),
                                SizedBox(height: 15),
                                _TermsCheckbox(
                                  checked: _agreeTerms,
                                  onChanged: (value) =>
                                      setState(() => _agreeTerms = value),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 40),
                          // Botão Sign up (342×50)
                          _SignUpButton(onTap: _simulateSignUp),
                        ],
                      ),
                    ),
                  ),
                ),

                // "Already have an account? Sign In" (y=774, centralizado)
                Positioned(
                  left: 0,
                  right: 0,
                  top: transform.mapY(774),
                  child: Transform.scale(
                    scale: transform.scale,
                    alignment: Alignment.topCenter,
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

/// Campo de input com borda #2c2c2c, raio 15, padding 20/100.
class _InputField extends StatelessWidget {
  const _InputField({
    required this.label,
    required this.controller,
    this.error = false,
    this.errorText,
  });

  final String label;
  final TextEditingController controller;
  final bool error;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 342,
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: error ? const Color(0xFFAD2536) : const Color(0xFF2C2C2C),
              width: 1,
            ),
          ),
          alignment: Alignment.centerLeft,
          child: TextField(
            controller: controller,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
              height: 1.3333, // 16/12
              letterSpacing: 0,
            ),
            cursorColor: Colors.white,
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              hintText: label,
              hintStyle: const TextStyle(
                color: Color(0xFF9E9E9E),
                fontSize: 12,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
                height: 1.3333, // 16/12
                letterSpacing: 0,
              ),
            ),
          ),
        ),
        if (error && errorText != null) ...[
          const SizedBox(height: 10),
          Text(
            errorText!,
            style: const TextStyle(
              color: Color(0xFFFF4C61),
              fontSize: 10,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
              height: 1.6, // 16/10
              letterSpacing: 0,
            ),
          ),
        ],
      ],
    );
  }
}

/// Campo de senha com ícone "eye" (olho aberto) à direita e toggle.
class _PasswordField extends StatefulWidget {
  const _PasswordField({required this.controller, this.error = false});

  final TextEditingController controller;
  final bool error;

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 342,
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: widget.error
                  ? const Color(0xFFAD2536)
                  : const Color(0xFF2C2C2C),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  obscureText: _obscure,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                    height: 1.3333, // 16/12
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
                      height: 1.3333, // 16/12
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 13),
              InkWell(
                onTap: () => setState(() => _obscure = !_obscure),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Icon(
                    _obscure ? Icons.visibility_off : Icons.visibility,
                    size: 20,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (widget.error) ...[
          const SizedBox(height: 10),
          const Text(
            'Está fraca! Digite uma combinação de números, letras e...',
            style: TextStyle(
              color: Color(0xFFFF4C61),
              fontSize: 10,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
              height: 1.6, // 16/10
              letterSpacing: 0,
            ),
          ),
        ],
      ],
    );
  }
}

/// Checkbox + texto de termos (marcável/desmarcável).
class _TermsCheckbox extends StatelessWidget {
  const _TermsCheckbox({required this.checked, required this.onChanged});

  final bool checked;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 315,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Checkbox 26×26, borda #525252, raio 6, com check quando selecionado
          InkWell(
            onTap: () => onChanged(!checked),
            borderRadius: BorderRadius.circular(6),
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(6)),
                border: Border.fromBorderSide(
                  const BorderSide(color: Color(0xFF525252), width: 1),
                ),
              ),
              child: checked
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 17),
          const Expanded(
            child: Text(
              'Concordo com os Termos de Serviço, a Política de Privacidade e as Configurações de Notificação padrão do Movietime.',
              style: TextStyle(
                color: Color(0xFF9E9E9E),
                fontSize: 10,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
                height: 1.6, // 16/10
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Botão "Sign up" com gradiente roxo e sombra.
class _SignUpButton extends StatelessWidget {
  const _SignUpButton({this.onTap});

  final VoidCallback? onTap;

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
          child: const Center(
            child: Text(
              'Cadastre-se',
              style: TextStyle(
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
    );
  }
}
