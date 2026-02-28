// Automatic FlutterFlow imports
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import '/custom_code/actions/index.dart'; // Imports custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'dart:collection';

class Snackbar extends StatefulWidget {
  const Snackbar({
    super.key,
    this.width,
    this.height,
  });

  /// width = optional max width of snackbar
  /// height = optional fixed height of snackbar
  final double? width;
  final double? height;

  @override
  _SnackbarState createState() => _SnackbarState();
}

class _SnackbarState extends State<Snackbar> with TickerProviderStateMixin {
  final Queue<_SnackbarRequest> _queue = Queue();
  bool _isShowing = false;
  int _lastTrigger = -1;

  AnimationController? _controller;
  Animation<double>? _fade;
  Animation<Offset>? _slide;

  String _message = "";
  Color _bg = Colors.black87;
  Color _textColor = Colors.white;

  @override
  void initState() {
    super.initState();
    //print("Snackbar widget MOUNTED");
    FFAppState().addListener(_onAppStateChanged);
  }

  @override
  void dispose() {
    FFAppState().removeListener(_onAppStateChanged);
    _controller?.dispose();
    super.dispose();
  }

  void _onAppStateChanged() {
    //print("AppState changed");
    final trigger = FFAppState().snackbarTrigger;

    if (trigger != _lastTrigger) {
      //print("Snackbar widget received new trigger: $trigger");
      _lastTrigger = trigger;

      _enqueue(
        _SnackbarRequest(
          text: FFAppState().snackbarMessage,
          durationMs: FFAppState().snackbarDurationMs,
          bg: FFAppState().snackbarBg,
          textColor: FFAppState().snackbarText,
        ),
      );
    }
  }

  void _enqueue(_SnackbarRequest req) {
    _queue.add(req);
    if (!_isShowing) {
      _processQueue();
    }
  }

  Future<void> _processQueue() async {
    if (!mounted || _queue.isEmpty) return;

    _isShowing = true;
    final req = _queue.removeFirst();

    //print("Processing request: ${req.text}");

    // BUILD ANIMATION CONTROLLER
    _controller?.dispose();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      reverseDuration: const Duration(milliseconds: 220),
    );

    // Fading animation (0 → 1)
    _fade = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller!, curve: Curves.easeOut),
    );

    // Slide animation - similar to FlutterFlow preset
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.10), // about 50px down
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller!, curve: Curves.easeOut),
    );

    setState(() {
      _message = req.text;
      _bg = req.bg;
      _textColor = req.textColor;
    });

    // Animate in
    if (mounted) await _controller!.forward();
    //print("Fade-in complete");

    // Visible for duration
    if (mounted) await Future.delayed(Duration(milliseconds: req.durationMs));
    //print("Hold complete");

    // Animate out
    if (mounted) await _controller!.reverse();
    //print("Fade-out complete");

    if (mounted) {
      setState(() => _message = "");
    }

    _isShowing = false;

    if (_queue.isNotEmpty) {
      _processQueue();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_message.isEmpty) {
      return const SizedBox.shrink();
    }

    // Wrap in AnimatedBuilder to update on every frame
    return AnimatedBuilder(
      animation: _controller!,
      builder: (_, __) {
        final fadeVal = _fade?.value ?? 0.0;
        return Opacity(
          opacity: fadeVal,
          child: SlideTransition(
            position: _slide ?? AlwaysStoppedAnimation<Offset>(Offset.zero),
            child: Container(
              width: widget.width,
              height: widget.height,
              padding: const EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 16,
              ),
              decoration: BoxDecoration(
                color: _bg,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text(
                _message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _textColor,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SnackbarRequest {
  final String text;
  final int durationMs;
  final Color bg;
  final Color textColor;

  _SnackbarRequest({
    required this.text,
    required this.durationMs,
    required this.bg,
    required this.textColor,
  });
}
