import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'forgot_page.dart';
import 'login_page.dart';
import 'signup_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({
    super.key,
    required this.app,
  });

  final Widget app;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session =
            Supabase.instance.client.auth.currentSession;

        if (session != null) {
          return app;
        }

        return const _AuthPage();
      },
    );
  }
}

class _AuthPage extends StatefulWidget {
  const _AuthPage();

  @override
  State<_AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<_AuthPage> {
  String screen = 'login';

  void _showLogin() {
    setState(() {
      screen = 'login';
    });
  }

  void _showSignup() {
    setState(() {
      screen = 'signup';
    });
  }

  void _showForgot() {
    setState(() {
      screen = 'forgot';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (screen == 'signup') {
      return SignupPage(
        onDone: _showLogin,
        onHaveAccount: _showLogin,
      );
    }

    if (screen == 'forgot') {
      return ForgotPage(
        onBack: _showLogin,
      );
    }

    return LoginPage(
      onLoggedIn: () {},
      onCreateAccount: _showSignup,
      onForgot: _showForgot,
    );
  }
}