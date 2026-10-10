import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

enum AuthStage {
  loginRequest,
  loginUi,
  signupRequest,
  signupUi,
  passwordReset,
  storageInitialize,
  storageRead,
  storageWrite,
  storageClear,
  authGate,
  profileLoad,
  navigation,
  sessionRefresh,
  logout,
}

/// Debug-only metadata. Never print exception messages, response bodies, URLs,
/// credentials, session objects, identity or profile values.
class AuthDiagnostics {
  static String category(Object error) {
    if (error is TimeoutException) return 'timeout';
    if (error is http.ClientException ||
        error is AuthRetryableFetchException && error.statusCode == null ||
        [
          'SocketException',
          'HandshakeException',
          'TlsException',
          'HttpException',
        ].contains(error.runtimeType.toString())) {
      return 'network';
    }
    if (error is AuthException) return 'auth';
    if (error is PostgrestException) return 'profile_api';
    if (error is PlatformException) return 'platform_storage';
    if (error is FormatException) return 'response_format';
    return 'unexpected';
  }

  @visibleForTesting
  static String formatFailure(
    AuthStage stage,
    Object error, [
    StackTrace? stack,
  ]) {
    final status = error is AuthException ? error.statusCode : null;
    final code = error is AuthException
        ? error.code
        : error is PostgrestException
        ? error.code
        : null;
    const codes = {
      'invalid_credentials',
      'email_not_confirmed',
      'over_request_rate_limit',
      'over_email_send_rate_limit',
      'user_already_exists',
      'weak_password',
      'signup_disabled',
      'session_expired',
      'refresh_token_not_found',
      'refresh_token_already_used',
      'bad_jwt',
      '42501',
      'PGRST116',
      'PGRST301',
      'PGRST302',
      'PGRST303',
    };
    final type = error.runtimeType.toString();
    final safeType = RegExp(r'^[A-Za-z_]{1,60}$').hasMatch(type)
        ? type
        : 'OtherError';
    final safeStatus =
        status != null && RegExp(r'^[1-5][0-9]{2}$').hasMatch(status)
        ? status
        : 'none';
    final frames = stack == null
        ? ''
        : RegExp(r'package:arc/(?:auth|data)/[a-z_]+\.dart:[0-9]+(?::[0-9]+)?')
              .allMatches(stack.toString())
              .take(3)
              .map((m) => m.group(0))
              .join(',');
    return '[ARC_AUTH] stage=${stage.name} category=${category(error)} '
        'type=$safeType status=$safeStatus code=${codes.contains(code) ? code : 'other'}'
        '${frames.isEmpty ? '' : ' frames=$frames'}';
  }

  static void failure(AuthStage stage, Object error, [StackTrace? stack]) {
    if (kDebugMode) debugPrint(formatFailure(stage, error, stack));
  }

  static void event(AuthStage stage, String event) {
    if (kDebugMode && RegExp(r'^[a-z_]{1,40}$').hasMatch(event)) {
      debugPrint('[ARC_AUTH] stage=${stage.name} event=$event');
    }
  }

  static Future<T> trace<T>(
    AuthStage stage,
    Future<T> Function() operation,
  ) async {
    event(stage, 'started');
    try {
      final result = await operation();
      event(stage, 'completed');
      return result;
    } catch (error, stack) {
      failure(stage, error, stack);
      rethrow;
    }
  }

  static String message(Object error, {String action = 'sign in'}) {
    final kind = category(error);
    if (kind == 'timeout') {
      return 'The request took too long. Check your connection and try again.';
    }
    if (kind == 'network') {
      return 'Could not reach ARC. Check your internet connection and try again.';
    }
    if (kind == 'platform_storage') {
      return 'Could not access local session storage. Restart ARC and try again.';
    }
    if (error is AuthException) {
      if (error.code == 'email_not_confirmed') {
        return 'Verify your email before signing in.';
      }
      if (error.code == 'invalid_credentials' ||
          error.statusCode == '400' && action == 'sign in') {
        return 'Could not sign in. Check your email and password, and verify your email.';
      }
      if (error.statusCode == '429' ||
          error.code == 'over_request_rate_limit' ||
          error.code == 'over_email_send_rate_limit') {
        return 'Too many attempts. Please wait and try again.';
      }
      if (error.code == 'user_already_exists') {
        return 'If you already have an account, sign in instead.';
      }
      if (error is AuthRetryableFetchException) {
        return 'ARC is temporarily unavailable. Please try again.';
      }
    }
    return 'Could not $action. Please try again.';
  }
}

class AuthNavigationObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    AuthDiagnostics.event(AuthStage.navigation, 'route_pushed');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    AuthDiagnostics.event(AuthStage.navigation, 'route_popped');
  }
}
