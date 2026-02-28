// Automatic FlutterFlow imports
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

Future<List<dynamic>> deleteCardItemByKey(
  List<dynamic> items,
  String keyToDelete,
) async {
  if (items == /* ignore: unnecessary_null_comparison */ null) return const [];
  if (keyToDelete.isEmpty) return items;

  // Copy list to avoid mutating original
  final list = List<dynamic>.from(items);

  // Remove the item where 'key' field matches
  list.removeWhere((e) {
    if (e is! Map) return false;
    return e['key']?.toString() == keyToDelete;
  });

  // Reassign order fields (1..N)
  for (var i = 0; i < list.length; i++) {
    final v = list[i];
    if (v is Map) {
      list[i] = {
        ...v,
        'order': i + 1,
      };
    }
  }

  return list;
}
