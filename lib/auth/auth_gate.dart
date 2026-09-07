import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/auth_service.dart';
import '../data/profile_service.dart';
import 'forgot_page.dart';
import 'login_page.dart';
import 'signup_page.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key, required this.app});

  final Widget app;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final AuthService auth;
  late final ProfileService profiles;
  String screen = 'login';

  @override
  void initState() {
    super.initState();
    final client = Supabase.instance.client;
    profiles = ProfileService(client);
    auth = AuthService(client, profiles);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = Supabase.instance.client.auth.currentSession;
        if (session != null) return widget.app;

        if (screen == 'signup') {
          return SignupPage(
            auth: auth,
            onDone: () => setState(() => screen = 'login'),
            onHaveAccount: () => setState(() => screen = 'login'),
          );
        }
        if (screen == 'forgot') {
          return ForgotPage(
            auth: auth,
            onBack: () => setState(() => screen = 'login'),
          );
        }
        return LoginPage(
          auth: auth,
          onLoggedIn: () {},
          onCreateAccount: () => setState(() => screen = 'signup'),
          onForgot: () => setState(() => screen = 'forgot'),
        );
      },
    );
  }
}