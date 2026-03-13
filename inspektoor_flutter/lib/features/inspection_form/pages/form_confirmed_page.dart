import 'package:flutter/material.dart';

import 'form_flow_tokens.dart';
import 'form_search_page.dart';

// ─── Screen 4 — Confirmed ─────────────────────────────────────────────────────
///
/// Shown after the user taps "Use This Form" on [FormDetailsPage].
/// Animated green checkmark, form summary, and two CTAs:
///   • Start Inspection — proceeds to the inspection flow (wiring TBD)
///   • Change Form      — pops back to [FormSearchPage]
class FormConfirmedPage extends StatefulWidget {
  final Map<String, dynamic> form;
  final List<Map<String, dynamic>> schemaItems;

  const FormConfirmedPage({
    super.key,
    required this.form,
    required this.schemaItems,
  });

  @override
  State<FormConfirmedPage> createState() => _FormConfirmedPageState();
}

class _FormConfirmedPageState extends State<FormConfirmedPage>
    with TickerProviderStateMixin {
  late final AnimationController _ringCtrl;
  late final AnimationController _checkCtrl;
  late final AnimationController _contentCtrl;

  late final Animation<double> _ringScale;
  late final Animation<double> _checkScale;
  late final Animation<double> _contentOpacity;
  late final Animation<Offset> _contentSlide;

  @override
  void initState() {
    super.initState();

    _ringCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _checkCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _contentCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));

    _ringScale = CurvedAnimation(parent: _ringCtrl, curve: Curves.easeOut);
    _checkScale =
        CurvedAnimation(parent: _checkCtrl, curve: Curves.elasticOut);
    _contentOpacity =
        CurvedAnimation(parent: _contentCtrl, curve: Curves.easeOut);
    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _contentCtrl, curve: Curves.easeOut));

    _ringCtrl.forward().then((_) {
      _checkCtrl.forward();
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) _contentCtrl.forward();
      });
    });
  }

  @override
  void dispose() {
    _ringCtrl.dispose();
    _checkCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  void _changeForm() {
    // Pop Confirmed + Preview to land back on Search.
    final nav = Navigator.of(context);
    nav.pop();
    nav.pop();
  }

  void _startInspection() {
    // TODO(FORM-03): wire up once asset context is confirmed.
    // Options:
    //   1. If assetId is passed into this flow: call initInspectionDraft then
    //      navigate to InspectAssetWidget.
    //   2. If no asset yet: navigate to the asset list page so the user picks one.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Start Inspection — wiring pending (FORM-03 open question)',
            style: ffStyle(13, FontWeight.w500, Colors.white)),
        backgroundColor: kFormSlate8,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final form = widget.form;
    final name = form['name'] as String? ?? 'Untitled';
    final category = form['category'] as String?;
    final stepCount = widget.schemaItems.length;

    return PopScope(
      canPop: false, // no back gesture on confirmation screen
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              // ── App bar (no back button) ────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Center(
                  child: Text('Form Assigned',
                      style: ffStyle(17, FontWeight.w800, kFormSlate8)),
                ),
              ),

              // ── Body ────────────────────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  child: SlideTransition(
                    position: _contentSlide,
                    child: FadeTransition(
                      opacity: _contentOpacity,
                      child: Column(
                        children: [
                          const SizedBox(height: 40),

                          // ── Animated checkmark ─────────────────────────
                          ScaleTransition(
                            scale: _ringScale,
                            child: SizedBox(
                              width: 100,
                              height: 100,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: kFormGreen.withValues(alpha: 0.10),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  Container(
                                    margin: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: kFormGreen.withValues(alpha: 0.07),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  ScaleTransition(
                                    scale: _checkScale,
                                    child: Container(
                                      width: 64,
                                      height: 64,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [kFormGreen, kFormGreenDk],
                                        ),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: kFormGreen
                                                .withValues(alpha: 0.35),
                                            blurRadius: 24,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.check_rounded,
                                        color: Colors.white,
                                        size: 30,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),
                          Text('Form Assigned!',
                              style:
                                  ffStyle(22, FontWeight.w800, kFormSlate8)),
                          const SizedBox(height: 8),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              'Your inspection is ready to go with the selected form',
                              style:
                                  ffStyle(13, FontWeight.w400, kFormSlate4),
                              textAlign: TextAlign.center,
                            ),
                          ),

                          const SizedBox(height: 32),

                          // ── Form summary card ─────────────────────────
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(
                                  color: const Color(0xFFD1FAE5), width: 2),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      kFormGreen.withValues(alpha: 0.10),
                                  blurRadius: 20,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFFF0FDF4),
                                        Color(0xFFDCFCE7)
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      categoryIcon(category),
                                      color: kFormGreen,
                                      size: 22,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(name,
                                          style: ffStyle(14,
                                              FontWeight.w800, kFormSlate8),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 3),
                                      Text(
                                        '$stepCount step${stepCount != 1 ? 's' : ''}'
                                        '${category != null && category.isNotEmpty ? ' · $category' : ''}',
                                        style: ffStyle(
                                            11, FontWeight.w400, kFormSlate4),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF0FDF4),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.check_rounded,
                                      color: kFormGreen, size: 14),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),

                          // ── Start Inspection button ───────────────────
                          GestureDetector(
                            onTap: _startInspection,
                            child: Container(
                              width: double.infinity,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [kFormBlue, kFormBlueDk],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: kFormBlue.withValues(alpha: 0.30),
                                    blurRadius: 24,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text('Start Inspection',
                                    style: ffStyle(
                                        15, FontWeight.w800, Colors.white)),
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // ── Change Form button ────────────────────────
                          GestureDetector(
                            onTap: _changeForm,
                            child: Container(
                              width: double.infinity,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: kFormBg,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: Text('Change Form',
                                    style: ffStyle(
                                        14, FontWeight.w700, kFormSlate5)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
