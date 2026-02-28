// Automatic FlutterFlow imports
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

bool _isValidEmail(String email) {
  final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  return regex.hasMatch(email);
}

String _sanitizeEmail(String e) {
  final parts = e.split('@');
  if (parts.length != 2) return 'invalid_email';
  return '${parts[0].isNotEmpty ? '***' : ''}@${parts[1]}';
}

// For user-friendly text (what you show to the user)
String _friendlySignInMessage(AuthException e) {
  final msg = (e.message ?? '').toLowerCase();
  final code = (e.code ?? '').toLowerCase();

  // Supabase usually returns a generic message for bad creds.
  // We keep it friendly and clear for the user.
  if (msg.contains('invalid login') ||
      msg.contains('invalid credentials') ||
      msg.contains('invalid email or password') ||
      code == 'invalid_credentials') {
    return 'Incorrect email or password.';
  }

  if (msg.contains('email not confirmed') ||
      msg.contains('not confirmed') ||
      code == 'email_not_confirmed') {
    return 'Please confirm your email before signing in.';
  }

  if (code == 'over_email_send_rate_limit' || msg.contains('rate limit')) {
    return 'Too many attempts. Please wait and try again.';
  }

  // Fallback
  return 'Authentication error. Please try again.';
}

// For branching in Action Flow (stable-ish normalized codes)
String _normalizeSignInCode(AuthException e) {
  final msg = (e.message ?? '').toLowerCase();
  final code = (e.code ?? '').toLowerCase();

  if (msg.contains('invalid login') ||
      msg.contains('invalid credentials') ||
      msg.contains('invalid email or password') ||
      code == 'invalid_credentials') return 'invalid_credentials';

  if (msg.contains('not confirmed') || code == 'email_not_confirmed') {
    return 'email_not_confirmed';
  }

  if (code == 'over_email_send_rate_limit' || msg.contains('rate limit')) {
    return 'rate_limited';
  }

  return code.isNotEmpty ? code : 'auth_error';
}

/// Custom Action: caLogin
/// Params: email (String), password (String)
/// Returns: Map { success: bool, code: String, message: String }
Future<dynamic> caLogin(
  String email,
  String password,
) async {
  final supa = SupaFlow.client; // FlutterFlow’s Supabase client
  final reqId = DateTime.now().microsecondsSinceEpoch.toString();
  final trimmedEmail = email.trim();
  final safeEmail = _sanitizeEmail(trimmedEmail);

  // ---------- Early client-side validation ----------
  if (!_isValidEmail(trimmedEmail)) {
    print('[caLogin][$reqId] Invalid email format: $trimmedEmail');
    return {
      'success': false,
      'code': 'invalid_email',
      'message': 'Please enter a valid email address.',
    };
  }

  if (password.isEmpty) {
    print('[caLogin][$reqId] Empty password');
    return {
      'success': false,
      'code': 'empty_password',
      'message': 'Password is required.',
    };
  }

  print('[caLogin][$reqId] Start sign-in for $safeEmail');

  try {
    final sw = Stopwatch()..start();
    final res = await supa.auth.signInWithPassword(
      email: trimmedEmail,
      password: password,
    );
    sw.stop();

    final user = res.user;
    final session = res.session;

    print('[caLogin][$reqId] signIn finished in ${sw.elapsedMilliseconds}ms '
        '(user: ${user != null}, session: ${session != null})');

    if (user != null && session != null) {
      //print('[caLogin][$reqId] Success. uid=${user.id}');
      // FF “Authenticated User” variables will populate automatically.
      return {
        'success': true,
        'code': 'ok',
        'message': 'Signed in successfully.',
      };
    }

    // Completed without a session → treat as unknown.
    print('[caLogin][$reqId] Warning: signIn returned without session.');
    return {
      'success': false,
      'code': 'no_session',
      'message': 'Sign in did not complete. Please try again.',
    };
  } on AuthException catch (e, st) {
    // Print raw details for debugging; return friendly message to user.
    print(
        '[caLogin][$reqId] AuthException code=${e.code} message=${e.message}');
    print('[caLogin][$reqId] Stack: $st');

    final friendly = _friendlySignInMessage(e);
    final normalized = _normalizeSignInCode(e);

    return {
      'success': false,
      'code': normalized,
      'message': friendly,
    };
  } catch (e, st) {
    print('[caLogin][$reqId] Unexpected error: $e');
    print('[caLogin][$reqId] Stack: $st');
    return {
      'success': false,
      'code': 'unexpected',
      'message': 'Something went wrong. Please try again.',
    };
  }
}
