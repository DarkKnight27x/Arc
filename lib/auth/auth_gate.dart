import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/profile_service.dart';
import '../data/auth_service.dart';
import '../data/auth_diagnostics.dart';
import 'forgot_page.dart';
import 'login_page.dart';
import 'onboarding_page.dart';
import 'signup_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key, required this.app, this.auth, this.profiles});

  final Widget app;
  final AuthService? auth;
  final ProfileService? profiles;

  @override
  Widget build(BuildContext context) {
    final service = auth ?? AuthService(Supabase.instance.client);
    return StreamBuilder<AuthState>(
      stream: service.onAuth,
      builder: (context, snapshot) {
        try {
          if (snapshot.hasError) {
            AuthDiagnostics.failure(
              AuthStage.authGate,
              snapshot.error!,
              snapshot.stackTrace,
            );
          }
          final session = service.session;

          final user = session?.user;

          if (user != null) {
            if (session!.isExpired || snapshot.hasError) {
              AuthDiagnostics.event(AuthStage.authGate, 'session_recovery');
              return _SessionRecovery(auth: service);
            }
            return _ProfileGate(
              key: ValueKey(user.id),
              userId: user.id,
              app: app,
              auth: service,
              profiles: profiles ?? ProfileService(Supabase.instance.client),
            );
          }

          AuthDiagnostics.event(AuthStage.authGate, 'signed_out');
          return _AuthPage(auth: service);
        } catch (err, stack) {
          AuthDiagnostics.failure(AuthStage.authGate, err, stack);
          return const Scaffold(
            body: Center(
              child: Text(
                'Could not check your sign-in status. Please restart ARC.',
              ),
            ),
          );
        }
      },
    );
  }
}

class _ProfileGate extends StatefulWidget {
  const _ProfileGate({
    super.key,
    required this.userId,
    required this.app,
    required this.auth,
    required this.profiles,
  });

  final String userId;
  final Widget app;
  final AuthService auth;
  final ProfileService profiles;

  @override
  State<_ProfileGate> createState() => _ProfileGateState();
}

class _ProfileGateState extends State<_ProfileGate> {
  late Future<ProfileRow?> _profile;
  final _appNavigator = GlobalKey<NavigatorState>();
  final _navigationObserver = AuthNavigationObserver();

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
    _profile = AuthDiagnostics.trace(AuthStage.profileLoad, () async {
      final profile = await widget.profiles
          .fetch(widget.userId)
          .timeout(const Duration(seconds: 20));
      if (profile == null) {
        AuthDiagnostics.event(AuthStage.profileLoad, 'missing_row');
      }
      return profile;
    });
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

        if (snapshot.hasError ||
            snapshot.data == null ||
            snapshot.data?.userId != widget.userId) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      snapshot.hasError ? 'Could not load your profile.' : 'Your profile is not available yet. Please retry or sign in again.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _retry,
                      child: const Text('Try again'),
                    ),
                    TextButton(
                      onPressed: () async {
                        try {
                          await widget.auth.logout();
                        } catch (_) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Could not sign out. Please retry.',
                                ),
                              ),
                            );
                          }
                        }
                      },
                      child: const Text('Sign out'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final profile = snapshot.data;

        if (profile?.onboardingComplete == true) {
          AuthDiagnostics.event(AuthStage.authGate, 'profile_complete');
          // Routes pushed by the signed-in app are disposed with this identity.
          return NavigatorPopHandler<Object?>(
            onPopWithResult: (result) =>
                _appNavigator.currentState?.pop(result),
            child: Navigator(
              key: _appNavigator,
              observers: [_navigationObserver],
              onGenerateRoute: (_) {
                try {
                  return MaterialPageRoute<void>(builder: (_) => widget.app);
                } catch (err, stack) {
                  AuthDiagnostics.failure(AuthStage.navigation, err, stack);
                  rethrow;
                }
              },
            ),
          );
        }
        AuthDiagnostics.event(AuthStage.authGate, 'onboarding_required');
        return OnboardingPage(
          key: ValueKey(widget.userId),
          userId: widget.userId,
          service: widget.profiles,
          onSignOut: widget.auth.logout,
          onComplete: _retry,
        );
      },
    );
  }
}

class _AuthPage extends StatefulWidget {
  const _AuthPage({required this.auth});
  final AuthService auth;

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
        auth: widget.auth,
        onDone: _showLogin,
        onHaveAccount: _showLogin,
      );
    }

    if (screen == 'forgot') {
      return ForgotPage(onBack: _showLogin);
    }

    return LoginPage(
      auth: widget.auth,
      onLoggedIn: () {},
      onCreateAccount: _showSignup,
      onForgot: _showForgot,
    );
  }
}

class _SessionRecovery extends StatefulWidget {
  const _SessionRecovery({required this.auth});
  final AuthService auth;
  @override
  State<_SessionRecovery> createState() => _SessionRecoveryState();
}

class _SessionRecoveryState extends State<_SessionRecovery> {
  late Future<AuthResponse> _refresh;
  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    _refresh = AuthDiagnostics.trace(
      AuthStage.sessionRefresh,
      () => widget.auth.refresh().timeout(const Duration(seconds: 20)),
    );
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<AuthResponse>(
    future: _refresh,
    builder: (context, snapshot) => Scaffold(
      body: Center(
        child: snapshot.connectionState != ConnectionState.done
            ? const CircularProgressIndicator()
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Could not restore your session. Please retry or sign in again.',
                  ),
                  FilledButton(
                    onPressed: () => setState(_start),
                    child: const Text('Try again'),
                  ),
                  TextButton(
                    onPressed: () async {
                      try {
                        await widget.auth.logout();
                      } catch (_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Could not sign out. Please retry.',
                              ),
                            ),
                          );
                        }
                      }
                    },
                    child: const Text('Sign out'),
                  ),
                ],
              ),
      ),
    ),
  );
}
