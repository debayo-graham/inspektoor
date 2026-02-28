// Automatic FlutterFlow imports
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

/// Deletes inspection forms attached to assets.
///
/// if form Id is null or empty it will delete all the inspection forms attach
/// to that asset
Future<dynamic> deleteAssetForms(
  String assetId,
  String? formId, // NULL or empty = delete all
) async {
  final supabase = Supabase.instance.client;

  try {
    dynamic result;

    // --------------------------------------------------
    // 1. DELETE ALL FORM RELATIONS FOR ASSET
    // --------------------------------------------------
    if (formId == null || formId.trim().isEmpty) {
      result = await supabase
          .from('asset_inspection_templates')
          .delete()
          .eq('asset_id', assetId)
          .select();

      return {
        'success': true,
        'data': result,
        'error': null,
        'status': 200,
      };
    }

    // --------------------------------------------------
    // 2. DELETE ONE SPECIFIC FORM RELATION
    // --------------------------------------------------
    result = await supabase
        .from('asset_inspection_templates')
        .delete()
        .eq('asset_id', assetId)
        .eq('inspection_template_id', formId)
        .select()
        .maybeSingle();

    return {
      'success': true,
      'data': result,
      'error': null,
      'status': 200,
    };
  }

  // --------------------------------------------------
  // DATABASE ERROR HANDLER
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
  // UNEXPECTED ERROR HANDLER
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
