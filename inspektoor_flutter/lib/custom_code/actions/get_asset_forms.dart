// Automatic FlutterFlow imports
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

/// Get all inspection forsms attached to an asset
Future<dynamic> getAssetForms(String assetId) async {
  final supabase = Supabase.instance.client;

  try {
    // --------------------------------------------------
    // 1. RELATION LOOKUP: Get template IDs for asset
    // --------------------------------------------------
    final relRows = await supabase
        .from('asset_inspection_templates')
        .select('inspection_template_id')
        .eq('asset_id', assetId);

    final relList = relRows as List;

    final templateIds = relList
        .map<String>((row) => row['inspection_template_id'] as String)
        .toList();

    if (templateIds.isEmpty) {
      return {
        'success': true,
        'data': {
          "forms": <dynamic>[],
          "ids": <String>[],
        },
        'error': null,
        'status': 200,
      };
    }

    // --------------------------------------------------
    // 2. FETCH TEMPLATE RECORDS
    // --------------------------------------------------
    final templatesRaw = await supabase
        .from('inspection_templates')
        .select()
        .inFilter('id', templateIds);

    final templates = templatesRaw as List;

    // --------------------------------------------------
    // 3. COLLECT all created_by IDs
    // --------------------------------------------------
    final creatorIds = templates
        .map((t) => t['created_by'])
        .whereType<String>()
        .toSet()
        .toList();

    Map<String, Map<String, dynamic>> creatorsById = {};

    if (creatorIds.isNotEmpty) {
      // ------------------------------------------------
      // 4. FETCH USERS (first_name, last_name)
      // ------------------------------------------------
      final creatorsRaw = await supabase
          .from('app_users') // FIXED TABLE NAME
          .select('id, first_name, last_name')
          .inFilter('id', creatorIds);

      final creators = creatorsRaw as List;

      for (final row in creators) {
        final id = row['id'] as String;
        creatorsById[id] = {
          'creator_first_name': row['first_name'],
          'creator_last_name': row['last_name'],
        };
      }
    }

    // --------------------------------------------------
    // 5. MERGE CREATOR DETAILS INTO EACH TEMPLATE
    // --------------------------------------------------
    final enrichedTemplates = templates.map((tpl) {
      final creatorId = tpl['created_by'] as String?;

      final extra = (creatorId != null && creatorsById.containsKey(creatorId))
          ? creatorsById[creatorId]!
          : {
              'creator_first_name': null,
              'creator_last_name': null,
            };

      return {
        ...tpl as Map<String, dynamic>,
        ...extra,
      };
    }).toList();

    // --------------------------------------------------
    // 6. ALSO BUILD ids ARRAY
    // --------------------------------------------------
    final ids =
        enrichedTemplates.map<String>((tpl) => tpl['id'] as String).toList();

    // --------------------------------------------------
    // SORT by name (case-insensitive, null-safe)
    // --------------------------------------------------
    enrichedTemplates.sort((a, b) {
      final nameA = (a['name'] ?? '').toString().toLowerCase();
      final nameB = (b['name'] ?? '').toString().toLowerCase();
      return nameA.compareTo(nameB);
    });

    // --------------------------------------------------
    // 7. RETURN WRAPPED DATA (FlutterFlow-friendly)
    // --------------------------------------------------
    return {
      'success': true,
      'data': {
        "forms": enrichedTemplates,
        "ids": ids,
      },
      'error': null,
      'status': 200,
    };
  }

  // --------------------------------------------------
  // DATABASE ERROR
  // --------------------------------------------------
  on PostgrestException catch (e) {
    print('DATABASE ERROR (getAssetForms): ${e.message} (Code: ${e.code})');
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
  // UNEXPECTED ERROR
  // --------------------------------------------------
  catch (e) {
    print('UNEXPECTED ERROR (getAssetForms): $e');

    return {
      'success': false,
      'data': null,
      'error': e.toString(),
      'status': 500,
    };
  }
}
