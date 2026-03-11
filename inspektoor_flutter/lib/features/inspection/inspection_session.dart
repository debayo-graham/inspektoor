import 'dart:convert';

/// Pure-Dart helpers for the inspection runner.
///
/// No Flutter or FlutterFlow imports — all methods operate on plain Dart
/// types so they are easily unit-testable without a widget environment.
class InspectionSession {
  InspectionSession._();

  // ── Template ──────────────────────────────────────────────────────────────

  /// Parses a raw template JSON string into a sorted list of items.
  ///
  /// Throws [FormatException] with a human-readable message if the input
  /// is empty or structurally invalid.
  static List<Map<String, dynamic>> parseTemplate(String raw) {
    if (raw.isEmpty) {
      throw const FormatException(
        'No template loaded. Please select an inspection form before starting.',
      );
    }
    final decoded = json.decode(raw);
    if (decoded is! Map || decoded['items'] is! List) {
      throw const FormatException('Invalid template format.');
    }
    final items = (decoded['items'] as List)
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList()
      ..sort(
        (a, b) => ((a['order'] as num?) ?? 0)
            .compareTo((b['order'] as num?) ?? 0),
      );

    // Remove any user-added signature items (signature is now auto-appended).
    items.removeWhere((e) => e['type'] == 'signature');

    // Always append a mandatory signature step at the end.
    items.add({
      'key': '__final_signature__',
      'type': 'signature',
      'label': 'Sign here',
      'order': 999999,
      'config': <String, dynamic>{
        'note': 'Please sign to complete the inspection',
      },
    });

    return items;
  }

  // ── Draft queries ─────────────────────────────────────────────────────────

  /// Returns the asset name stored in the draft JSON, or empty string.
  static String assetName(String draftRaw) {
    if (draftRaw.isEmpty) return '';
    try {
      final draft = json.decode(draftRaw);
      return (draft['asset_name'] as String?) ?? '';
    } catch (_) {}
    return '';
  }

  /// Returns the started_at timestamp from the draft JSON, or null.
  static DateTime? startedAt(String draftRaw) {
    if (draftRaw.isEmpty) return null;
    try {
      final draft = json.decode(draftRaw);
      final s = draft['started_at'] as String?;
      if (s != null) return DateTime.tryParse(s);
    } catch (_) {}
    return null;
  }

  /// Returns the completed_at timestamp from the draft JSON, or null.
  static DateTime? completedAt(String draftRaw) {
    if (draftRaw.isEmpty) return null;
    try {
      final draft = json.decode(draftRaw);
      final s = draft['completed_at'] as String?;
      if (s != null) return DateTime.tryParse(s);
    } catch (_) {}
    return null;
  }

  /// Returns the number of answered items in the draft JSON.
  static int answeredCount(String draftRaw) {
    if (draftRaw.isEmpty) return 0;
    try {
      final draft = json.decode(draftRaw);
      if (draft is Map && draft['items'] is List) {
        return (draft['items'] as List).length;
      }
    } catch (_) {}
    return 0;
  }

  /// Returns a map of template_item_key → hasDefect for all answered items.
  ///
  /// An item has a defect when any of its values equals 'fail', 'failed',
  /// or 'no' (case-insensitive), OR when a numeric value is out of the
  /// configured min/max range.
  static Map<String, bool> defectMap(
    String draftRaw, {
    List<Map<String, dynamic>> templateItems = const [],
  }) {
    if (draftRaw.isEmpty) return {};
    try {
      final draft = json.decode(draftRaw);
      final items = (draft['items'] as List? ?? []);

      // Build a lookup: template_item_key → template config
      final configByKey = <String, Map<String, dynamic>>{};
      for (final t in templateItems) {
        final k = t['key'] as String? ?? '';
        if (k.isNotEmpty) configByKey[k] = t;
      }

      final result = <String, bool>{};
      for (final item in items) {
        final key = item['template_item_key'] as String? ?? '';
        final values = (item['values'] as List? ?? []);

        // Standard check: fail / failed / no
        var hasDefect = values.any((v) {
          final raw = (v as Map?)?['value'];
          if (raw is! String) return false;
          return ['fail', 'failed', 'no'].contains(raw.toLowerCase());
        });

        // Numeric range check
        if (!hasDefect && configByKey.containsKey(key)) {
          final tpl = configByKey[key]!;
          final type = tpl['type'] as String? ?? '';
          if (type == 'numeric') {
            final cfg = Map<String, dynamic>.from(tpl['config'] as Map? ?? {});
            final mn = cfg['min'] as num?;
            final mx = cfg['max'] as num?;
            if (mn != null || mx != null) {
              final firstV = values.isNotEmpty ? values.first : null;
              final valStr = (firstV as Map?)?['value'] as String? ?? '';
              final v = num.tryParse(valStr.trim());
              if (v != null) {
                final outOfRange =
                    (mn != null && v < mn) || (mx != null && v > mx);
                if (outOfRange) hasDefect = true;
              }
            }
          }
        }

        result[key] = hasDefect;
      }
      return result;
    } catch (_) {}
    return {};
  }

  /// Returns all answered items from the draft as typed maps.
  static List<Map<String, dynamic>> answeredItems(String draftRaw) {
    if (draftRaw.isEmpty) return [];
    try {
      final draft = json.decode(draftRaw);
      return (draft['items'] as List? ?? [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (_) {}
    return [];
  }

  // ── Item type policy ──────────────────────────────────────────────────────

  /// Returns true when the item type requires a Next button rather than
  /// an immediate tap-to-submit interaction.
  static bool needsNextButton(String type, {bool allowMultiple = false}) =>
      type == 'numeric' ||
      type == 'comment-box' ||
      type == 'alphanumeric' ||
      type == 'photo' ||
      type == 'signature' ||
      type == 'single-check' ||
      type == 'multi-check' ||
      (type == 'multiple-choice' && allowMultiple);

  // ── Value assembly ────────────────────────────────────────────────────────

  /// Returns the number of sub-checks in [checkValues] that have no selection.
  ///
  /// Call this before [buildValues] for 'multi-check' items to validate that
  /// every sub-check has been answered.
  static int unsetMultiCheckCount(Map<String, String> checkValues) =>
      checkValues.values.where((v) => v.isEmpty).length;

  /// Assembles the submission values list for the given item [type] and
  /// current answer state.
  ///
  /// For 'multi-check', all checks must be set before calling — use
  /// [unsetMultiCheckCount] to validate first.
  static List<Map<String, dynamic>> buildValues({
    required String type,
    required Map<String, String> checkValues,
    required Set<String> multiSelected,
    required String textValue,
    required List<Map<String, dynamic>> checks,
  }) {
    switch (type) {
      case 'numeric':
      case 'comment-box':
      case 'alphanumeric':
        return [
          {'key': 'value', 'label': 'Value', 'value': textValue.trim()}
        ];

      case 'multi-check':
        return checkValues.entries.map((e) {
          final match = checks.firstWhere(
            (c) => c['id'] == e.key,
            orElse: () => {'id': e.key, 'label': e.key},
          );
          return {
            'key': e.key,
            'label': match['label'] as String? ?? e.key,
            'value': e.value,
          };
        }).toList();

      case 'multiple-choice':
        return multiSelected
            .map((l) => {'key': l, 'label': l, 'value': l})
            .toList();

      default:
        // photo / signature stubs
        return [
          {'key': 'skipped', 'label': 'Skipped', 'value': 'skipped'}
        ];
    }
  }
}
