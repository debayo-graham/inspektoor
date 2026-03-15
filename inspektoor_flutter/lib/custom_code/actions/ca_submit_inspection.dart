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

import 'package:image/image.dart' as img;

import '/flutter_flow/upload_data.dart';

/// Persists the in-memory inspection draft to the database.
///
/// Uploads photos/signatures to Supabase Storage, then inserts one row into
/// `inspections`, one row per item into `inspection_items`, and one row per
/// value into `inspection_item_values` (with `photo_url` and `comment`).
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

    // ── 3b. UPDATE asset last_inspected_at ───────────────────────────────
    try {
      await supabase
          .from('assets')
          .update({
            'last_inspected_at':
                completedAt ?? DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', assetId);
    } catch (e) {
      // Non-critical — log but don't fail the submission.
      debugPrint('WARNING: failed to update last_inspected_at: $e');
    }

    // ── 4. INSERT inspection_items (batch) ───────────────────────────────
    if (items.isNotEmpty) {
      // Pre-compute which items were skipped so we can set status and
      // avoid writing sentinel value rows for them.
      final skippedKeys = <String>{};
      for (final item in items) {
        final vals =
            (item['values'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        if (vals.any((v) => v['value'] == 'skipped')) {
          skippedKeys.add(item['template_item_key'] as String? ?? '');
        }
      }

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
          'status': skippedKeys.contains(key) ? 'skipped' : 'completed',
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

      // ── 5. Upload photos & build inspection_item_values ────────────────
      final valueRows = <Map<String, dynamic>>[];
      for (final item in items) {
        final key = item['template_item_key'] as String? ?? '';
        final itemId = itemIdMap[key];
        if (itemId == null) continue;

        // Skipped items have status on the parent row — no value rows needed.
        if (skippedKeys.contains(key)) continue;

        final values =
            (item['values'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        for (final v in values) {
          // Extract transient upload keys (set by _handleNext / _valuesFromCache).
          var photoBase64List =
              (v['_photos'] as List?)?.whereType<String>().toList() ?? [];
          final comment = v['_comment'] as String?;
          var isSignature = v['_isSignature'] == true;

          // Fallback: detect legacy base64 data stored directly in `value`.
          final rawVal = v['value'];
          if (photoBase64List.isEmpty && rawVal is List) {
            final strings = rawVal.whereType<String>().toList();
            if (strings.isNotEmpty && strings.first.length > 100) {
              photoBase64List = strings;
            }
          } else if (photoBase64List.isEmpty &&
              rawVal is String &&
              rawVal.length > 100) {
            photoBase64List = [rawVal];
            isSignature = true;
          }

          // Upload photos to Storage if present.
          String? photoUrlJson;
          if (photoBase64List.isNotEmpty) {
            final urls = await _uploadPhotos(
              orgId: orgId,
              inspectionId: inspectionId,
              itemKey: key,
              checkKey: v['key'] as String? ?? 'photo',
              base64Photos: photoBase64List,
              isSignature: isSignature,
            );
            photoUrlJson = json.encode(urls);
          }

          // If we uploaded photos, clear the value (was base64 data).
          // Otherwise stringify normally.
          final String? valueStr;
          if (photoUrlJson != null || rawVal is List || rawVal == null) {
            valueStr = null;
          } else {
            valueStr = _stringifyValue(rawVal);
          }

          valueRows.add({
            'inspection_item_id': itemId,
            'key': v['key'] as String? ?? '',
            'label': v['label'] as String?,
            'value': valueStr,
            'photo_url': photoUrlJson,
            'comment':
                (comment != null && comment.isNotEmpty) ? comment : null,
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

/// Compresses a photo to 1280px max / 80% JPEG before upload.
/// Signatures are kept as lossless PNG. Falls back to original on error.
Uint8List _compressPhoto(Uint8List bytes, {bool isSignature = false}) {
  try {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return bytes;
    if (isSignature) return Uint8List.fromList(img.encodePng(decoded));
    final resized = decoded.width >= decoded.height
        ? (decoded.width > 1280 ? img.copyResize(decoded, width: 1280) : decoded)
        : (decoded.height > 1280 ? img.copyResize(decoded, height: 1280) : decoded);
    return Uint8List.fromList(img.encodeJpg(resized, quality: 80));
  } catch (_) {
    return bytes;
  }
}

/// Uploads base64-encoded photos to Supabase Storage and returns public URLs.
///
/// Path convention: `{orgId}/{inspectionId}/{itemKey}/{filename}`
Future<List<String>> _uploadPhotos({
  required String orgId,
  required String inspectionId,
  required String itemKey,
  required String checkKey,
  required List<String> base64Photos,
  bool isSignature = false,
}) async {
  final urls = <String>[];
  final ts = DateTime.now().millisecondsSinceEpoch;
  for (var i = 0; i < base64Photos.length; i++) {
    final bytes = _compressPhoto(
      base64Decode(base64Photos[i]),
      isSignature: isSignature,
    );
    final ext = isSignature ? 'png' : 'jpg';
    final filename =
        isSignature ? 'signature_$ts.png' : '${checkKey}_${ts}_$i.$ext';
    final storagePath = '$orgId/$inspectionId/$itemKey/$filename';
    final selectedFile = SelectedFile(
      storagePath: storagePath,
      bytes: Uint8List.fromList(bytes),
    );
    final url = await uploadSupabaseStorageFile(
      bucketName: 'inspection-photos',
      selectedFile: selectedFile,
    );
    urls.add(url);
  }
  return urls;
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
