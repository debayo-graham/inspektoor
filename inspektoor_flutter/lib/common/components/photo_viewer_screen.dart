import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Private tokens (self-contained, no inspection_tokens import) ────────────
TextStyle _inter(double size, FontWeight weight, Color color) =>
    GoogleFonts.inter(
        fontSize: size, fontWeight: weight, color: color, letterSpacing: 0.0);

const Color _kDarkBg = Color(0xFF1A1A1A);
const Color _kDarkBorder = Color(0xFF444444);
const Color _kPrimaryBlue = Color(0xFF27AAE2);

// ─── PhotoViewerScreen ───────────────────────────────────────────────────────
///
/// Read-only full-screen photo viewer with swipe carousel.
/// Opens at [initialIndex] and allows swiping through all [photos].
/// Supports pinch-to-zoom on each image.
class PhotoViewerScreen extends StatefulWidget {
  final List<Uint8List> photos;
  final int initialIndex;

  const PhotoViewerScreen({
    super.key,
    required this.photos,
    this.initialIndex = 0,
  });

  @override
  State<PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends State<PhotoViewerScreen> {
  late PageController _pageCtrl;
  late int _currentIndex;
  bool _isZoomed = false;
  final List<TransformationController> _transformCtrls = [];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, widget.photos.length - 1);
    _pageCtrl = PageController(initialPage: _currentIndex);
    for (int i = 0; i < widget.photos.length; i++) {
      _transformCtrls.add(TransformationController());
    }
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    for (final c in _transformCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  void _onPageChanged(int index) {
    // Reset zoom on previous page
    if (_isZoomed) {
      _transformCtrls[_currentIndex].value = Matrix4.identity();
    }
    setState(() {
      _currentIndex = index;
      _isZoomed = false;
    });
  }

  void _jumpToPage(int index) {
    _pageCtrl.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final photos = widget.photos;
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: _kDarkBg,
      body: Column(
        children: [
          // ── Top bar ──────────────────────────────────────────────────────
          Container(
            padding: EdgeInsets.only(
                top: topPadding + 8, left: 8, right: 16, bottom: 8),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded,
                      color: Colors.white, size: 24),
                ),
                const Spacer(),
                if (photos.length > 1)
                  Text(
                    '${_currentIndex + 1} / ${photos.length}',
                    style: _inter(14, FontWeight.w600, Colors.white70),
                  ),
              ],
            ),
          ),

          // ── Main image area ──────────────────────────────────────────────
          Expanded(
            child: PageView.builder(
              controller: _pageCtrl,
              itemCount: photos.length,
              onPageChanged: _onPageChanged,
              physics: _isZoomed
                  ? const NeverScrollableScrollPhysics()
                  : const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                return InteractiveViewer(
                  transformationController: _transformCtrls[index],
                  minScale: 1.0,
                  maxScale: 4.0,
                  onInteractionEnd: (details) {
                    final scale =
                        _transformCtrls[index].value.getMaxScaleOnAxis();
                    setState(() => _isZoomed = scale > 1.05);
                  },
                  child: Center(
                    child: Image.memory(
                      photos[index],
                      fit: BoxFit.contain,
                    ),
                  ),
                );
              },
            ),
          ),

          // ── Bottom thumbnail strip (only if >1 photo) ───────────────────
          if (photos.length > 1) ...[
            Container(
              height: 72,
              padding: EdgeInsets.only(bottom: bottomPadding > 0 ? 8 : 12),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: photos.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final selected = index == _currentIndex;
                  return GestureDetector(
                    onTap: () => _jumpToPage(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selected ? _kPrimaryBlue : _kDarkBorder,
                          width: selected ? 2.5 : 1.5,
                        ),
                      ),
                      clipBehavior: Clip.hardEdge,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.memory(
                          photos[index],
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ] else
            SizedBox(height: bottomPadding > 0 ? bottomPadding : 16),
        ],
      ),
    );
  }
}
