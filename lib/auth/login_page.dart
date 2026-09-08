import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    required this.onLoggedIn,
    required this.onCreateAccount,
    required this.onForgot,
  });

  final VoidCallback onLoggedIn;
  final VoidCallback onCreateAccount;
  final VoidCallback onForgot;

  static const page = Color(0xFF050506);
  static const surface = Color(0xFF0C0E12);
  static const chip = Color(0xFF16181E);
  static const line = Color(0xFF2A2C32);
  static const ink = Color(0xFFE8EEF8);
  static const muted = Color(0xFF8B97AB);
  static const faint = Color(0xFF5C6B82);

  // ARC CTA gradient
  static const ctaTop = Color(0xFF4A555B);
  static const ctaMid = Color(0xFF252B2F);
  static const ctaBottom = Color(0xFF3A4449);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final password = TextEditingController();

  bool hide = true;
  bool busy = false;
  String? error;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  void _submit() {
    final e = email.text.trim();
    final p = password.text;

    if (e.isEmpty || p.isEmpty) {
      setState(() {
        error = 'Email and password are required.';
      });
      return;
    }

    // --------------------------------------------------
    // TEMPORARY LOCAL TEST ACCOUNT
    // --------------------------------------------------

    const testEmail = 'test@arc.com';
    const testPassword = 'arc123456';

    if (e == testEmail && p == testPassword) {
      setState(() {
        error = null;
      });

      widget.onLoggedIn();
      return;
    }

    setState(() {
      error = 'That email or password doesn’t match.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: LoginPage.page,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              const Row(
                children: [
                  Text(
                    'ARC',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: LoginPage.ink,
                    ),
                  ),
                  Spacer(),
                  Text(
                    'WELCOME BACK',
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w600,
                      color: LoginPage.faint,
                    ),
                  ),
                  Spacer(),
                  SizedBox(width: 28),
                ],
              ),

              const SizedBox(height: 72),

              const Text(
                'ARC',
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w600,
                  color: LoginPage.faint,
                ),
              ),

              const SizedBox(height: 10),

              const Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Pick up\n',
                      style: TextStyle(
                        fontSize: 40,
                        height: 1.05,
                        fontWeight: FontWeight.w500,
                        color: LoginPage.ink,
                      ),
                    ),
                    TextSpan(
                      text: 'your path.',
                      style: TextStyle(
                        fontSize: 40,
                        height: 1.05,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w500,
                        color: LoginPage.ink,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'You choose the goal. ARC builds the path.',
                style: TextStyle(
                  fontSize: 15,
                  color: LoginPage.muted,
                ),
              ),

              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: LoginPage.surface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: const Color(0x14FFFFFF),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Email',
                      style: TextStyle(
                        fontSize: 13,
                        color: LoginPage.muted,
                      ),
                    ),

                    const SizedBox(height: 6),

                    _Field(
                      controller: email,
                      hint: 'you@example.com',
                      keyboard: TextInputType.emailAddress,
                    ),

                    const SizedBox(height: 14),

                    const Text(
                      'Password',
                      style: TextStyle(
                        fontSize: 13,
                        color: LoginPage.muted,
                      ),
                    ),

                    const SizedBox(height: 6),

                    _Field(
                      controller: password,
                      hint: 'Your ARC password',
                      obscure: hide,
                      onToggle: () {
                        setState(() {
                          hide = !hide;
                        });
                      },
                    ),

                    if (error != null) ...[
                      const SizedBox(height: 12),

                      Text(
                        error!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFFB4452C),
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // ------------------------------------------
                    // PRIMARY CTA
                    // ------------------------------------------

                    Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            LoginPage.ctaTop,
                            LoginPage.ctaMid,
                            LoginPage.ctaBottom,
                          ],
                          stops: [
                            0.0,
                            0.35,
                            1.0,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(999),

                        // Subtle premium glow
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF8FA7B2).withOpacity(0.16),
                            blurRadius: 18,
                            spreadRadius: 0,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(999),
                          onTap: busy ? null : _submit,
                          child: Center(
                            child: Text(
                              busy ? 'Signing in…' : 'Continue  →',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: LoginPage.ink,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ------------------------------------------
              // SECONDARY CTA
              // ------------------------------------------

              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: widget.onCreateAccount,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: LoginPage.ink,
                    side: const BorderSide(
                      color: LoginPage.line,
                    ),
                    backgroundColor: LoginPage.chip,
                    shape: const StadiumBorder(),
                  ),
                  child: const Text(
                    'Create an account',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Center(
                child: TextButton(
                  onPressed: widget.onForgot,
                  child: const Text(
                    'Forgot password?',
                    style: TextStyle(
                      color: LoginPage.muted,
                    ),
                  ),
                ),
              ),

              const Center(
                child: Text(
                  'ARC does not diagnose injuries. Your choices stay yours.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: LoginPage.faint,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.hint,
    this.obscure = false,
    this.onToggle,
    this.keyboard,
  });

  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final VoidCallback? onToggle;
  final TextInputType? keyboard;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboard,
      style: const TextStyle(
        color: LoginPage.ink,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: LoginPage.faint,
        ),
        filled: true,
        fillColor: LoginPage.chip,

        suffixIcon: onToggle == null
            ? null
            : IconButton(
          onPressed: onToggle,
          icon: Icon(
            obscure
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: LoginPage.muted,
            size: 20,
          ),
        ),

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: LoginPage.line,
          ),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: LoginPage.ctaTop,
          ),
        ),
      ),
    );
  }
}