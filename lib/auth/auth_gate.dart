import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/profile_service.dart';
import 'forgot_page.dart';
import 'login_page.dart';
import 'onboarding_page.dart';
import 'signup_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key, required this.app});

  final Widget app;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = Supabase.instance.client.auth.currentSession;

        final user = session?.user;

        if (user != null) {
          return _ProfileGate(userId: user.id, app: app);
        }

        return const _AuthPage();
      },
    );
  }
}

class _ProfileGate extends StatefulWidget {
  const _ProfileGate({required this.userId, required this.app});

  final String userId;
  final Widget app;

  @override
  State<_ProfileGate> createState() => _ProfileGateState();
}

class _ProfileGateState extends State<_ProfileGate> {
  late Future<ProfileRow?> _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void didUpdateWidget(covariant _ProfileGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _loadProfile();
    }
  }

  void _loadProfile() {
    _profile = ProfileService(Supabase.instance.client).fetch(widget.userId);
  }

  void _retry() {
    setState(_loadProfile);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ProfileRow?>(
      future: _profile,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Could not load your profile.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _retry,
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final profile = snapshot.data;

        if (profile?.onboardingComplete == true) {
          return widget.app;
        }

        return const OnboardingPage();
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
      return SignupPage(onDone: _showLogin, onHaveAccount: _showLogin);
    }

    if (screen == 'forgot') {
      return ForgotPage(onBack: _showLogin);
    }

    return LoginPage(
      onLoggedIn: () {},
      onCreateAccount: _showSignup,
      onForgot: _showForgot,
    );
  }
}
