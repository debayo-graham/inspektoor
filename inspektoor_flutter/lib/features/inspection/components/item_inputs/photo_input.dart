import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../common/components/photo_capture_box.dart';
import '../../inspection_tokens.dart';

// ─── InspectionPhotoInput ─────────────────────────────────────────────────────
//
// Photo capture input for inspection items of type "photo".
// Wraps the reusable PhotoCaptureBox with a status hint row below.
// No FlutterFlow imports — camera capture callback is injected by the parent.

class InspectionPhotoInput extends StatelessWidget {
  final List<Uint8List> photos;
  final int maxPhotos;
  final bool disabled;
  final void Function(List<Uint8List>) onPhotosChanged;
  final Future<Uint8List?> Function() onCapturePhoto;
  final bool isTablet;

  const InspectionPhotoInput({
    super.key,
    required this.photos,
    this.maxPhotos = 5,
    this.disabled = false,
    required this.onPhotosChanged,
    required this.onCapturePhoto,
    this.isTablet = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhotos = photos.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Photo capture box ───────────────────────────────────────────────
        PhotoCaptureBox(
          photos: photos,
          maxPhotos: maxPhotos,
          borderColor: kInspBorder,
          accentColor: const Color(0xFF0284C7), // sky-600
          accentBgColor: const Color(0xFFE0F2FE), // sky-100
          onPhotosChanged: onPhotosChanged,
          onCapturePhoto: onCapturePhoto,
          emptyLabel: 'Tap to take photo',
          emptySubtitle: 'Capture photo evidence',
        ),

        // ── Status hint ─────────────────────────────────────────────────────
        const SizedBox(height: 8),
        Text(
          hasPhotos
              ? '✓ ${photos.length} photo${photos.length == 1 ? '' : 's'} captured'
              : '⚠ At least 1 photo required',
          style: inspInterStyle(
            12,
            FontWeight.w600,
            hasPhotos ? kInspPassFill : kInspWarning,
          ),
        ),
      ],
    );
  }
}
