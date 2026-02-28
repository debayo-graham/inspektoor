// Automatic FlutterFlow imports
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

Future<dynamic> upsertAsset(
  String? assetId, // <-- NULL = insert, NOT NULL = update
  String orgId,
  String name,
  String category,
  String make,
  String model,
  List<String>? formIds,
  String? picUrl,
) async {
  final supabase = Supabase.instance.client;

  try {
    // --------------------------------------------------
    // 1. PREPARE ASSET DATA
    // --------------------------------------------------
    final data = <String, dynamic>{
      'org_id': orgId,
      'name': name,
      'category': category,
      'make': make,
      'model': model,
    };

    if (picUrl != null && picUrl.trim().isNotEmpty) {
      data['picUrl'] = picUrl;
    }

    Map<String, dynamic>? assetResponse;

    // --------------------------------------------------
    // 2. INSERT
    // --------------------------------------------------
    if (assetId == null || assetId.trim().isEmpty) {
      assetResponse =
          await supabase.from('assets').insert(data).select().maybeSingle();

      if (assetResponse == null) {
        return {
          'success': false,
          'data': null,
          'error': 'Asset insert returned null.',
          'status': 500,
        };
      }

      // Make sure assetId is now a non-null String
      assetId = assetResponse['id'] as String;
    }

    // --------------------------------------------------
    // 3. UPDATE
    // --------------------------------------------------
    else {
      assetResponse = await supabase
          .from('assets')
          .update(data)
          .eq('id', assetId!) // assetId is non-null here
          .select()
          .maybeSingle();

      if (assetResponse == null) {
        return {
          'success': false,
          'data': null,
          'error': 'Asset update returned null.',
          'status': 500,
        };
      }
    }

    // At this point assetId MUST be non-null
    final String assetIdValue = assetId!;

    // --------------------------------------------------
    // 4. SMART UPDATE FORM RELATIONS
    // --------------------------------------------------
    if (formIds != null) {
      // 4A. Fetch current relations
      final existingRows = await supabase
          .from('asset_inspection_templates')
          .select('inspection_template_id')
          .eq('asset_id', assetIdValue);

      final existingIds = (existingRows as List)
          .map<String>((row) => row['inspection_template_id'] as String)
          .toList();

      // 4B. Determine what to add
      final idsToAdd =
          formIds.where((id) => !existingIds.contains(id)).toList();

      // 4C. Determine what to remove
      final idsToRemove =
          existingIds.where((id) => !formIds.contains(id)).toList();

      // 4D. Insert only the new relations
      if (idsToAdd.isNotEmpty) {
        final rows = idsToAdd.map((formId) {
          return {
            'asset_id': assetIdValue,
            'inspection_template_id': formId,
          };
        }).toList();

        await supabase.from('asset_inspection_templates').insert(rows);
      }

      // 4E. Delete only the removed relations
      if (idsToRemove.isNotEmpty) {
        await supabase
            .from('asset_inspection_templates')
            .delete()
            .eq('asset_id', assetIdValue)
            .inFilter('inspection_template_id', idsToRemove);
      }
    }

    // --------------------------------------------------
    // 5. SUCCESS RESPONSE
    // --------------------------------------------------
    return {
      'success': true,
      'data': assetResponse,
      'error': null,
      'status': 200,
    };
  }

  // --------------------------------------------------
  // 6. DATABASE ERRORS
  // --------------------------------------------------
  on PostgrestException catch (e) {
    print('DATABASE ERROR: ${e.message} (Code: ${e.code})');

    final raw = e.code;
    final status = raw != null ? int.tryParse(raw) ?? 500 : 500;

    return {
      'success': false,
      'data': null,
      'error': e.message,
      'status': status,
    };
  }

  // --------------------------------------------------
  // 7. UNEXPECTED ERRORS
  // --------------------------------------------------
  catch (e) {
    print('UNEXPECTED ERROR: $e');
    return {
      'success': false,
      'data': null,
      'error': e.toString(),
      'status': 500,
    };
  }
}
