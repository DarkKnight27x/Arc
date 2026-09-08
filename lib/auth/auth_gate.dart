import 'package:flutter/material.dart';

import 'forgot_page.dart';
import 'login_page.dart';
import 'signup_page.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({
    super.key,
    required this.app,
  });

  final Widget app;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool loggedIn = false;
  String screen = 'login';

  void _login() {
    setState(() {
      loggedIn = true;
    });
  }

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
    // User is logged in → show the actual ARC app.
    if (loggedIn) {
      return widget.app;
    }

    // Signup
    if (screen == 'signup') {
      return SignupPage(
        onDone: _showLogin,
        onHaveAccount: _showLogin,
      );
    }

    // Forgot password
    if (screen == 'forgot') {
      return ForgotPage(
        onBack: _showLogin,
      );
    }

    // Login
    return LoginPage(
      onLoggedIn: _login,
      onCreateAccount: _showSignup,
      onForgot: _showForgot,
    );
  }
}