import 'package:flutter/material.dart';

import '../data/auth_service.dart';
import 'login_page.dart';

class ForgotPage extends StatefulWidget {
  const ForgotPage({super.key, required this.auth, required this.onBack});

  final AuthService auth;
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
    if (email.text.trim().isEmpty) return;
    try {
      await widget.auth.sendReset(email.text);
    } catch (_) {}
    setState(() {
      note = 'If that inbox exists, a reset mail is on the way.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: LoginPage.page,
      child: SafeArea(
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
                style: TextStyle(color: LoginPage.muted),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: email,
                style: const TextStyle(color: LoginPage.ink),
                decoration: InputDecoration(
                  hintText: 'you@example.com',
                  hintStyle: const TextStyle(color: LoginPage.faint),
                  filled: true,
                  fillColor: LoginPage.chip,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: LoginPage.line),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: LoginPage.cta),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _send,
                  style: FilledButton.styleFrom(
                    backgroundColor: LoginPage.cta,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                  ),
                  child: const Text('Send reset link'),
                ),
              ),
              if (note != null) ...[
                const SizedBox(height: 12),
                Text(note!, style: const TextStyle(color: LoginPage.muted)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}