// Automatic FlutterFlow imports
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!

import 'dart:async';
import 'dart:ui' as ui; // for PlatformDispatcher (works on web)
import 'package:flutter/foundation.dart';
import '/auth/supabase_auth/auth_util.dart';

Future<void> initGlobalErrorLogging() async {
  if (_ErrorHooks.installed) return;
  _ErrorHooks.install();
}

/// Log a caught error to the Supabase Edge Function (app_errors table).
/// Call this from any catch block where the error is handled gracefully
/// but still needs to be recorded for investigation.
Future<void> logCaughtError(
  Object error, {
  StackTrace? stack,
  String? screen,
  Map<String, dynamic>? extra,
}) {
  return _ErrorHooks._sendToEdge(
    errorType: 'CaughtError',
    message: error.toString(),
    stack: stack?.toString(),
    screen: screen,
    extra: extra,
  );
}

class _ErrorHooks {
  static bool installed = false;

  static void install() {
    if (installed) return;

    if (!isProd) {
      print('[ErrorHooks] Installing global error handlers...');
    }

    // 1) Flutter framework (build) errors
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);

      if (!isProd) {
        print(
            '[ErrorHooks] FlutterError caught: ${details.exceptionAsString()}');
        print('[ErrorHooks] Stack: ${details.stack}');
      }

      _sendToEdge(
        errorType: 'FlutterError',
        message: details.exceptionAsString(),
        stack: details.stack?.toString(),
        screen: details.library,
      );
    };

    // 2) Unhandled async/platform errors
    ui.PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      if (!isProd) {
        print('[ErrorHooks] PlatformError caught: $error');
        print('[ErrorHooks] Stack: $stack');
      }

      _sendToEdge(
        errorType: 'PlatformError',
        message: error.toString(),
        stack: stack.toString(),
      );
      return true;
    };

    // 3) Replace red error widget
    ErrorWidget.builder = (FlutterErrorDetails details) {
      if (!isProd) {
        print(
            '[ErrorHooks] ErrorWidget.builder invoked: ${details.exceptionAsString()}');
      }

      return const ColoredBox(
        color: Color(0xFFFFFFFF),
        child: Center(
          child: Text('Something went wrong. Please restart the app.'),
        ),
      );
    };

    installed = true;
  }

  static bool get isProd => kReleaseMode;

  static String get platformName {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.linux:
        return 'linux';
      case TargetPlatform.fuchsia:
        return 'fuchsia';
    }
  }

  static Future<void> _sendToEdge({
    required String errorType,
    required String message,
    String? stack,
    String? screen,
    Map<String, dynamic>? extra,
  }) async {
    try {
      final supa = SupaFlow.client;
      const appVersion =
          String.fromEnvironment('APP_VERSION', defaultValue: 'unknown');

      if (!isProd) {
        print('[ErrorHooks] Sending error to Edge: $errorType | $message');
      }

      await supa.functions.invoke(
        'log-error',
        body: {
          'user_id': currentUserUid,
          'org_id': null,
          'env': isProd ? 'prod' : 'dev',
          'platform': platformName,
          'app_version': appVersion,
          'screen': screen,
          'error_type': errorType,
          'message': message,
          'stack': stack,
          'extra': extra ?? {},
        },
      );

      if (!isProd) {
        print('[ErrorHooks] Error logged successfully.');
      }
    } catch (e) {
      if (!isProd) {
        print('[ErrorHooks] Failed to send error: $e');
      }
    }
  }
}
