import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '/custom_code/actions/build_values_for_pass_all_sub_checks.dart';
import '../inspection_session.dart';
import '../inspection_tokens.dart';
import 'inspection_progress_header.dart';
import 'pill_button.dart';
import 'item_inputs/option_grid.dart';
import 'item_inputs/multi_check_list.dart';
import 'item_inputs/multi_choice_list.dart';
import 'item_inputs/text_entry.dart';
import 'item_inputs/stub_notice.dart';
import 'item_inputs/signature_pad.dart';

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
  });

  @override
  State<InspectionItemStep> createState() => _InspectionItemStepState();
}

class _InspectionItemStepState extends State<InspectionItemStep> {
  bool _submitting = false;

  // multi-check: sub-check id → 'pass' | 'fail' | '' (unset)
  late final Map<String, String> _checkValues;

  // multiple-choice (allowMultiple): selected option labels
  final Set<String> _multiSelected = {};

  // text / numeric inputs
  final TextEditingController _textCtrl = TextEditingController();

  // single-check / single multiple-choice: last selected label
  String _singleChoice = '';

  // signature: raw PNG bytes captured by InspectionSignaturePad
  Uint8List? _signatureBytes;

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

    final savedMulti = (cache['multiSelected'] as List?)?.cast<String>() ?? [];
    _multiSelected.addAll(savedMulti);

    _textCtrl.text = (cache['text'] as String?) ?? '';
    _textCtrl.addListener(_onTextChanged);

    _singleChoice = (cache['singleChoice'] as String?) ?? '';

    final savedSig = cache['signatureBase64'] as String?;
    if (savedSig != null && savedSig.isNotEmpty) {
      _signatureBytes = base64Decode(savedSig);
    }
  }

  @override
  void dispose() {
    _textCtrl.removeListener(_onTextChanged);
    _textCtrl.dispose();
    super.dispose();
  }

  void _onTextChanged() => _updateCache();

  void _updateCache() {
    widget.onCacheChanged({
      'checkValues': Map<String, String>.from(_checkValues),
      'multiSelected': _multiSelected.toList(),
      'text': _textCtrl.text,
      'singleChoice': _singleChoice,
      'signatureBase64': _signatureBytes != null
          ? base64Encode(_signatureBytes!)
          : null,
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

    if (t == 'signature') {
      if (_signatureBytes == null) return;
      _submit([
        {
          'key': 'signature_data',
          'label': 'Signature',
          'value': base64Encode(_signatureBytes!),
        }
      ]);
      return;
    }

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
    }

    _submit(InspectionSession.buildValues(
      type: t,
      checkValues: _checkValues,
      multiSelected: _multiSelected,
      textValue: _textCtrl.text,
      checks: (_cfg['checks'] as List? ?? [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InspectionProgressHeader(
            step: widget.step,
            total: widget.total,
            label: widget.item['label'] as String? ?? '',
            templateItems: widget.templateItems,
            defectMap: widget.defectMap,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: InspectionInputCard(child: _buildInputArea()),
            ),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    final t = widget.item['type'] as String? ?? '';
    final allowMultiple = _cfg['allowMultiple'] as bool? ?? false;

    return switch (t) {
      'single-check' => InspectionOptionGrid(
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
          onToggle: (id, val) {
            setState(() => _checkValues[id] = val);
            _updateCache();
          },
          onPassAll: () async {
            final checks = (_cfg['checks'] as List? ?? []).toList();
            final vals = await buildValuesForPassAllSubChecks(checks);
            setState(() {
              for (final key in _checkValues.keys.toList()) {
                _checkValues[key] = 'pass';
              }
            });
            _updateCache();
            await _submit(vals);
          },
          submitting: _submitting,
        ),
      'numeric' => InspectionTextEntry(
          controller: _textCtrl,
          placeholder: _cfg['placeholder'] as String? ?? 'Enter value',
          suffix: _cfg['unit'] as String?,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          formatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d.\-]'))
          ],
        ),
      'comment-box' => InspectionTextEntry(
          controller: _textCtrl,
          placeholder:
              _cfg['placeholder'] as String? ?? 'Enter comment…',
          maxLines: 5,
          maxLength: (_cfg['maxLength'] as num?)?.toInt(),
        ),
      'alphanumeric' => InspectionTextEntry(
          controller: _textCtrl,
          placeholder: _cfg['placeholder'] as String? ?? 'Enter value',
          maxLength: (_cfg['maxLength'] as num?)?.toInt(),
        ),
      'photo' => const InspectionStubNotice(
          icon: Icons.photo_camera_outlined,
          message: 'Photo capture is not yet available.',
        ),
      'signature' => InspectionSignaturePad(
          submitting: _submitting,
          onCapture: (bytes) {
            setState(() => _signatureBytes = bytes);
            _updateCache();
          },
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
    return true;
  }

  Widget _buildFooter() {
    final hasBack = widget.onBack != null;
    final hasNext = _needsNextButton;

    if (!hasBack && !hasNext) return const SizedBox.shrink();

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      child: hasBack && hasNext
          ? Row(
              children: [
                Expanded(
                  child: InspectionPillButton(
                    label: 'Previous',
                    leadingIcon: Icons.arrow_back_rounded,
                    onTap: _submitting ? null : () => widget.onBack!(),
                    outlined: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InspectionPillButton(
                    label: _submitting ? 'Saving…' : 'Next',
                    trailingIcon: Icons.arrow_forward_rounded,
                    onTap: (_submitting || !_canNext) ? null : _handleNext,
                    outlined: false,
                  ),
                ),
              ],
            )
          : hasNext
              ? Center(
                  child: FractionallySizedBox(
                    widthFactor: 0.5,
                    child: InspectionPillButton(
                      label: _submitting ? 'Saving…' : 'Next',
                      trailingIcon: Icons.arrow_forward_rounded,
                      onTap: (_submitting || !_canNext) ? null : _handleNext,
                      outlined: false,
                    ),
                  ),
                )
              : InspectionPillButton(
                  label: 'Previous',
                  leadingIcon: Icons.arrow_back_rounded,
                  onTap: _submitting ? null : () => widget.onBack!(),
                  outlined: true,
                ),
    );
  }
}
