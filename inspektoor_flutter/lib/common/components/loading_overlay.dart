import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LoadingOverlay {
  /// Show an animated loading overlay with waveform bars, pill card,
  /// and bouncing dots over a blurred dark scrim.
  ///
  /// [message] — primary text (e.g. "Preparing inspection…")
  /// [subtitle] — secondary text below the message (e.g. asset name)
  /// [icon] — trailing icon in the pill card
  static void show(
    BuildContext context, {
    String message = 'Loading…',
    String? subtitle,
    IconData? icon,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      builder: (_) => _LoadingOverlayContent(
        message: message,
        subtitle: subtitle,
        icon: icon,
      ),
    );
  }

  /// Dismiss the overlay.
  static void hide(BuildContext context) {
    Navigator.of(context).pop();
  }
}

// ─── Overlay content (stateful for animations) ──────────────────────────────

class _LoadingOverlayContent extends StatefulWidget {
  final String message;
  final String? subtitle;
  final IconData? icon;

  const _LoadingOverlayContent({
    required this.message,
    this.subtitle,
    this.icon,
  });

  @override
  State<_LoadingOverlayContent> createState() => _LoadingOverlayContentState();
}

class _LoadingOverlayContentState extends State<_LoadingOverlayContent>
    with TickerProviderStateMixin {
  static const _kPrimary = Color(0xFF27AAE2);
  static const _kSecText = Color(0xFF57636C);
  static const _kDotGrey = Color(0xFFCBD5E1); // slate-300, muted dots

  // Entry animation (card scale + fade)
  late final AnimationController _entryCtrl;
  late final Animation<double> _entryScale;
  late final Animation<double> _entryOpacity;

  // Waveform bars (4 bars, staggered)
  late final AnimationController _waveCtrl;

  // Bouncing dots (3 dots, staggered)
  late final AnimationController _dotsCtrl;

  // Bar height configs: each bar has its own min/max and phase offset
  static const _barConfigs = [
    (min: 8.0, max: 24.0, begin: 0.0, end: 0.5),
    (min: 12.0, max: 32.0, begin: 0.15, end: 0.65),
    (min: 6.0, max: 20.0, begin: 0.3, end: 0.8),
    (min: 10.0, max: 28.0, begin: 0.5, end: 1.0),
  ];

  @override
  void initState() {
    super.initState();

    // Entry: 400ms ease-out
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _entryScale = Tween(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutBack),
    );
    _entryOpacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut),
    );

    // Waveform: 1.8s loop (relaxed, smooth)
    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    // Dots: 2s loop (gentle pulse)
    _dotsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _waveCtrl.dispose();
    _dotsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: FadeTransition(
        opacity: _entryOpacity,
        child: Stack(
          children: [
            // ── Blurred dark backdrop ───────────────────────────────────
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
                child: Container(color: Colors.black.withValues(alpha: 0.4)),
              ),
            ),
            // ── Centered content ────────────────────────────────────────
            Center(
              child: ScaleTransition(
                scale: _entryScale,
                child: Material(
                  color: Colors.transparent,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildPillCard(),
                      const SizedBox(height: 20),
                      _buildBouncingDots(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Pill card ───────────────────────────────────────────────────────────────

  Widget _buildPillCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Waveform bars
          _buildWaveformBars(),
          const SizedBox(width: 20),
          // Text column
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.message,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1D354F),
                ),
              ),
              if (widget.subtitle != null) ...[
                const SizedBox(height: 3),
                Text(
                  widget.subtitle!,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: _kSecText,
                  ),
                ),
              ],
            ],
          ),
          if (widget.icon != null) ...[
            const SizedBox(width: 20),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _kPrimary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                widget.icon,
                size: 18,
                color: _kPrimary.withValues(alpha: 0.5),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Waveform bars ─────────────────────────────────────────────────────────

  Widget _buildWaveformBars() {
    return AnimatedBuilder(
      animation: _waveCtrl,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(_barConfigs.length, (i) {
            final cfg = _barConfigs[i];
            final t = _waveCtrl.value;

            // Create a staggered sine wave for each bar
            final phase = (t - cfg.begin) / (cfg.end - cfg.begin);
            final clamped = phase.clamp(0.0, 1.0);
            // Sine wave: 0 → 1 → 0
            final sinVal = _pingPong(clamped);
            final height = cfg.min + (cfg.max - cfg.min) * sinVal;

            // Opacity varies slightly with height
            final opacity = 0.4 + 0.6 * sinVal;

            return Padding(
              padding: EdgeInsets.only(left: i == 0 ? 0 : 3),
              child: Container(
                width: 4,
                height: height,
                decoration: BoxDecoration(
                  color: _kPrimary.withValues(alpha: opacity),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  /// Converts a 0→1 value into a 0→1→0 ping-pong curve using sine.
  double _pingPong(double t) {
    return (1 - (2 * t - 1).abs()).clamp(0.0, 1.0);
  }

  // ── Bouncing dots ─────────────────────────────────────────────────────────

  Widget _buildBouncingDots() {
    return AnimatedBuilder(
      animation: _dotsCtrl,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            // Stagger: each dot offset by 0.2
            final offset = i * 0.2;
            final t = (_dotsCtrl.value - offset).clamp(0.0, 1.0);

            // Bounce up then down in the first half of its window
            final bounce = _pingPong((t * 2.5).clamp(0.0, 1.0));
            final scale = 0.6 + 0.4 * bounce;
            final opacity = 0.4 + 0.6 * bounce;

            return Padding(
              padding: EdgeInsets.only(left: i == 0 ? 0 : 8),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _kDotGrey.withValues(alpha: opacity),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
