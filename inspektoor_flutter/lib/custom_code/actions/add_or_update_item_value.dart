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

Future<void> addOrUpdateItemValue(
  String templateItemKey,
  String type,
  String label,
  int order,
  List<dynamic> values,
) async {
  try {
    // decode JSON
    final draft = json.decode(FFAppState().inspectionDraftJson);

    // ensure items array exists
    draft['items'] ??= <dynamic>[];

    // find index
    final index = draft['items'].indexWhere(
      (i) => i['template_item_key'] == templateItemKey,
    );

    // build new item
    final newItem = {
      "template_item_key": templateItemKey,
      "type": type,
      "label": label,
      "order": order,
      "values": values,
    };

    if (index == -1) {
      draft['items'].add(newItem);
    } else {
      draft['items'][index] = newItem;
    }

    FFAppState().inspectionDraftJson = json.encode(draft);
  } catch (e, st) {
    debugPrint("ERROR in addOrUpdateItemValue: $e");
    debugPrint("$st");
    rethrow;
  }
}
