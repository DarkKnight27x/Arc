import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/auth_service.dart';
import 'login_page.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({
    super.key,
    required this.auth,
    required this.onDone,
    required this.onHaveAccount,
  });

  final AuthService auth;
  final VoidCallback onDone;
  final VoidCallback onHaveAccount;

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final confirm = TextEditingController();
  bool busy = false;
  String? error;

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (name.text.trim().isEmpty || email.text.trim().isEmpty) {
      setState(() => error = 'Name and email are required.');
      return;
    }
    if (password.text.length < 8) {
      setState(() => error = 'Use at least 8 characters.');
      return;
    }
    if (password.text != confirm.text) {
      setState(() => error = 'Passwords don’t match.');
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.auth.signup(
        email: email.text,
        password: password.text,
        displayName: name.text,
      );
      widget.onDone();
    } on AuthException catch (ex) {
      setState(() => error = ex.message);
    } catch (_) {
      setState(() => error = 'Could not create the account. Try again.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: ColoredBox(
        color: LoginPage.page,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              const Text(
                'ARC',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: LoginPage.ink,
                ),
              ),
              const SizedBox(height: 48),
              const Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Start your\n',
                      style: TextStyle(
                        fontSize: 40,
                        height: 1.05,
                        fontWeight: FontWeight.w500,
                        color: LoginPage.ink,
                      ),
                    ),
                    TextSpan(
                      text: 'ARC.',
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
              const SizedBox(height: 8),
              const Text(
                'A file for training, food and recovery. Not a feed.',
                style: TextStyle(fontSize: 15, color: LoginPage.muted),
              ),
              const SizedBox(height: 24),
              _box('What should we call you?', name, 'Saarthak'),
              const SizedBox(height: 12),
              _box('Email', email, 'you@example.com'),
              const SizedBox(height: 12),
              _box('Password', password, 'At least 8 characters', hide: true),
              const SizedBox(height: 12),
              _box('Confirm password', confirm, 'Repeat it', hide: true),
              if (error != null) ...[
                const SizedBox(height: 12),
                Text(
                  error!,
                  style: const TextStyle(fontSize: 13, color: Color(0xFFB4452C)),
                ),
              ],
              const SizedBox(height: 18),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: busy ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: LoginPage.cta,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                  ),
                  child: Text(
                    busy ? 'Creating…' : 'Create account',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              TextButton(
                onPressed: widget.onHaveAccount,
                child: const Text(
                  'I already have an account',
                  style: TextStyle(color: LoginPage.muted),
                ),
              ),
              const Text(
                'By continuing you get a client profile. ARC does not diagnose injuries.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: LoginPage.faint),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _box(
      String label,
      TextEditingController c,
      String hint, {
        bool hide = false,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: LoginPage.muted),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: c,
          obscureText: hide,
          style: const TextStyle(color: LoginPage.ink),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: LoginPage.faint),
            filled: true,
            fillColor: LoginPage.chip,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
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
      ],
    );
  }
}