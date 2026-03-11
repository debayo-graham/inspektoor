import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

// ─── OcrExtractionMode ───────────────────────────────────────────────────────

enum OcrExtractionMode {
  /// Extract the first numeric value (digits, decimal point, minus sign).
  numeric,

  /// Extract alphanumeric characters (letters + digits + internal spaces),
  /// trimmed of leading/trailing whitespace and punctuation. Uppercased.
  alphanumeric,

  /// Extract all readable text preserving original case and punctuation.
  freeText,
}

// ─── OcrCaptureResult ────────────────────────────────────────────────────────

class OcrCaptureResult {
  final Uint8List imageBytes; // Cropped viewfinder image (JPEG)
  final String? extractedText; // First numeric match, or null

  const OcrCaptureResult({required this.imageBytes, this.extractedText});
}

// ─── OcrCameraScreen ─────────────────────────────────────────────────────────
//
// Full-screen camera with a viewfinder overlay. Captures, crops to the
// viewfinder region, runs ML Kit text recognition, and returns the result.

class OcrCameraScreen extends StatefulWidget {
  /// Instruction text shown below the viewfinder box.
  final String instruction;

  /// Controls how recognized text is extracted and returned.
  final OcrExtractionMode extractionMode;

  /// When true, uses a larger viewfinder box suitable for capturing paragraphs.
  final bool largeViewfinder;

  const OcrCameraScreen({
    super.key,
    this.instruction = 'Place the reading inside the box above',
    this.extractionMode = OcrExtractionMode.numeric,
    this.largeViewfinder = false,
  });

  @override
  State<OcrCameraScreen> createState() => _OcrCameraScreenState();
}

class _OcrCameraScreenState extends State<OcrCameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  bool _isInitialized = false;
  String? _initError;
  bool _isCapturing = false;

  // Viewfinder rect in screen coordinates — computed in build via LayoutBuilder.
  Rect _viewfinderRect = Rect.zero;

  // Key on the camera preview to read its render size.
  final GlobalKey _previewKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
      _controller = null;
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _initError = 'No cameras available');
        return;
      }
      // Prefer back camera.
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        back,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _isInitialized = true;
      });
    } catch (e) {
      if (mounted) setState(() => _initError = 'Camera error: $e');
    }
  }

  // ── Capture + crop + OCR ─────────────────────────────────────────────────

  Future<void> _capture() async {
    if (_isCapturing || _controller == null || !_controller!.value.isInitialized) {
      return;
    }
    setState(() => _isCapturing = true);

    File? tempFile;
    try {
      final xFile = await _controller!.takePicture();
      final rawBytes = await xFile.readAsBytes();

      // Decode full image.
      final decoded = img.decodeImage(rawBytes);
      if (decoded == null) throw Exception('Failed to decode captured image');

      // Map viewfinder rect from screen coords to image pixel coords.
      final croppedImage = _cropToViewfinder(decoded);
      final croppedBytes =
          Uint8List.fromList(img.encodeJpg(croppedImage, quality: 90));

      // Write cropped image to temp file for ML Kit.
      final dir = await getTemporaryDirectory();
      tempFile = File(
          '${dir.path}/ocr_crop_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await tempFile.writeAsBytes(croppedBytes);

      // Run ML Kit text recognition.
      final inputImage = InputImage.fromFilePath(tempFile.path);
      final recognizer = TextRecognizer();
      final recognized = await recognizer.processImage(inputImage);
      await recognizer.close();

      // Extract text based on the configured mode.
      final allText = recognized.blocks.map((b) => b.text).join(' ');
      String? extracted;

      switch (widget.extractionMode) {
        case OcrExtractionMode.numeric:
          final match = RegExp(r'-?[\d]+\.?[\d]*').firstMatch(allText);
          extracted = match?.group(0);
          break;
        case OcrExtractionMode.alphanumeric:
          // Preserve all recognized text (uppercased, newlines collapsed, trimmed).
          final collapsed = allText.replaceAll(RegExp(r'\n+'), ' ').replaceAll(RegExp(r' {2,}'), ' ').trim();
          extracted = collapsed.isNotEmpty ? collapsed.toUpperCase() : null;
          break;
        case OcrExtractionMode.freeText:
          // Collapse newlines into spaces so paragraph text flows naturally.
          final collapsed = allText.replaceAll(RegExp(r'\n+'), ' ').replaceAll(RegExp(r' {2,}'), ' ').trim();
          extracted = collapsed.isNotEmpty ? collapsed : null;
          break;
      }

      if (!mounted) return;

      if (extracted == null) {
        // No text found — show retry dialog.
        setState(() => _isCapturing = false);
        final retry = await _showOcrFailedDialog();
        if (retry) return; // User chose to retake — camera stays open.
        if (mounted) Navigator.of(context).pop(); // User chose to close.
        return;
      }

      Navigator.of(context).pop(OcrCaptureResult(
        imageBytes: croppedBytes,
        extractedText: extracted,
      ));
    } catch (e) {
      debugPrint('OCR capture error: $e');
      if (mounted) {
        setState(() => _isCapturing = false);
        final retry = await _showOcrFailedDialog(
          message: 'Something went wrong while reading the image. '
              'Please try again with better lighting or a clearer angle, '
              'or close and enter the value manually.',
        );
        if (retry) return;
        if (mounted) Navigator.of(context).pop();
      }
    } finally {
      try {
        await tempFile?.delete();
      } catch (_) {}
    }
  }

  // ── OCR-failed dialog ──────────────────────────────────────────────────

  /// Shows an info dialog when no text was found.
  /// Returns `true` if the user wants to retake, `false` to close.
  Future<bool> _showOcrFailedDialog({
    String? message,
  }) async {
    message ??= widget.extractionMode == OcrExtractionMode.alphanumeric
        ? 'No text could be detected in the image. '
          'Try positioning the text clearly inside the box with good lighting, '
          'or close and enter the value manually.'
        : 'No numeric value could be detected in the image. '
          'Try positioning the reading clearly inside the box with good lighting, '
          'or close and enter the value manually.';
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 40),
        child: Container(
          width: 285,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.info_outline_rounded,
                  color: Color(0xFF27AAE2), size: 64),
              const SizedBox(height: 20),
              const Text(
                'Could not read value',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1D354F),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF57636C),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF57636C),
                          side: const BorderSide(
                              color: Color(0xFFE0E3E7), width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Close'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF27AAE2),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Retake'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    return result ?? false;
  }

  img.Image _cropToViewfinder(img.Image fullImage) {
    // Get render size of the camera preview widget.
    final renderBox =
        _previewKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return fullImage;

    final renderSize = renderBox.size;

    // Camera preview is displayed as BoxFit.cover. The sensor image might
    // be landscape while the preview renders in portrait. Determine the
    // effective image orientation.
    final imgW = fullImage.width.toDouble();
    final imgH = fullImage.height.toDouble();

    // Scale factors: how many image pixels per screen pixel.
    // CameraPreview uses BoxFit.cover, so we take the larger scale.
    final scaleX = imgW / renderSize.width;
    final scaleY = imgH / renderSize.height;
    final scale = scaleX > scaleY ? scaleX : scaleY;

    // The preview is centered — compute offset of rendered image relative to
    // the widget (some parts are clipped).
    final renderedW = imgW / scale;
    final renderedH = imgH / scale;
    final offsetX = (renderedW - renderSize.width) / 2;
    final offsetY = (renderedH - renderSize.height) / 2;

    // Map viewfinder rect from widget coords to image coords.
    // Widget-local viewfinder position.
    final renderOrigin = renderBox.localToGlobal(Offset.zero);
    final vfLocal = _viewfinderRect.shift(-renderOrigin);

    final cropX = ((vfLocal.left + offsetX) * scale).round().clamp(0, fullImage.width - 1);
    final cropY = ((vfLocal.top + offsetY) * scale).round().clamp(0, fullImage.height - 1);
    var cropW = (vfLocal.width * scale).round();
    var cropH = (vfLocal.height * scale).round();

    // Clamp to image bounds.
    if (cropX + cropW > fullImage.width) cropW = fullImage.width - cropX;
    if (cropY + cropH > fullImage.height) cropH = fullImage.height - cropY;
    if (cropW <= 0 || cropH <= 0) return fullImage;

    return img.copyCrop(fullImage,
        x: cropX, y: cropY, width: cropW, height: cropH);
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final screenW = mq.size.width;
    final screenH = mq.size.height;

    // Viewfinder dimensions.
    final vfW = screenW * (widget.largeViewfinder ? 0.82 : 0.62);
    final vfH = vfW * (widget.largeViewfinder ? 0.65 : 0.35);
    final vfLeft = (screenW - vfW) / 2;
    final vfTop = (screenH - vfH) / 2 - 30; // slightly above center
    final vfRect = Rect.fromLTWH(vfLeft, vfTop, vfW, vfH);

    // Store for crop mapping.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewfinderRect = vfRect;
    });
    // Also set synchronously for the overlay painter.
    _viewfinderRect = vfRect;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Camera preview ───────────────────────────────────────────────
          if (_isInitialized && _controller != null)
            SizedBox.expand(
              key: _previewKey,
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller!.value.previewSize!.height,
                  height: _controller!.value.previewSize!.width,
                  child: CameraPreview(_controller!),
                ),
              ),
            )
          else if (_initError != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  _initError!,
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),

          // ── Viewfinder overlay ───────────────────────────────────────────
          CustomPaint(
            size: Size(screenW, screenH),
            painter: _ViewfinderOverlayPainter(viewfinder: vfRect),
          ),

          // ── Instruction text ─────────────────────────────────────────────
          Positioned(
            left: 24,
            right: 24,
            top: vfRect.bottom + 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.instruction,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ),
          ),

          // ── Processing overlay ───────────────────────────────────────────
          if (_isCapturing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Reading text…',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Bottom controls ──────────────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: mq.padding.bottom + 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Close button
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 24),
                  ),
                ),
                // Capture button
                GestureDetector(
                  onTap: _isCapturing ? null : _capture,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                // Spacer to balance layout
                const SizedBox(width: 48, height: 48),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── _ViewfinderOverlayPainter ───────────────────────────────────────────────

class _ViewfinderOverlayPainter extends CustomPainter {
  final Rect viewfinder;

  _ViewfinderOverlayPainter({required this.viewfinder});

  @override
  void paint(Canvas canvas, Size size) {
    // Semi-transparent mask with clear viewfinder cutout.
    final maskPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(viewfinder, const Radius.circular(8)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(
      maskPath,
      Paint()..color = Colors.black.withValues(alpha: 0.6),
    );

    // Corner brackets.
    const armLen = 28.0;
    const strokeW = 3.5;
    final bracketPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final r = viewfinder;

    // Top-left
    canvas.drawLine(Offset(r.left, r.top + armLen), Offset(r.left, r.top), bracketPaint);
    canvas.drawLine(Offset(r.left, r.top), Offset(r.left + armLen, r.top), bracketPaint);

    // Top-right
    canvas.drawLine(Offset(r.right - armLen, r.top), Offset(r.right, r.top), bracketPaint);
    canvas.drawLine(Offset(r.right, r.top), Offset(r.right, r.top + armLen), bracketPaint);

    // Bottom-left
    canvas.drawLine(Offset(r.left, r.bottom - armLen), Offset(r.left, r.bottom), bracketPaint);
    canvas.drawLine(Offset(r.left, r.bottom), Offset(r.left + armLen, r.bottom), bracketPaint);

    // Bottom-right
    canvas.drawLine(Offset(r.right - armLen, r.bottom), Offset(r.right, r.bottom), bracketPaint);
    canvas.drawLine(Offset(r.right, r.bottom), Offset(r.right, r.bottom - armLen), bracketPaint);
  }

  @override
  bool shouldRepaint(_ViewfinderOverlayPainter old) =>
      old.viewfinder != viewfinder;
}
