// Automatic FlutterFlow imports
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

Future<List<dynamic>> moveCardItem(
  List<dynamic> items,
  int from,
  int to,
) async {
  if (items == null) return const [];
  if (from < 0 || from >= items.length || to < 0 || to >= items.length) {
    return items;
  }

  // Clone to avoid mutating the original
  final list = List<dynamic>.from(items);

  final it = list.removeAt(from);
  list.insert(to, it);

  // Normalize order to 1..N when element is a Map-like JSON
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
