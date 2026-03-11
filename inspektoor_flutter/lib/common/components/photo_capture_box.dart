import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'dashed_border_painter.dart';
import 'photo_preview_screen.dart';

// ─── Private tokens ──────────────────────────────────────────────────────────
const Color _kSlate = Color(0xFFF8FAFC); // slate-50, empty-state bg
const Color _kBorder = Color(0xFFE0E3E7); // inactive dot / fallback border

TextStyle _inter(double size, FontWeight weight, Color color) =>
    GoogleFonts.inter(fontSize: size, fontWeight: weight, color: color, letterSpacing: 0.0);

// ─── PhotoCaptureBox ─────────────────────────────────────────────────────────
///
/// Reusable multi-photo capture widget.
///
/// **Empty state**: dashed border, camera icon, label + subtitle.
/// Tapping opens the camera (via [onCapturePhoto]) then pushes a
/// [PhotoPreviewScreen].
///
/// **Has-photos state**: swipeable carousel (PageView) with pagination dots,
/// counter badge, "+" add button, delete overlay. Tapping the carousel re-opens
/// the preview screen at the current index.
///
/// The widget has **no FlutterFlow imports**. Camera capture is injected via
/// the [onCapturePhoto] callback so the parent can wire it to `selectMedia`.
class PhotoCaptureBox extends StatefulWidget {
  /// Current list of captured photos (owned by the parent).
  final List<Uint8List> photos;

  /// Maximum number of photos allowed.
  final int maxPhotos;

  /// Border colour for the dashed empty-state border.
  final Color borderColor;

  /// Accent colour used for the camera icon circle and active carousel dots.
  final Color accentColor;

  /// Background tint for the camera icon circle in the empty state.
  final Color accentBgColor;

  /// Called whenever the photo list changes (add, delete, reorder from preview).
  final ValueChanged<List<Uint8List>> onPhotosChanged;

  /// Captures a single photo and returns its bytes (`null` = user cancelled).
  final Future<Uint8List?> Function() onCapturePhoto;

  /// Label shown in the empty state (below the icon).
  final String emptyLabel;

  /// Subtitle shown in the empty state.
  final String emptySubtitle;

  /// Optional label forwarded to [PhotoPreviewScreen] for text overlay.
  final String? label;

  const PhotoCaptureBox({
    super.key,
    required this.photos,
    this.maxPhotos = 5,
    required this.borderColor,
    required this.accentColor,
    required this.accentBgColor,
    required this.onPhotosChanged,
    required this.onCapturePhoto,
    this.emptyLabel = 'Tap to take photo',
    this.emptySubtitle = 'Evidence of the issue',
    this.label,
  });

  @override
  State<PhotoCaptureBox> createState() => _PhotoCaptureBoxState();
}

class _PhotoCaptureBoxState extends State<PhotoCaptureBox> {
  final PageController _pageCtrl = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  // ── Camera + preview flow ──────────────────────────────────────────────────

  /// Capture a photo, then open the preview screen seeded with it.
  Future<void> _captureAndPreview() async {
    final bytes = await widget.onCapturePhoto();
    if (bytes == null || !mounted) return;

    final result = await Navigator.of(context).push<List<Uint8List>>(
      MaterialPageRoute(
        builder: (_) => PhotoPreviewScreen(
          initialPhotos: [...widget.photos, bytes],
          initialIndex: widget.photos.length, // new photo is last
          maxPhotos: widget.maxPhotos,
          onCapturePhoto: widget.onCapturePhoto,
          accentColor: widget.accentColor,
          label: widget.label,
        ),
      ),
    );
    if (result != null && mounted) {
      widget.onPhotosChanged(result);
    }
  }

  /// Open preview from the carousel at the current page index.
  Future<void> _openPreview() async {
    final result = await Navigator.of(context).push<List<Uint8List>>(
      MaterialPageRoute(
        builder: (_) => PhotoPreviewScreen(
          initialPhotos: widget.photos,
          initialIndex: _currentPage,
          maxPhotos: widget.maxPhotos,
          onCapturePhoto: widget.onCapturePhoto,
          accentColor: widget.accentColor,
          label: widget.label,
        ),
      ),
    );
    if (result != null && mounted) {
      widget.onPhotosChanged(result);
      // Reset page to 0 if the list shrank.
      if (_currentPage >= result.length) {
        setState(() => _currentPage = result.isEmpty ? 0 : result.length - 1);
      }
    }
  }

  /// Capture another photo from the carousel "+" button.
  Future<void> _addFromCarousel() async {
    final bytes = await widget.onCapturePhoto();
    if (bytes == null || !mounted) return;
    widget.onPhotosChanged([...widget.photos, bytes]);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageCtrl.hasClients) {
        _pageCtrl.animateToPage(
          widget.photos.length, // will be the new last index after rebuild
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _deleteFromCarousel(int index) {
    final updated = List<Uint8List>.from(widget.photos)..removeAt(index);
    widget.onPhotosChanged(updated);
    if (_currentPage >= updated.length && updated.isNotEmpty) {
      setState(() => _currentPage = updated.length - 1);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (widget.photos.isEmpty) return _buildEmptyState();
    return _buildCarousel();
  }

  // ── Empty state ────────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return GestureDetector(
      onTap: _captureAndPreview,
      child: CustomPaint(
        foregroundPainter: DashedBorderPainter(color: widget.borderColor),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 140,
            width: double.infinity,
            color: _kSlate,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: widget.accentBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.photo_camera_outlined,
                    color: widget.accentColor,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.emptyLabel,
                  style: _inter(13, FontWeight.w600, const Color(0xFF1D354F)),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.emptySubtitle,
                  style: _inter(11, FontWeight.w400, const Color(0xFF57636C)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Carousel state ─────────────────────────────────────────────────────────

  Widget _buildCarousel() {
    final photos = widget.photos;
    final canAdd = photos.length < widget.maxPhotos;

    return Column(
      children: [
        // ── Image slider ─────────────────────────────────────────────────
        GestureDetector(
          onTap: _openPreview,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const ColoredBox(color: Colors.black),
                  PageView.builder(
                    controller: _pageCtrl,
                    itemCount: photos.length,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    itemBuilder: (_, i) =>
                        Image.memory(photos[i], fit: BoxFit.contain),
                  ),
                  // "+" add button (top-left)
                  if (canAdd)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: GestureDetector(
                        onTap: _addFromCarousel,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.add_rounded,
                              color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  // Delete button (top-right)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => _deleteFromCarousel(_currentPage),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.delete_outline_rounded,
                            color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                  // Counter badge (bottom-left)
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_currentPage + 1}/${photos.length}',
                        style: _inter(11, FontWeight.w600, Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // ── Dot indicator ────────────────────────────────────────────────
        if (photos.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(photos.length, (i) {
                final isActive = i == _currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: isActive ? 8 : 6,
                  height: isActive ? 8 : 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive ? widget.accentColor : _kBorder,
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }
}
