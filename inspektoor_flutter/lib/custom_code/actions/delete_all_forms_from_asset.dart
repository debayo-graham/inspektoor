// Automatic FlutterFlow imports
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

Future<dynamic> deleteAllFormsFromAsset(
    String assetId, List<String>? formIdsToDelete) async {
  final supabase = Supabase.instance.client;

  try {
    // --------------------------------------------------
    // 1. DETERMINE MODE: Delete all OR delete selected?
    // --------------------------------------------------
    final deleteAll = formIdsToDelete == null || formIdsToDelete.isEmpty;

    List<dynamic> deletedRows = [];

    if (deleteAll) {
      // ----------------------------------------------
      // DELETE ALL FORMS FOR THIS ASSET
      // ----------------------------------------------
      final deleteResult = await supabase
          .from('asset_inspection_templates')
          .delete()
          .eq('asset_id', assetId)
          .select();

      deletedRows = deleteResult as List;
    } else {
      // ----------------------------------------------
      // DELETE ONLY SPECIFIC FORM IDS
      // ----------------------------------------------
      final deleteResult = await supabase
          .from('asset_inspection_templates')
          .delete()
          .eq('asset_id', assetId)
          .inFilter('inspection_template_id', formIdsToDelete)
          .select();

      deletedRows = deleteResult as List;
    }

    return {
      'success': true,
      'data': deletedRows,
      'deletedCount': deletedRows.length,
      'deletedAll': deleteAll,
      'error': null,
      'status': 200,
    };
  }

  // --------------------------------------------------
  // DATABASE ERROR
  // --------------------------------------------------
  on PostgrestException catch (e) {
    print(
        'DATABASE ERROR (deleteFormsFromAsset): ${e.message} (Code: ${e.code})');
    final raw = e.code;
    final status = raw != null ? int.tryParse(raw) ?? 500 : 500;

    return {
      'success': false,
      'data': null,
      'deletedCount': 0,
      'deletedAll': false,
      'error': e.message,
      'status': status,
    };
  }

  // --------------------------------------------------
  // UNEXPECTED ERROR
  // --------------------------------------------------
  catch (e) {
    print('UNEXPECTED ERROR (deleteFormsFromAsset): $e');

    return {
      'success': false,
      'data': null,
      'deletedCount': 0,
      'deletedAll': false,
      'error': e.toString(),
      'status': 500,
    };
  }
}
