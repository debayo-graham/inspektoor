import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'dashed_border_painter.dart';

// ─── Private tokens (self-contained, no inspection_tokens import) ────────────
TextStyle _inter(double size, FontWeight weight, Color color) =>
    GoogleFonts.inter(fontSize: size, fontWeight: weight, color: color, letterSpacing: 0.0);

const Color _kDarkBg = Color(0xFF1A1A1A);
const Color _kDarkBorder = Color(0xFF444444);
const Color _kPrimaryBlue = Color(0xFF27AAE2);

// ─── PhotoPreviewScreen ──────────────────────────────────────────────────────
///
/// Full-screen photo preview pushed after capture. Allows the user to review
/// photos, add more (up to [maxPhotos]), delete, and save.
///
/// Returns `List<Uint8List>` on Save, or `null` on Back (no changes).
class PhotoPreviewScreen extends StatefulWidget {
  final List<Uint8List> initialPhotos;
  final int initialIndex;
  final int maxPhotos;
  final Future<Uint8List?> Function() onCapturePhoto;
  final Color accentColor;

  const PhotoPreviewScreen({
    super.key,
    required this.initialPhotos,
    this.initialIndex = 0,
    this.maxPhotos = 5,
    required this.onCapturePhoto,
    required this.accentColor,
  });

  @override
  State<PhotoPreviewScreen> createState() => _PhotoPreviewScreenState();
}

class _PhotoPreviewScreenState extends State<PhotoPreviewScreen> {
  late final List<Uint8List> _photos;
  late PageController _pageCtrl;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _photos = List<Uint8List>.from(widget.initialPhotos);
    _currentIndex = widget.initialIndex.clamp(0, _photos.length - 1);
    _pageCtrl = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
  }

  Future<void> _addPhoto() async {
    if (_photos.length >= widget.maxPhotos) return;
    final bytes = await widget.onCapturePhoto();
    if (bytes != null && mounted) {
      setState(() {
        _photos.add(bytes);
        _currentIndex = _photos.length - 1;
      });
      // Jump to the new photo after the frame builds.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageCtrl.hasClients) {
          _pageCtrl.animateToPage(
            _currentIndex,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  void _deleteAt(int index) {
    if (index < 0 || index >= _photos.length) return;
    setState(() {
      _photos.removeAt(index);
      if (_photos.isEmpty) {
        // All deleted — pop with empty list.
        Navigator.of(context).pop(<Uint8List>[]);
        return;
      }
      _currentIndex = _currentIndex.clamp(0, _photos.length - 1);
    });
    // Sync PageView.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageCtrl.hasClients) {
        _pageCtrl.jumpToPage(_currentIndex);
      }
    });
  }

  void _deleteCurrent() => _deleteAt(_currentIndex);

  void _save() => Navigator.of(context).pop(List<Uint8List>.from(_photos));
  void _back() => Navigator.of(context).pop(null);

  @override
  Widget build(BuildContext context) {
    final accent = widget.accentColor;
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: _kDarkBg,
      body: Column(
        children: [
          SizedBox(height: topPadding),
          // ── Top bar ────────────────────────────────────────────────────
          _TopBar(
            onBack: _back,
            onDelete: _photos.isNotEmpty ? _deleteCurrent : null,
            accentColor: accent,
          ),

          // ── Main image viewer ──────────────────────────────────────────
          Expanded(
            child: _photos.isEmpty
                ? Center(
                    child: Text(
                      'No photos',
                      style: _inter(16, FontWeight.w500, Colors.white54),
                    ),
                  )
                : PageView.builder(
                    controller: _pageCtrl,
                    itemCount: _photos.length,
                    onPageChanged: _onPageChanged,
                    itemBuilder: (_, i) => Container(
                      color: Colors.black,
                      padding: const EdgeInsets.all(8),
                      child: Image.memory(
                        _photos[i],
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
          ),

          // ── Page indicator ─────────────────────────────────────────────
          if (_photos.length > 1)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                '${_currentIndex + 1}/${_photos.length}',
                style: _inter(13, FontWeight.w600, Colors.white70),
              ),
            ),

          // ── Thumbnail strip ────────────────────────────────────────────
          _ThumbnailStrip(
            photos: _photos,
            currentIndex: _currentIndex,
            maxPhotos: widget.maxPhotos,
            accentColor: accent,
            onSelect: (i) {
              setState(() => _currentIndex = i);
              _pageCtrl.animateToPage(
                i,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
              );
            },
            onDelete: _deleteAt,
            onAdd: _addPhoto,
          ),

          // ── Bottom bar (Back / Save) ───────────────────────────────────
          _BottomBar(
            onBack: _back,
            onSave: _save,
            accentColor: accent,
          ),
          SizedBox(height: bottomPadding),
        ],
      ),
    );
  }
}

// ─── _TopBar ─────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback? onDelete;
  final Color accentColor;

  const _TopBar({
    required this.onBack,
    required this.onDelete,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: onBack,
          ),
          const Spacer(),
          if (onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.white),
              onPressed: onDelete,
            ),
        ],
      ),
    );
  }
}

// ─── _ThumbnailStrip ─────────────────────────────────────────────────────────

class _ThumbnailStrip extends StatelessWidget {
  final List<Uint8List> photos;
  final int currentIndex;
  final int maxPhotos;
  final Color accentColor;
  final void Function(int) onSelect;
  final void Function(int) onDelete;
  final VoidCallback onAdd;

  const _ThumbnailStrip({
    required this.photos,
    required this.currentIndex,
    required this.maxPhotos,
    required this.accentColor,
    required this.onSelect,
    required this.onDelete,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final canAdd = photos.length < maxPhotos;

    return Container(
      height: 84,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: maxPhotos,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          if (i < photos.length) {
            final isSelected = i == currentIndex;
            return _Thumbnail(
              photo: photos[i],
              isSelected: isSelected,
              accentColor: accentColor,
              onTap: () => onSelect(i),
              onDelete: () => onDelete(i),
            );
          }
          // First empty slot is the "+" add tile, rest are empty placeholders
          if (i == photos.length && canAdd) {
            return _AddTile(accentColor: accentColor, onTap: onAdd);
          }
          return _EmptySlot(index: i + 1);
        },
      ),
    );
  }
}

// ─── _Thumbnail ──────────────────────────────────────────────────────────────

class _Thumbnail extends StatelessWidget {
  final Uint8List photo;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _Thumbnail({
    required this.photo,
    required this.isSelected,
    required this.accentColor,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? accentColor : _kDarkBorder,
                width: isSelected ? 2.5 : 1.5,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(photo, fit: BoxFit.cover),
            ),
          ),
          // X delete badge
          Positioned(
            top: -6,
            right: -6,
            child: GestureDetector(
              onTap: onDelete,
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: Colors.black87,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── _EmptySlot ──────────────────────────────────────────────────────────

class _EmptySlot extends StatelessWidget {
  final int index;
  const _EmptySlot({required this.index});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: const DashedBorderPainter(
        color: _kDarkBorder,
        radius: 10,
        strokeWidth: 1.5,
        dashWidth: 5,
        dashGap: 3,
      ),
      child: SizedBox(
        width: 70,
        height: 70,
        child: Center(
          child: Text(
            '$index',
            style: _inter(13, FontWeight.w500, Colors.white24),
          ),
        ),
      ),
    );
  }
}

// ─── _AddTile ────────────────────────────────────────────────────────────────

class _AddTile extends StatelessWidget {
  final Color accentColor;
  final VoidCallback onTap;

  const _AddTile({required this.accentColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CustomPaint(
        painter: const DashedBorderPainter(
          color: _kDarkBorder,
          radius: 10,
          strokeWidth: 1.5,
          dashWidth: 5,
          dashGap: 3,
        ),
        child: const SizedBox(
          width: 70,
          height: 70,
          child: Icon(Icons.add_rounded, color: Colors.white70, size: 28),
        ),
      ),
    );
  }
}

// ─── _BottomBar ──────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onSave;
  final Color accentColor;

  const _BottomBar({
    required this.onBack,
    required this.onSave,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 50,
              child: OutlinedButton(
                onPressed: onBack,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: _kDarkBorder, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text('Back', style: _inter(15, FontWeight.w600, Colors.white)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: onSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimaryBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text('Save', style: _inter(15, FontWeight.w600, Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
