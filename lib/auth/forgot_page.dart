import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'login_page.dart';

class ForgotPage extends StatefulWidget {
  const ForgotPage({
    super.key,
    required this.onBack,
  });

  final VoidCallback onBack;

  @override
  State<ForgotPage> createState() => _ForgotPageState();
}

class _ForgotPageState extends State<ForgotPage> {
  final email = TextEditingController();

  String? note;

  @override
  void dispose() {
    email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final userEmail = email.text.trim();

    if (userEmail.isEmpty) {
      setState(() {
        note = 'Enter your email first.';
      });
      return;
    }

    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        userEmail,
      );

      if (!mounted) return;

      setState(() {
        note =
        'If that email exists, a reset link has been sent.';
      });
    } on AuthException catch (err) {
      setState(() {
        note = err.message;
      });
    } catch (_) {
      setState(() {
        note = 'Something went wrong. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LoginPage.page,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextButton(
                onPressed: widget.onBack,
                child: const Text('Back'),
              ),

              const SizedBox(height: 24),

              const Text(
                'Reset the password.',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w500,
                  color: LoginPage.ink,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'If that inbox exists, a reset mail is on the way.',
                style: TextStyle(
                  color: LoginPage.muted,
                ),
              ),

              const SizedBox(height: 20),

              TextField(
                controller: email,
                style: const TextStyle(
                  color: LoginPage.ink,
                ),
                decoration: InputDecoration(
                  hintText: 'you@example.com',
                  hintStyle: const TextStyle(
                    color: LoginPage.faint,
                  ),
                  filled: true,
                  fillColor: LoginPage.chip,

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

                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                ),
              ),

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
                    onTap: _send,
                    child: const Center(
                      child: Text(
                        'Send reset link',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: LoginPage.ink,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              if (note != null) ...[
                const SizedBox(height: 12),

                Text(
                  note!,
                  style: const TextStyle(
                    color: LoginPage.muted,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}