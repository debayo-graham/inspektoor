import 'dart:typed_data';
import 'dart:ui' as ui;

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
  final String? label;

  const PhotoPreviewScreen({
    super.key,
    required this.initialPhotos,
    this.initialIndex = 0,
    this.maxPhotos = 5,
    required this.onCapturePhoto,
    required this.accentColor,
    this.label,
  });

  @override
  State<PhotoPreviewScreen> createState() => _PhotoPreviewScreenState();
}

class _PhotoPreviewScreenState extends State<PhotoPreviewScreen> {
  late final List<Uint8List> _photos;
  late PageController _pageCtrl;
  int _currentIndex = 0;
  bool _isAnnotating = false;
  bool _baking = false;
  // Per-photo drawing strokes: index → list of strokes.
  final Map<int, List<_DrawStroke>> _allStrokes = {};
  Color _penColor = Colors.white;

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
      _currentIndex = _photos.isEmpty
          ? 0
          : _currentIndex.clamp(0, _photos.length - 1);
    });
    // Sync PageView.
    if (_photos.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageCtrl.hasClients) {
          _pageCtrl.jumpToPage(_currentIndex);
        }
      });
    }
  }

  void _deleteCurrent() => _deleteAt(_currentIndex);

  void _save() {
    Navigator.of(context).pop(List<Uint8List>.from(_photos));
  }

  /// Rasterize strokes onto photo [index] and return new PNG bytes.
  /// Returns null on failure. Uses the last known [_viewerSize] for coordinate
  /// mapping since the annotation canvas may no longer be mounted.
  Future<Uint8List?> _bakePhoto(int index, List<_DrawStroke> strokes) async {
    final viewSize = _viewerSize;
    if (viewSize == null) return null;

    final codec = await ui.instantiateImageCodec(_photos[index]);
    final frame = await codec.getNextFrame();
    final srcImage = frame.image;

    final imgW = srcImage.width.toDouble();
    final imgH = srcImage.height.toDouble();

    const pad = 8.0;
    final availW = viewSize.width - pad * 2;
    final availH = viewSize.height - pad * 2;
    final scale = (availW / imgW).clamp(0.0, availH / imgH);
    final fittedW = imgW * scale;
    final fittedH = imgH * scale;
    final offsetX = pad + (availW - fittedW) / 2;
    final offsetY = pad + (availH - fittedH) / 2;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawImage(srcImage, Offset.zero, Paint());

    for (final stroke in strokes) {
      if (stroke.points.length < 2) continue;
      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = 5.0 * (imgW / fittedW)
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      final path = ui.Path();
      final first = stroke.points.first;
      path.moveTo(
        (first.dx - offsetX) / scale,
        (first.dy - offsetY) / scale,
      );
      for (var j = 1; j < stroke.points.length; j++) {
        final p = stroke.points[j];
        path.lineTo(
          (p.dx - offsetX) / scale,
          (p.dy - offsetY) / scale,
        );
      }
      canvas.drawPath(path, paint);
    }

    final picture = recorder.endRecording();
    final result = await picture.toImage(imgW.toInt(), imgH.toInt());
    final byteData = await result.toByteData(format: ui.ImageByteFormat.png);
    srcImage.dispose();
    result.dispose();

    return byteData?.buffer.asUint8List();
  }

  Future<void> _back() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Are you sure you want to leave?',
            style: _inter(16, FontWeight.w700, Colors.white)),
        content: Text('All changes will be lost.',
            style: _inter(14, FontWeight.w400, Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: _inter(14, FontWeight.w600, Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Leave', style: _inter(14, FontWeight.w600, const Color(0xFFEF4444))),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      Navigator.of(context).pop(null);
    }
  }

  /// Tracks the viewer area size for coordinate mapping during bake.
  Size? _viewerSize;

  Future<void> _toggleAnnotation() async {
    if (_isAnnotating) {
      // Exiting annotation — bake strokes into current photo.
      final strokes = _allStrokes[_currentIndex];
      final hasStrokes = strokes != null && strokes.isNotEmpty;

      if (hasStrokes) {
        setState(() => _baking = true);
        final baked = await _bakePhoto(_currentIndex, strokes);
        if (baked != null) _photos[_currentIndex] = baked;
        _allStrokes.remove(_currentIndex);
      }

      setState(() {
        _baking = false;
        _isAnnotating = false;
        _pageCtrl.dispose();
        _pageCtrl = PageController(initialPage: _currentIndex);
      });
    } else {
      setState(() => _isAnnotating = true);
    }
  }

  void _undoStroke() {
    final strokes = _allStrokes[_currentIndex];
    if (strokes != null && strokes.isNotEmpty) {
      setState(() => strokes.removeLast());
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accentColor;
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        backgroundColor: _kDarkBg,
        body: Stack(
          children: [
            Column(
              children: [
                SizedBox(height: topPadding),
                // ── Top bar ────────────────────────────────────────────────────
                _isAnnotating
                    ? _AnnotationTopBar(
                    onClear: () {
                      setState(() => _allStrokes[_currentIndex]?.clear());
                    },
                    onUndo: _undoStroke,
                  )
                : _TopBar(
                    onDelete: _photos.isNotEmpty ? _deleteCurrent : null,
                    onEdit: _photos.isNotEmpty ? _toggleAnnotation : null,
                  ),

            // ── Main image viewer ──────────────────────────────────────────
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  _viewerSize = Size(constraints.maxWidth, constraints.maxHeight);
                  if (_photos.isEmpty) {
                    return Center(
                      child: Text(
                        'No photos',
                        style: _inter(16, FontWeight.w500, Colors.white54),
                      ),
                    );
                  }
                  if (_isAnnotating) {
                    return _AnnotationCanvas(
                      photo: _photos[_currentIndex],
                      strokes: _allStrokes.putIfAbsent(
                          _currentIndex, () => []),
                      penColor: _penColor,
                    );
                  }
                  return PageView.builder(
                    controller: _pageCtrl,
                    itemCount: _photos.length,
                    onPageChanged: _onPageChanged,
                    itemBuilder: (_, i) {
                      final strokes = _allStrokes[i];
                      final hasStrokes = strokes != null && strokes.isNotEmpty;
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          Container(
                            color: Colors.black,
                            padding: const EdgeInsets.all(8),
                            child: Image.memory(
                              _photos[i],
                              fit: BoxFit.contain,
                            ),
                          ),
                          // Strokes overlay (read-only in browse mode)
                          if (hasStrokes)
                            IgnorePointer(
                              child: CustomPaint(
                                painter: _StrokePainter(strokes: strokes),
                                size: Size.infinite,
                              ),
                            ),
                          // Label overlay
                          if (widget.label != null &&
                              widget.label!.isNotEmpty)
                            Positioned(
                              bottom: 16,
                              left: 16,
                              right: 16,
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius:
                                        BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    widget.label!,
                                    style: _inter(14, FontWeight.w600,
                                        Colors.white),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),

            // ── Annotation color picker or page indicator ─────────────────
            if (_isAnnotating)
              _ColorPicker(
                selected: _penColor,
                onSelect: (c) => setState(() => _penColor = c),
                onDone: _toggleAnnotation,
              )
            else ...[
              if (_photos.length > 1)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    '${_currentIndex + 1}/${_photos.length}',
                    style: _inter(13, FontWeight.w600, Colors.white70),
                  ),
                ),

              // ── Thumbnail strip ──────────────────────────────────────────
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

              // ── Bottom bar (Back / Save) ─────────────────────────────────
              _BottomBar(
                onBack: _back,
                onSave: _save,
                accentColor: accent,
              ),
            ],
                SizedBox(height: bottomPadding),
              ],
            ),

            // ── Saving overlay ─────────────────────────────────────────────
            if (_baking)
              Positioned.fill(
                child: AbsorbPointer(
                  child: Container(
                    color: Colors.black54,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Applying edits…',
                            style: _inter(15, FontWeight.w600, Colors.white70),
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
    );
  }
}

// ─── _TopBar ─────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const _TopBar({
    required this.onDelete,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          if (onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  color: Colors.white, size: 28),
              onPressed: onDelete,
            ),
          const Spacer(),
          if (onEdit != null)
            IconButton(
              icon: const Icon(Icons.edit_rounded,
                  color: Colors.white, size: 28),
              onPressed: onEdit,
            ),
        ],
      ),
    );
  }
}

// ─── _AnnotationTopBar ────────────────────────────────────────────────────────

class _AnnotationTopBar extends StatelessWidget {
  final VoidCallback onClear;
  final VoidCallback onUndo;

  const _AnnotationTopBar({
    required this.onClear,
    required this.onUndo,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          TextButton(
            onPressed: onClear,
            child: Text('Clear',
                style: _inter(15, FontWeight.w500, Colors.white70)),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.undo_rounded, color: Colors.white, size: 28),
            onPressed: onUndo,
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

// ─── Drawing data ─────────────────────────────────────────────────────────────

class _DrawStroke {
  final Color color;
  final List<Offset> points;
  _DrawStroke({required this.color, List<Offset>? points})
      : points = points ?? [];
}

// ─── _AnnotationCanvas ────────────────────────────────────────────────────────

class _AnnotationCanvas extends StatefulWidget {
  final Uint8List photo;
  final List<_DrawStroke> strokes;
  final Color penColor;

  const _AnnotationCanvas({
    required this.photo,
    required this.strokes,
    required this.penColor,
  });

  @override
  State<_AnnotationCanvas> createState() => _AnnotationCanvasState();
}

class _AnnotationCanvasState extends State<_AnnotationCanvas> {
  _DrawStroke? _currentStroke;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          color: Colors.black,
          padding: const EdgeInsets.all(8),
          child: Image.memory(widget.photo, fit: BoxFit.contain),
        ),
        // Drawing layer
        GestureDetector(
          onPanStart: (d) {
            _currentStroke = _DrawStroke(color: widget.penColor);
            _currentStroke!.points.add(d.localPosition);
            widget.strokes.add(_currentStroke!);
            setState(() {});
          },
          onPanUpdate: (d) {
            _currentStroke?.points.add(d.localPosition);
            setState(() {});
          },
          onPanEnd: (_) {
            _currentStroke = null;
          },
          child: CustomPaint(
            painter: _StrokePainter(strokes: widget.strokes),
            size: Size.infinite,
          ),
        ),
      ],
    );
  }
}

// ─── _StrokePainter ───────────────────────────────────────────────────────────

class _StrokePainter extends CustomPainter {
  final List<_DrawStroke> strokes;
  _StrokePainter({required this.strokes});

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      if (stroke.points.length < 2) continue;
      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = 5.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      final path = ui.Path();
      path.moveTo(stroke.points.first.dx, stroke.points.first.dy);
      for (var i = 1; i < stroke.points.length; i++) {
        path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StrokePainter old) => true;
}

// ─── _ColorPicker ─────────────────────────────────────────────────────────────

class _ColorPicker extends StatelessWidget {
  final Color selected;
  final void Function(Color) onSelect;
  final VoidCallback onDone;

  static const _colors = [
    Colors.white,
    Colors.black,
    Color(0xFFEF4444), // red
    Color(0xFFF97316), // orange
    Color(0xFFEAB308), // yellow
    Color(0xFF22C55E), // green
    Color(0xFF3B82F6), // blue
  ];

  const _ColorPicker({
    required this.selected,
    required this.onSelect,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _colors.map((c) {
              final isSelected = c == selected;
              return GestureDetector(
                onTap: () => onSelect(c),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(color: _kPrimaryBlue, width: 3)
                        : Border.all(
                            color: Colors.white24,
                            width: 1.5,
                          ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 18, color: Colors.white)
                      : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onDone,
              child: Text('Done',
                  style: _inter(15, FontWeight.w600, Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
