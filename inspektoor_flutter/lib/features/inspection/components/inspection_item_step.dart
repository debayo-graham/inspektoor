import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


import '../inspection_session.dart';
import '../inspection_tokens.dart';
import 'item_inputs/option_grid.dart';
import 'item_inputs/single_check_card.dart';
import 'item_inputs/multi_check_list.dart';
import 'item_inputs/multi_choice_list.dart';
import 'item_inputs/numeric_input.dart';
import 'item_inputs/alphanumeric_input.dart';
import 'item_inputs/comment_box_input.dart';
import 'item_inputs/photo_input.dart';
import 'item_inputs/stub_notice.dart';
import 'item_inputs/signature_pad.dart';
import '/flutter_flow/upload_data.dart';

// ─── InspectionInputCard ──────────────────────────────────────────────────────

class InspectionInputCard extends StatelessWidget {
  final Widget child;
  const InspectionInputCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kInspCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kInspBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }
}

// ─── InspectionItemStep ───────────────────────────────────────────────────────

class InspectionItemStep extends StatefulWidget {
  final Map<String, dynamic> item;
  final int step;
  final int total;
  final List<Map<String, dynamic>> templateItems;
  final Map<String, bool> defectMap;
  final Future<void> Function(List<dynamic> values) onSubmit;
  final Future<void> Function()? onBack;
  final Map<String, dynamic> initialCache;
  final void Function(Map<String, dynamic>) onCacheChanged;

  /// When true, the step widget does not render its own footer buttons.
  /// Used on tablet where the sidebar owns navigation.
  final bool hideFooter;

  /// Whether the layout is tablet-sized (≥768px). Passed to input widgets
  /// so they can render wider 2-column layouts.
  final bool isTablet;

  /// External notifier updated by the step widget with its current _canNext.
  final ValueNotifier<bool>? canNextNotifier;

  /// External notifier populated with the step's _handleNext callback.
  final ValueNotifier<VoidCallback?>? handleNextNotifier;

  const InspectionItemStep({
    required super.key,
    required this.item,
    required this.step,
    required this.total,
    required this.templateItems,
    required this.defectMap,
    required this.onSubmit,
    required this.onBack,
    required this.initialCache,
    required this.onCacheChanged,
    this.hideFooter = false,
    this.isTablet = false,
    this.canNextNotifier,
    this.handleNextNotifier,
  });

  @override
  State<InspectionItemStep> createState() => _InspectionItemStepState();
}

class _InspectionItemStepState extends State<InspectionItemStep> {
  bool _submitting = false;
  bool _submitted = false;

  // multi-check: sub-check id → 'pass' | 'fail' | '' (unset)
  late final Map<String, String> _checkValues;

  // Failure notes keyed by check id (multi-check) or '_single' (single-check)
  late final Map<String, String> _failureNotes;

  // Failure photos keyed by check id (multi-check) or '_single' (single-check)
  final Map<String, List<Uint8List>> _failurePhotos = {};

  // multiple-choice (allowMultiple): selected option labels
  final Set<String> _multiSelected = {};

  // text / numeric inputs
  final TextEditingController _textCtrl = TextEditingController();

  // single-check / single multiple-choice: last selected label
  String _singleChoice = '';

  // signature: raw PNG bytes captured by InspectionSignaturePad
  Uint8List? _signatureBytes;

  // photo type: captured photos
  List<Uint8List> _photos = [];

  // OCR captured image bytes (numeric input with OCR)
  Uint8List? _ocrImageBytes;

  /// Key used to store single-check failure data in the notes/photos maps.
  static const _singleKey = '_single';

  @override
  void initState() {
    super.initState();
    final cache = widget.initialCache;

    if (widget.item['type'] == 'multi-check') {
      final checks = (_cfg['checks'] as List? ?? []).whereType<Map>();
      final saved = Map<String, String>.from(
        (cache['checkValues'] as Map?)?.cast<String, String>() ?? {},
      );
      _checkValues = {
        for (final c in checks)
          if (c['id'] != null)
            c['id'] as String: saved[c['id'] as String] ?? '',
      };
    } else {
      _checkValues = {};
    }

    _failureNotes = Map<String, String>.from(
      (cache['failureNotes'] as Map?)?.cast<String, String>() ?? {},
    );

    final savedMulti = (cache['multiSelected'] as List?)?.cast<String>() ?? [];
    _multiSelected.addAll(savedMulti);

    _textCtrl.text = (cache['text'] as String?) ?? '';
    _textCtrl.addListener(_onTextChanged);

    _singleChoice = (cache['singleChoice'] as String?) ?? '';

    final savedSig = cache['signatureBase64'] as String?;
    if (savedSig != null && savedSig.isNotEmpty) {
      _signatureBytes = base64Decode(savedSig);
    }

    final savedOcr = cache['ocrImageBase64'] as String?;
    if (savedOcr != null && savedOcr.isNotEmpty) {
      _ocrImageBytes = base64Decode(savedOcr);
    }

    // Restore photo-type photos
    final savedPhotos2 = (cache['photos'] as List?)?.whereType<String>() ?? [];
    _photos = savedPhotos2
        .where((s) => s.isNotEmpty)
        .map((s) => base64Decode(s))
        .toList();

    // Restore failure photos — backward-compatible with old single-photo format
    final savedPhotos =
        (cache['failurePhotos'] as Map?)?.cast<String, dynamic>() ?? {};
    for (final entry in savedPhotos.entries) {
      if (entry.value is String && (entry.value as String).isNotEmpty) {
        // Legacy single-photo format → migrate to single-item list
        _failurePhotos[entry.key] = [base64Decode(entry.value as String)];
      } else if (entry.value is List) {
        _failurePhotos[entry.key] = (entry.value as List)
            .whereType<String>()
            .where((s) => s.isNotEmpty)
            .map((s) => base64Decode(s))
            .toList();
      }
    }
  }

  @override
  void dispose() {
    _textCtrl.removeListener(_onTextChanged);
    _textCtrl.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    _updateCache();
    // Eagerly push the current validation state to the sidebar notifier
    // so the Continue button updates without waiting for a full rebuild.
    widget.canNextNotifier?.value = _canNext;
    if (mounted) setState(() {});
  }

  void _updateCache() {
    widget.onCacheChanged({
      'checkValues': Map<String, String>.from(_checkValues),
      'failureNotes': Map<String, String>.from(_failureNotes),
      'multiSelected': _multiSelected.toList(),
      'text': _textCtrl.text,
      'singleChoice': _singleChoice,
      'signatureBase64': _signatureBytes != null
          ? base64Encode(_signatureBytes!)
          : null,
      'ocrImageBase64': _ocrImageBytes != null
          ? base64Encode(_ocrImageBytes!)
          : null,
      'failurePhotos': {
        for (final e in _failurePhotos.entries)
          if (e.value.isNotEmpty)
            e.key: e.value.map((b) => base64Encode(b)).toList(),
      },
      'photos': _photos.map((b) => base64Encode(b)).toList(),
    });
  }

  Map<String, dynamic> get _cfg =>
      Map<String, dynamic>.from(widget.item['config'] as Map? ?? {});

  List<Map<String, dynamic>> get _options =>
      (_cfg['options'] as List? ?? [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

  Future<void> _submit(List<dynamic> values) async {
    if (_submitting) return;
    _submitted = true;
    setState(() => _submitting = true);
    try {
      await widget.onSubmit(values);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  bool get _needsNextButton => InspectionSession.needsNextButton(
        widget.item['type'] as String? ?? '',
        allowMultiple: _cfg['allowMultiple'] as bool? ?? false,
      );

  void _handleNext() {
    final t = widget.item['type'] as String? ?? '';
    final itemLabel = widget.item['label'] as String? ?? '';

    if (t == 'photo') {
      if (_photos.isEmpty) return;
      _submit([
        {
          'key': 'photos',
          'label': itemLabel.isNotEmpty ? itemLabel : 'Photos',
          'value': null,
          '_photos': _photos.map((b) => base64Encode(b)).toList(),
        }
      ]);
      return;
    }

    if (t == 'signature') {
      if (_signatureBytes == null) return;
      _submit([
        {
          'key': 'signature_data',
          'label': itemLabel.isNotEmpty ? itemLabel : 'Signature',
          'value': null,
          '_photos': [base64Encode(_signatureBytes!)],
          '_isSignature': true,
        }
      ]);
      return;
    }

    // ── Single-check validation ────────────────────────────────────────
    if (t == 'single-check') {
      if (_singleChoice.isEmpty) return;
      final isFail = _singleChoice.toLowerCase() == 'fail';
      if (isFail) {
        final reqPhoto = _cfg['photoRequired'] as bool? ?? false;
        final hasNote = (_failureNotes[_singleKey] ?? '').trim().isNotEmpty;
        final hasPhotos = (_failurePhotos[_singleKey] ?? []).isNotEmpty;
        if (reqPhoto && !hasPhotos) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
              'Photo evidence is required for failed items.',
              style: inspInterStyle(13, FontWeight.w500, Colors.white),
            ),
            backgroundColor: kInspPrimaryText,
            behavior: SnackBarBehavior.floating,
          ));
          return;
        }
        if (!hasNote && !hasPhotos) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
              'A note or photo is required before continuing.',
              style: inspInterStyle(13, FontWeight.w500, Colors.white),
            ),
            backgroundColor: kInspPrimaryText,
            behavior: SnackBarBehavior.floating,
          ));
          return;
        }
      }
      _submit([
        {
          'key': 'selected',
          'label': _singleChoice,
          'value': _singleChoice,
          if (_singleChoice.toLowerCase() == 'fail') ...{
            '_photos': (_failurePhotos[_singleKey] ?? [])
                .map((b) => base64Encode(b))
                .toList(),
            '_comment': (_failureNotes[_singleKey] ?? '').trim(),
          },
        }
      ]);
      return;
    }

    // ── Multi-check validation ─────────────────────────────────────────
    if (t == 'multi-check') {
      final unset = InspectionSession.unsetMultiCheckCount(_checkValues);
      if (unset > 0) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            '$unset check${unset == 1 ? '' : 's'} still need a Pass or Fail selection.',
            style: inspInterStyle(13, FontWeight.w500, Colors.white),
          ),
          backgroundColor: kInspPrimaryText,
          behavior: SnackBarBehavior.floating,
        ));
        return;
      }

      // Validate failure evidence (per-check photoRequired)
      final itemReqPhoto = _cfg['photoRequired'] as bool? ?? false;
      final checksConfig = (_cfg['checks'] as List? ?? []).whereType<Map>();
      final failedIds = _checkValues.entries
          .where((e) => e.value == 'fail')
          .map((e) => e.key);
      for (final id in failedIds) {
        final checkCfg = checksConfig
            .cast<Map<String, dynamic>>()
            .where((c) => c['id'] == id)
            .firstOrNull;
        final reqPhoto =
            checkCfg?['photoRequired'] as bool? ?? itemReqPhoto;
        final hasNote = (_failureNotes[id] ?? '').trim().isNotEmpty;
        final hasPhotos = (_failurePhotos[id] ?? []).isNotEmpty;
        if (reqPhoto && !hasPhotos) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
              'Photo evidence is required for failed items.',
              style: inspInterStyle(13, FontWeight.w500, Colors.white),
            ),
            backgroundColor: kInspPrimaryText,
            behavior: SnackBarBehavior.floating,
          ));
          return;
        }
        if (!hasNote && !hasPhotos) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
              'Failed items need a note or photo before continuing.',
              style: inspInterStyle(13, FontWeight.w500, Colors.white),
            ),
            backgroundColor: kInspPrimaryText,
            behavior: SnackBarBehavior.floating,
          ));
          return;
        }
      }
    }

    final rawValues = InspectionSession.buildValues(
      type: t,
      checkValues: _checkValues,
      multiSelected: _multiSelected,
      textValue: _textCtrl.text,
      checks: (_cfg['checks'] as List? ?? [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList(),
      itemLabel: itemLabel.isNotEmpty ? itemLabel : 'Value',
    );
    // Enrich failed checks with failure photos and notes for upload.
    // Copy to Map<String, dynamic> since buildValues returns Map<String, String>.
    final submitValues = rawValues.map((v) {
      final m = Map<String, dynamic>.from(v);
      if (t == 'multi-check' && m['value'] == 'fail') {
        final id = m['key'] as String? ?? '';
        m['_photos'] = (_failurePhotos[id] ?? [])
            .map((b) => base64Encode(b))
            .toList();
        m['_comment'] = (_failureNotes[id] ?? '').trim();
      }
      return m;
    }).toList();
    _submit(submitValues);
  }

  @override
  Widget build(BuildContext context) {
    // Sync external notifiers (if provided) — but skip if this step already
    // submitted. After submission the runner creates a new step widget; the old
    // one (animated out by AnimatedSwitcher) must not overwrite the new step's
    // notifier values. Use a post-frame callback to avoid setting notifiers
    // during the build phase (which can be swallowed by ValueListenableBuilder).
    if (!_submitted) {
      final canNext = _canNext;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _submitted) return;
        widget.canNextNotifier?.value = canNext;
        widget.handleNextNotifier?.value = _handleNext;
      });
    }

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent,
      child: ColoredBox(
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: widget.isTablet
                    ? const EdgeInsets.fromLTRB(32, 24, 32, 16)
                    : const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: _buildScrollableContent(),
              ),
            ),
            if (!widget.hideFooter) _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildScrollableContent() {
    final t = widget.item['type'] as String? ?? '';
    final label = widget.item['label'] as String? ?? '';
    final description = _cfg['description'] as String? ?? '';

    // Types that get the full-width section layout (no InspectionInputCard).
    if (t == 'multi-check' || t == 'single-check' || t == 'numeric' || t == 'alphanumeric' || t == 'comment-box' || t == 'photo' || t == 'signature') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: inspInterStyle(20, FontWeight.w700, kInspPrimaryText),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: inspInterStyle(14, FontWeight.w400, const Color(0xFF94A3B8)),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildInputArea(),
        ],
      );
    }
    return InspectionInputCard(child: _buildInputArea());
  }

  Widget _buildInputArea() {
    final t = widget.item['type'] as String? ?? '';
    final allowMultiple = _cfg['allowMultiple'] as bool? ?? false;

    return switch (t) {
      'single-check' => InspectionSingleCheckCard(
          value: _singleChoice.toLowerCase() == 'pass'
              ? 'pass'
              : _singleChoice.toLowerCase() == 'fail'
                  ? 'fail'
                  : '',
          note: _failureNotes[_singleKey] ?? '',
          photos: _failurePhotos[_singleKey] ?? [],
          disabled: _submitting,
          photoRequired: _cfg['photoRequired'] as bool? ?? false,
          maxPhotos:
              (_cfg['maxPhotos'] as num?)?.toInt().clamp(1, 5) ?? 5,
          isTablet: widget.isTablet,
          photoLabel: widget.item['label'] as String?,
          onToggle: (val) {
            FocusScope.of(context).unfocus();
            setState(() {
              _singleChoice = val == 'pass'
                  ? 'Pass'
                  : val == 'fail'
                      ? 'Fail'
                      : '';
              // Hard reset: clear note & photos when toggling back to pass or unset
              if (val != 'fail') {
                _failureNotes.remove(_singleKey);
                _failurePhotos.remove(_singleKey);
              }
            });
            _updateCache();
            // Auto-submit on Pass (like "Pass All" in multi-check)
            if (val == 'pass') {
              _submit([
                {'key': 'selected', 'label': 'Pass', 'value': 'Pass'}
              ]);
            }
          },
          onNoteChanged: (note) {
            setState(() => _failureNotes[_singleKey] = note);
            _updateCache();
          },
          onPhotosChanged: (photos) {
            setState(() => _failurePhotos[_singleKey] = photos);
            _updateCache();
          },
        ),
      'multiple-choice' when !allowMultiple => InspectionOptionGrid(
          options: _options,
          submitting: _submitting,
          selected: _singleChoice,
          onTap: (label) {
            setState(() => _singleChoice = label);
            _updateCache();
            _submit([
              {'key': 'selected', 'label': label, 'value': label}
            ]);
          },
        ),
      'multiple-choice' => InspectionMultiChoiceList(
          options: _options,
          selected: _multiSelected,
          onToggle: (label) {
            setState(() {
              _multiSelected.contains(label)
                  ? _multiSelected.remove(label)
                  : _multiSelected.add(label);
            });
            _updateCache();
          },
        ),
      'multi-check' => InspectionMultiCheckList(
          checks: (_cfg['checks'] as List? ?? [])
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList(),
          values: _checkValues,
          failureNotes: _failureNotes,
          failurePhotos: _failurePhotos,
          onToggle: (id, val) {
            FocusScope.of(context).unfocus();
            setState(() {
              _checkValues[id] = val;
              // Hard reset: clear note & photos when toggling back to pass.
              if (val == 'pass') {
                _failureNotes.remove(id);
                _failurePhotos.remove(id);
              }
            });
            _updateCache();
          },
          onNoteChanged: (id, note) {
            setState(() => _failureNotes[id] = note);
            _updateCache();
          },
          onPhotosChanged: (id, photoList) {
            setState(() => _failurePhotos[id] = photoList);
            _updateCache();
          },
          onPassAll: () async {
            FocusScope.of(context).unfocus();
            setState(() {
              for (final key in _checkValues.keys.toList()) {
                _checkValues[key] = 'pass';
                _failureNotes.remove(key);
                _failurePhotos.remove(key);
              }
            });
            _updateCache();
            _handleNext();
          },
          submitting: _submitting,
          itemPhotoRequired: _cfg['photoRequired'] as bool? ?? false,
          itemMaxPhotos: (_cfg['maxPhotos'] as num?)?.toInt().clamp(1, 5) ?? 5,
          isTablet: widget.isTablet,
          itemLabel: widget.item['label'] as String?,
        ),
      'numeric' => InspectionNumericInput(
          controller: _textCtrl,
          placeholder: _cfg['placeholder'] as String? ?? 'Enter value',
          unit: _cfg['unit'] as String?,
          min: _cfg['min'] as num?,
          max: _cfg['max'] as num?,
          disabled: _submitting,
          ocrEnabled: _cfg['ocrEnabled'] as bool? ?? false,
          ocrImageBytes: _ocrImageBytes,
          onOcrImageChanged: (bytes) {
            setState(() => _ocrImageBytes = bytes);
            _updateCache();
          },
          isTablet: widget.isTablet,
        ),
      'comment-box' => InspectionCommentBoxInput(
          controller: _textCtrl,
          placeholder:
              _cfg['placeholder'] as String? ?? 'Add your comments here…',
          maxLength: (_cfg['maxLength'] as num?)?.toInt() ?? 500,
          disabled: _submitting,
          ocrEnabled: _cfg['ocrEnabled'] as bool? ?? false,
          ocrImageBytes: _ocrImageBytes,
          onOcrImageChanged: (bytes) {
            setState(() => _ocrImageBytes = bytes);
            _updateCache();
          },
          isTablet: widget.isTablet,
        ),
      'alphanumeric' => InspectionAlphanumericInput(
          controller: _textCtrl,
          placeholder: _cfg['placeholder'] as String? ?? 'Enter value',
          maxLength: (_cfg['maxLength'] as num?)?.toInt(),
          formatPattern: _cfg['formatPattern'] as String? ?? _cfg['regex'] as String?,
          disabled: _submitting,
          ocrEnabled: _cfg['ocrEnabled'] as bool? ?? false,
          ocrImageBytes: _ocrImageBytes,
          onOcrImageChanged: (bytes) {
            setState(() => _ocrImageBytes = bytes);
            _updateCache();
          },
          isTablet: widget.isTablet,
        ),
      'photo' => InspectionPhotoInput(
          photos: _photos,
          maxPhotos: (_cfg['maxPhotos'] as num?)?.toInt().clamp(1, 5) ?? 5,
          disabled: _submitting,
          label: widget.item['label'] as String?,
          onPhotosChanged: (list) {
            setState(() => _photos = list);
            _updateCache();
          },
          onCapturePhoto: () async {
            final selected =
                await selectMedia(mediaSource: MediaSource.camera);
            if (selected != null && selected.isNotEmpty) {
              return selected.first.bytes;
            }
            return null;
          },
          isTablet: widget.isTablet,
        ),
      'signature' => InspectionSignaturePad(
          submitting: _submitting,
          initialBytes: _signatureBytes,
          onCapture: (bytes) {
            setState(() => _signatureBytes = bytes);
            _updateCache();
          },
          isTablet: widget.isTablet,
        ),
      _ => InspectionStubNotice(
          icon: Icons.help_outline,
          message: 'Unsupported item type: $t',
        ),
    };
  }

  bool get _canNext {
    final t = widget.item['type'] as String? ?? '';
    if (t == 'signature') return _signatureBytes != null;
    if (t == 'photo') return _photos.isNotEmpty;

    if (t == 'numeric') {
      final v = num.tryParse(_textCtrl.text.trim());
      return v != null;
    }

    if (t == 'alphanumeric') {
      if (_textCtrl.text.trim().isEmpty) return false;
      final pattern = _cfg['formatPattern'] as String? ?? _cfg['regex'] as String?;
      if (pattern != null && pattern.isNotEmpty) {
        return _textCtrl.text.length == pattern.length;
      }
      return true;
    }

    if (t == 'comment-box') {
      if (_textCtrl.text.trim().isEmpty) return false;
      final maxLen = (_cfg['maxLength'] as num?)?.toInt() ?? 500;
      if (_textCtrl.text.length > maxLen) return false;
      return true;
    }

    if (t == 'single-check') {
      if (_singleChoice.isEmpty) return false;
      final isFail = _singleChoice.toLowerCase() == 'fail';
      if (!isFail) return true;
      final reqPhoto = _cfg['photoRequired'] as bool? ?? false;
      final hasNote = (_failureNotes[_singleKey] ?? '').trim().isNotEmpty;
      final hasPhotos = (_failurePhotos[_singleKey] ?? []).isNotEmpty;
      if (reqPhoto) return hasPhotos;
      return hasNote || hasPhotos;
    }

    if (t == 'multi-check') {
      if (_checkValues.isEmpty ||
          InspectionSession.unsetMultiCheckCount(_checkValues) != 0) {
        return false;
      }
      final itemReqPhoto = _cfg['photoRequired'] as bool? ?? false;
      final checksConfig = (_cfg['checks'] as List? ?? []).whereType<Map>();
      return _checkValues.entries.where((e) => e.value == 'fail').every((e) {
        final checkCfg = checksConfig
            .cast<Map<String, dynamic>>()
            .where((c) => c['id'] == e.key)
            .firstOrNull;
        final reqPhoto =
            checkCfg?['photoRequired'] as bool? ?? itemReqPhoto;
        final hasNote = (_failureNotes[e.key] ?? '').trim().isNotEmpty;
        final hasPhotos = (_failurePhotos[e.key] ?? []).isNotEmpty;
        if (reqPhoto) return hasPhotos;
        return hasNote || hasPhotos;
      });
    }
    return true;
  }

  Widget _buildFooter() {
    final t = widget.item['type'] as String? ?? '';
    if (t == 'multi-check') return _buildMultiCheckFooter();
    if (t == 'single-check') return _buildSingleCheckFooter();
    if (t == 'numeric') return _buildNumericFooter();
    if (t == 'alphanumeric') return _buildAlphanumericFooter();
    if (t == 'comment-box') return _buildCommentBoxFooter();
    if (t == 'photo') return _buildPhotoFooter();
    if (t == 'signature') return _buildSignatureFooter();

    final hasBack = widget.onBack != null;
    final hasNext = _needsNextButton;

    if (!hasBack && !hasNext) return const SizedBox.shrink();

    final ready = _canNext;
    final continueLabel = _submitting
        ? 'Saving…'
        : ready
            ? 'Continue to Next Step →'
            : 'Answer to continue';
    final VoidCallback? onNext = (_submitting || !ready) ? null : _handleNext;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      child: Column(
        children: [
          const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),
          Row(
            children: [
              if (hasBack) ...[
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: kInspSlate,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: kInspBorder, width: 1.5),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: kInspPrimaryText,
                    ),
                    onPressed:
                        _submitting ? null : () => widget.onBack!(),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: hasNext
                    ? GestureDetector(
                        onTap: onNext,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          height: 56,
                          decoration: BoxDecoration(
                            color: ready ? null : kInspBorder,
                            gradient: ready
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFF0EA5E9),
                                      Color(0xFF0284C7),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: ready
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF0EA5E9)
                                          .withValues(alpha: 0.35),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            continueLabel,
                            style: inspInterStyle(
                              15,
                              FontWeight.w700,
                              onNext != null
                                  ? Colors.white
                                  : const Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Numeric footer ─────────────────────────────────────────────────────────

  Widget _buildNumericFooter() {
    final ready = _canNext;
    final mn = _cfg['min'] as num?;
    final mx = _cfg['max'] as num?;
    final hasRange = mn != null || mx != null;
    final v = num.tryParse(_textCtrl.text.trim());
    final outOfRange = hasRange &&
        v != null &&
        ((mn != null && v < mn) || (mx != null && v > mx));

    final Gradient? gradient;
    final Color bgColor;
    final Color? glowColor;
    final String label;
    final VoidCallback? onTap;

    if (!ready) {
      gradient = null;
      bgColor = kInspBorder;
      glowColor = null;
      label = 'Enter a value to continue';
      onTap = null;
    } else if (outOfRange) {
      gradient = null;
      bgColor = kInspWarning;
      glowColor = kInspWarning;
      label = 'Continue with Defect →';
      onTap = _submitting ? null : _handleNext;
    } else {
      gradient = const LinearGradient(
        colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      bgColor = const Color(0xFF0EA5E9);
      glowColor = const Color(0xFF0EA5E9);
      label = 'Continue to Next Step →';
      onTap = _submitting ? null : _handleNext;
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      child: Column(
        children: [
          const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: kInspSlate,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: kInspBorder, width: 1.5),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_back_rounded,
                    color: widget.onBack != null ? kInspPrimaryText : kInspBorder,
                  ),
                  onPressed: _submitting || widget.onBack == null
                      ? null
                      : () => widget.onBack!(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: onTap,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    height: 56,
                    decoration: BoxDecoration(
                      color: gradient == null ? bgColor : null,
                      gradient: gradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: glowColor != null
                          ? [
                              BoxShadow(
                                color: glowColor.withValues(alpha: 0.35),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      label,
                      style: inspInterStyle(
                        15,
                        FontWeight.w700,
                        onTap != null ? Colors.white : const Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Alphanumeric footer ──────────────────────────────────────────────────────

  Widget _buildAlphanumericFooter() {
    final ready = _canNext;

    final Gradient? gradient;
    final Color bgColor;
    final Color? glowColor;
    final String label;
    final VoidCallback? onTap;

    if (!ready) {
      gradient = null;
      bgColor = kInspBorder;
      glowColor = null;
      label = 'Enter a value to continue';
      onTap = null;
    } else {
      gradient = const LinearGradient(
        colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      bgColor = const Color(0xFF0EA5E9);
      glowColor = const Color(0xFF0EA5E9);
      label = 'Continue to Next Step →';
      onTap = _submitting ? null : _handleNext;
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      child: Column(
        children: [
          const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: kInspSlate,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: kInspBorder, width: 1.5),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_back_rounded,
                    color: widget.onBack != null ? kInspPrimaryText : kInspBorder,
                  ),
                  onPressed: _submitting || widget.onBack == null
                      ? null
                      : () => widget.onBack!(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: onTap,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    height: 56,
                    decoration: BoxDecoration(
                      color: gradient == null ? bgColor : null,
                      gradient: gradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: glowColor != null
                          ? [
                              BoxShadow(
                                color: glowColor.withValues(alpha: 0.35),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      label,
                      style: inspInterStyle(
                        15,
                        FontWeight.w700,
                        onTap != null ? Colors.white : const Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Comment-box footer ──────────────────────────────────────────────────────

  Widget _buildCommentBoxFooter() {
    final ready = _canNext;

    final Gradient? gradient;
    final Color bgColor;
    final Color? glowColor;
    final String label;
    final VoidCallback? onTap;

    final maxLen = (_cfg['maxLength'] as num?)?.toInt() ?? 500;
    final overLimit = _textCtrl.text.length > maxLen;

    if (!ready) {
      gradient = null;
      bgColor = kInspBorder;
      glowColor = null;
      label = overLimit
          ? 'Comment exceeds $maxLen characters'
          : 'Add a comment to continue';
      onTap = null;
    } else {
      gradient = const LinearGradient(
        colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      bgColor = const Color(0xFF0EA5E9);
      glowColor = const Color(0xFF0EA5E9);
      label = 'Continue to Next Step →';
      onTap = _submitting ? null : _handleNext;
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      child: Column(
        children: [
          const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: kInspSlate,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: kInspBorder, width: 1.5),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_back_rounded,
                    color: widget.onBack != null ? kInspPrimaryText : kInspBorder,
                  ),
                  onPressed: _submitting || widget.onBack == null
                      ? null
                      : () => widget.onBack!(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: onTap,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    height: 56,
                    decoration: BoxDecoration(
                      color: gradient == null ? bgColor : null,
                      gradient: gradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: glowColor != null
                          ? [
                              BoxShadow(
                                color: glowColor.withValues(alpha: 0.35),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      label,
                      style: inspInterStyle(
                        15,
                        FontWeight.w700,
                        onTap != null ? Colors.white : const Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Single-check footer (same style as multi-check) ────────────────────────

  Widget _buildSingleCheckFooter() {
    final ready = _canNext;
    final isFail = _singleChoice.toLowerCase() == 'fail';
    final isPass = _singleChoice.toLowerCase() == 'pass';

    final Gradient? gradient;
    final Color bgColor;
    final Color? glowColor;
    final String label;
    final VoidCallback? onTap;

    if (_singleChoice.isEmpty) {
      gradient = null;
      bgColor = kInspBorder;
      glowColor = null;
      label = 'Select Pass or Fail to continue';
      onTap = null;
    } else if (isPass) {
      gradient = const LinearGradient(
        colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      bgColor = const Color(0xFF0EA5E9);
      glowColor = const Color(0xFF0EA5E9);
      label = 'Continue to Next Step →';
      onTap = _submitting ? null : _handleNext;
    } else if (isFail && ready) {
      gradient = null;
      bgColor = kInspWarning;
      glowColor = kInspWarning;
      label = 'Continue with Defect →';
      onTap = _submitting ? null : _handleNext;
    } else {
      // fail but not ready (missing note/photo)
      gradient = null;
      bgColor = kInspBorder;
      glowColor = null;
      label = 'Add note or photo to continue';
      onTap = null;
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      child: Column(
        children: [
          const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),
          Row(
            children: [
              // Square back button
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: kInspSlate,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: kInspBorder, width: 1.5),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_back_rounded,
                    color: widget.onBack != null ? kInspPrimaryText : kInspBorder,
                  ),
                  onPressed: _submitting || widget.onBack == null
                      ? null
                      : () => widget.onBack!(),
                ),
              ),
              const SizedBox(width: 12),
              // Context-aware continue button
              Expanded(
                child: GestureDetector(
                  onTap: onTap,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    height: 56,
                    decoration: BoxDecoration(
                      color: gradient == null ? bgColor : null,
                      gradient: gradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: glowColor != null
                          ? [
                              BoxShadow(
                                color: glowColor.withValues(alpha: 0.35),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      label,
                      style: inspInterStyle(
                        15,
                        FontWeight.w700,
                        onTap != null ? Colors.white : const Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Photo footer ──────────────────────────────────────────────────────────

  Widget _buildPhotoFooter() {
    final ready = _canNext;

    final Gradient? gradient;
    final Color bgColor;
    final Color? glowColor;
    final String label;
    final VoidCallback? onTap;

    if (!ready) {
      gradient = null;
      bgColor = kInspBorder;
      glowColor = null;
      label = 'Take a photo to continue';
      onTap = null;
    } else {
      gradient = const LinearGradient(
        colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      bgColor = const Color(0xFF0EA5E9);
      glowColor = const Color(0xFF0EA5E9);
      label = 'Continue to Next Step →';
      onTap = _submitting ? null : _handleNext;
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      child: Column(
        children: [
          const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: kInspSlate,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: kInspBorder, width: 1.5),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_back_rounded,
                    color: widget.onBack != null ? kInspPrimaryText : kInspBorder,
                  ),
                  onPressed: _submitting || widget.onBack == null
                      ? null
                      : () => widget.onBack!(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: onTap,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    height: 56,
                    decoration: BoxDecoration(
                      color: gradient == null ? bgColor : null,
                      gradient: gradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: glowColor != null
                          ? [
                              BoxShadow(
                                color: glowColor.withValues(alpha: 0.35),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      label,
                      style: inspInterStyle(
                        15,
                        FontWeight.w700,
                        onTap != null ? Colors.white : const Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Signature footer ────────────────────────────────────────────────────────

  Widget _buildSignatureFooter() {
    final ready = _canNext;

    final Gradient? gradient;
    final Color bgColor;
    final Color? glowColor;
    final String label;
    final VoidCallback? onTap;

    if (!ready) {
      gradient = null;
      bgColor = kInspBorder;
      glowColor = null;
      label = 'Sign above to continue';
      onTap = null;
    } else {
      gradient = const LinearGradient(
        colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      bgColor = const Color(0xFF0EA5E9);
      glowColor = const Color(0xFF0EA5E9);
      label = 'Continue to Next Step →';
      onTap = _submitting ? null : _handleNext;
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      child: Column(
        children: [
          const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: kInspSlate,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: kInspBorder, width: 1.5),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_back_rounded,
                    color: widget.onBack != null ? kInspPrimaryText : kInspBorder,
                  ),
                  onPressed: _submitting || widget.onBack == null
                      ? null
                      : () => widget.onBack!(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: onTap,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    height: 56,
                    decoration: BoxDecoration(
                      color: gradient == null ? bgColor : null,
                      gradient: gradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: glowColor != null
                          ? [
                              BoxShadow(
                                color: glowColor.withValues(alpha: 0.35),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      label,
                      style: inspInterStyle(
                        15,
                        FontWeight.w700,
                        onTap != null ? Colors.white : const Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMultiCheckFooter() {
    final allAnswered = _canNext;
    final allPassed = allAnswered &&
        _checkValues.values.every((v) => v == 'pass');
    final anyFailed = _checkValues.values.any((v) => v == 'fail');

    // Derive continue button appearance
    final Gradient? gradient;
    final Color bgColor;
    final Color? glowColor;
    final String label;
    final VoidCallback? onTap;

    if (!allAnswered) {
      gradient = null;
      bgColor = kInspBorder;
      glowColor = null;
      label = 'Answer all items to continue';
      onTap = null;
    } else if (allPassed) {
      gradient = const LinearGradient(
        colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      bgColor = const Color(0xFF0EA5E9);
      glowColor = const Color(0xFF0EA5E9);
      label = 'Continue to Next Step →';
      onTap = _submitting ? null : _handleNext;
    } else if (anyFailed) {
      gradient = null;
      bgColor = kInspWarning;
      glowColor = kInspWarning;
      label = 'Continue with Defects →';
      onTap = _submitting ? null : _handleNext;
    } else {
      gradient = null;
      bgColor = kInspBorder;
      glowColor = null;
      label = 'Answer all items to continue';
      onTap = null;
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      child: Row(
        children: [
          // Square back button
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: kInspSlate,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kInspBorder, width: 1.5),
            ),
            child: IconButton(
              icon: Icon(
                Icons.arrow_back_rounded,
                color: widget.onBack != null ? kInspPrimaryText : kInspBorder,
              ),
              onPressed: _submitting || widget.onBack == null
                  ? null
                  : () => widget.onBack!(),
            ),
          ),
          const SizedBox(width: 12),
          // Context-aware continue button
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: 56,
                decoration: BoxDecoration(
                  color: gradient == null ? bgColor : null,
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: glowColor != null
                      ? [
                          BoxShadow(
                            color: glowColor.withValues(alpha: 0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  label,
                  style: inspInterStyle(
                    15,
                    FontWeight.w700,
                    onTap != null ? Colors.white : const Color(0xFF94A3B8),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
