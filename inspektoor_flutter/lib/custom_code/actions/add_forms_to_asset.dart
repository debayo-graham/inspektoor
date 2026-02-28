// Automatic FlutterFlow imports
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

/// This action is used to add inspection forms to asset when editing an asset
Future<dynamic> addFormsToAsset(
  String assetId,
  List<String>? formIds,
) async {
  final supabase = Supabase.instance.client;

  try {
    // --------------------------------------------------
    // 1. NO FORMS PASSED → NOTHING TO DO
    // --------------------------------------------------
    if (formIds == null || formIds.isEmpty) {
      return {
        'success': true,
        'data': [],
        'error': null,
        'status': 200,
      };
    }

    // --------------------------------------------------
    // 2. LOAD EXISTING FORM RELATIONS FOR THIS ASSET
    // --------------------------------------------------
    final existingRows = await supabase
        .from('asset_inspection_templates')
        .select('inspection_template_id')
        .eq('asset_id', assetId);

    final existingIds = (existingRows as List)
        .map<String>((row) => row['inspection_template_id'] as String)
        .toList();

    // --------------------------------------------------
    // 3. FIGURE OUT WHICH FORM IDS ARE NEW
    // --------------------------------------------------
    final idsToAdd = formIds.where((id) => !existingIds.contains(id)).toList();

    if (idsToAdd.isEmpty) {
      // Everything the sheet returned is already assigned
      return {
        'success': true,
        'data': [],
        'error': null,
        'status': 200,
      };
    }

    // --------------------------------------------------
    // 4. INSERT ONLY THE NEW RELATIONS
    // --------------------------------------------------
    final rowsToInsert = idsToAdd.map((formId) {
      return {
        'asset_id': assetId,
        'inspection_template_id': formId,
      };
    }).toList();

    final insertResult = await supabase
        .from('asset_inspection_templates')
        .insert(rowsToInsert)
        .select();

    // --------------------------------------------------
    // 5. SUCCESS
    // --------------------------------------------------
    return {
      'success': true,
      'data': insertResult,
      'error': null,
      'status': 200,
    };
  }

  // --------------------------------------------------
  // 6. DATABASE ERROR
  // --------------------------------------------------
  on PostgrestException catch (e) {
    print(
        'DATABASE ERROR (caAddAssetFormsSmart): ${e.message} (Code: ${e.code})');
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
  // 7. UNEXPECTED ERROR
  // --------------------------------------------------
  catch (e) {
    print('UNEXPECTED ERROR (caAddAssetFormsSmart): $e');

    return {
      'success': false,
      'data': null,
      'error': e.toString(),
      'status': 500,
    };
  }
}
