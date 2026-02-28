// Automatic FlutterFlow imports
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

String _sanitizeEmail(String e) {
  final parts = e.split('@');
  if (parts.length != 2) return 'invalid_email';
  return '${parts[0].isNotEmpty ? '***' : ''}@${parts[1]}';
}

bool _isValidEmail(String email) {
  final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  return regex.hasMatch(email);
}

String _mapAuthError(AuthException e) {
  final code = (e.code ?? '').toLowerCase();
  final msg = (e.message ?? '').toLowerCase();

  if (msg.contains('user already registered') ||
      code == 'user_already_exists') {
    return 'This email is already registered. Try signing in or resetting your password.';
  }
  if (msg.contains('invalid email')) {
    return 'Please enter a valid email address.';
  }
  if (msg.contains('weak') && msg.contains('password')) {
    return 'Password is too weak. Use at least 8 characters with a mix of letters and numbers.';
  }
  if (code == 'over_email_send_rate_limit' || msg.contains('rate limit')) {
    return 'Too many attempts. Please wait and try again.';
  }
  return e.message ?? 'Authentication error. Please try again.';
}

/// Custom Action
/// Params: email (String), password (String), confirmPassword (String)
/// Returns: Map { success: bool, code: String, message: String }
Future<dynamic> caCreateAccount(
  String email,
  String password,
  String confirmPassword,
) async {
  final supa = SupaFlow.client; // FlutterFlow’s Supabase client
  final reqId = DateTime.now().microsecondsSinceEpoch.toString();
  final trimmedEmail = email.trim();
  final safeEmail = _sanitizeEmail(trimmedEmail);

  // ---------- Early client-side validation ----------
  // Email format
  if (!_isValidEmail(trimmedEmail)) {
    print('[caCreateAccount][$reqId] Invalid email format: $trimmedEmail');
    return {
      'success': false,
      'code': 'invalid_email',
      'message': 'Please enter a valid email address.'
    };
  }

  // Password presence
  if (password.isEmpty || confirmPassword.isEmpty) {
    print('[caCreateAccount][$reqId] Empty password or confirmPassword');
    return {
      'success': false,
      'code': 'empty_password',
      'message': 'Password and Confirm Password are required.'
    };
  }

  // Password match
  if (password != confirmPassword) {
    print('[caCreateAccount][$reqId] Passwords do not match');
    return {
      'success': false,
      'code': 'password_mismatch',
      'message': 'Passwords do not match. Please re-enter them.'
    };
  }

  // Basic password policy (adjust if you enforce stronger rules)
  if (password.length < 8) {
    print('[caCreateAccount][$reqId] Password too short');
    return {
      'success': false,
      'code': 'weak_password',
      'message': 'Password is too short. Use at least 8 characters.'
    };
  }

  print('[caCreateAccount][$reqId] Start sign-up for $safeEmail');

  try {
    final sw = Stopwatch()..start();
    final res = await supa.auth.signUp(
      email: trimmedEmail,
      password: password,
    );
    sw.stop();

    print(
        '[caCreateAccount][$reqId] signUp finished in ${sw.elapsedMilliseconds}ms '
        '(user: ${res.user != null}, session: ${res.session != null})');

    if (res.user != null) {
      final needsConfirm = res.session == null;
      print(
          '[caCreateAccount][$reqId] Success. needsEmailConfirm=$needsConfirm');
      return {
        'success': true,
        'code': 'ok',
        'message': needsConfirm
            ? 'Account created. Check your email to confirm your address.'
            : 'Account created successfully.'
      };
    }

    // Returned without a user → treat as unknown failure.
    print('[caCreateAccount][$reqId] Warning: signUp returned user == null');
    return {
      'success': false,
      'code': 'unknown',
      'message': 'Sign up did not complete. Please try again.'
    };
  } on AuthException catch (e, st) {
    print(
        '[caCreateAccount][$reqId] AuthException code=${e.code} message=${e.message}');
    print('[caCreateAccount][$reqId] Stack: $st');
    final friendly = _mapAuthError(e);
    return {
      'success': false,
      'code': e.code ?? 'auth_error',
      'message': friendly
    };
  } catch (e, st) {
    print('[caCreateAccount][$reqId] Unexpected error: $e');
    print('[caCreateAccount][$reqId] Stack: $st');
    return {
      'success': false,
      'code': 'unexpected',
      'message': 'Something went wrong. Please try again.'
    };
  }
}
