// Automatic FlutterFlow imports
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'dart:convert';

/// Persists the in-memory inspection draft to the database.
///
/// Inserts one row into `inspections`, one row per item into
/// `inspection_items`, and one row per value into
/// `inspection_item_values`.
///
/// Returns `{ 'success': true/false, 'data': ..., 'error': ..., 'status': ... }`
/// following the same pattern as `upsertAsset`.
Future<dynamic> caSubmitInspection() async {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser?.id;

  try {
    // ── 1. Parse the draft ───────────────────────────────────────────────
    final draftRaw = FFAppState().inspectionDraftJson;
    if (draftRaw.isEmpty) {
      return _err('No inspection draft found.', 400);
    }

    final draft = json.decode(draftRaw) as Map<String, dynamic>;
    final assetId = draft['asset_id'] as String?;
    final templateId = draft['template_id'] as String?;
    final startedAt = draft['started_at'] as String?;
    final completedAt = draft['completed_at'] as String?;
    final gps = draft['gps'];
    final items = (draft['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    if (assetId == null || templateId == null) {
      return _err('Draft is missing asset_id or template_id.', 400);
    }

    final orgId = FFAppState().currentOrgId;
    if (orgId.isEmpty) {
      return _err('No org_id available.', 400);
    }

    // ── 2. Parse the template to get config per item ─────────────────────
    final templateItems = _parseTemplateItems(FFAppState().templateJson);

    // ── 3. INSERT inspection ─────────────────────────────────────────────
    final inspectionRow = await supabase
        .from('inspections')
        .insert({
          'org_id': orgId,
          'asset_id': assetId,
          'template_id': templateId,
          'status': 'completed',
          'started_at': startedAt,
          'completed_at':
              completedAt ?? DateTime.now().toUtc().toIso8601String(),
          'gps': gps,
          'created_by': userId,
        })
        .select('id')
        .single();

    final inspectionId = inspectionRow['id'] as String;

    // ── 4. INSERT inspection_items (batch) ───────────────────────────────
    if (items.isNotEmpty) {
      final itemRows = items.map((item) {
        final key = item['template_item_key'] as String? ?? '';
        final tplItem = templateItems[key];
        return {
          'inspection_id': inspectionId,
          'template_item_key': key,
          'type': item['type'] as String? ?? '',
          'label': item['label'] as String? ?? '',
          'order': (item['order'] as num?)?.toInt() ?? 0,
          'config': tplItem?['config'],
          'created_by': userId,
        };
      }).toList();

      final insertedItems = await supabase
          .from('inspection_items')
          .insert(itemRows)
          .select('id, template_item_key');

      // Build a lookup: template_item_key → inspection_item id
      final itemIdMap = <String, String>{};
      for (final row in insertedItems as List) {
        itemIdMap[row['template_item_key'] as String] = row['id'] as String;
      }

      // ── 5. INSERT inspection_item_values (batch) ─────────────────────
      final valueRows = <Map<String, dynamic>>[];
      for (final item in items) {
        final key = item['template_item_key'] as String? ?? '';
        final itemId = itemIdMap[key];
        if (itemId == null) continue;

        final values =
            (item['values'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        for (final v in values) {
          valueRows.add({
            'inspection_item_id': itemId,
            'key': v['key'] as String? ?? '',
            'label': v['label'] as String?,
            'value': _stringifyValue(v['value']),
          });
        }
      }

      if (valueRows.isNotEmpty) {
        await supabase.from('inspection_item_values').insert(valueRows);
      }
    }

    // ── 6. Success ───────────────────────────────────────────────────────
    return {
      'success': true,
      'data': {'inspection_id': inspectionId},
      'error': null,
      'status': 200,
    };
  } on PostgrestException catch (e) {
    debugPrint('DATABASE ERROR in caSubmitInspection: ${e.message}');
    final raw = e.code;
    final status = raw != null ? int.tryParse(raw) ?? 500 : 500;
    return _err(e.message, status);
  } catch (e) {
    debugPrint('UNEXPECTED ERROR in caSubmitInspection: $e');
    return _err(e.toString(), 500);
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────────

Map<String, dynamic> _err(String message, int status) => {
      'success': false,
      'data': null,
      'error': message,
      'status': status,
    };

/// Ensures the value column always receives a String (or null).
/// Lists and maps are JSON-encoded.
String? _stringifyValue(dynamic val) {
  if (val == null) return null;
  if (val is String) return val;
  return json.encode(val);
}

/// Parse template JSON into a map keyed by item key for config lookup.
Map<String, Map<String, dynamic>> _parseTemplateItems(String templateRaw) {
  final result = <String, Map<String, dynamic>>{};
  if (templateRaw.isEmpty) return result;
  try {
    final parsed = json.decode(templateRaw);
    List<dynamic> items;
    if (parsed is Map && parsed.containsKey('items')) {
      items = parsed['items'] as List? ?? [];
    } else if (parsed is List) {
      items = parsed;
    } else {
      return result;
    }
    for (final item in items) {
      if (item is Map<String, dynamic>) {
        final key = item['key'] as String? ?? '';
        if (key.isNotEmpty) result[key] = item;
      }
    }
  } catch (_) {}
  return result;
}
