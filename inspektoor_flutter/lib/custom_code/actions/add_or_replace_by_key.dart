// Automatic FlutterFlow imports
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

Future<List<dynamic>> addOrReplaceByKey(
    List<dynamic> items, dynamic item) async {
  print('>>> addOrReplaceByKey called');
  print('Current items: $items');
  print('Incoming item: $item');

  final list = List<dynamic>.from(items);
  final m = jsonDecode(jsonEncode(item)); // deep copy

  dynamic key;
  if (m is Map && m.containsKey('key')) {
    key = m['key'];
  } else {
    key = null;
  }

  print('Item key: $key');

  if (key != null) {
    int idx = -1;
    for (int i = 0; i < list.length; i++) {
      final e = list[i];
      if (e is Map && e.containsKey('key') && e['key'] == key) {
        idx = i;
        break;
      }
    }
    print('Index found: $idx');

    if (idx >= 0) {
      dynamic keepOrder;
      final current = list[idx];
      if (current is Map && current.containsKey('order')) {
        keepOrder = current['order'];
      }
      if (keepOrder != null) {
        m['order'] = keepOrder;
      }
      list[idx] = m;
      print('Item replaced at index $idx. New list: $list');
      return await recalcOrder(list);
    }
  }

  // create: append to end and set order 1-based
  m['order'] = list.length + 1;
  list.add(m);
  print('Item appended. New list: $list');
  return await recalcOrder(list);
}

Future<List<dynamic>> recalcOrder(List<dynamic> items) async {
  print('>>> recalcOrder called');
  final list = List<dynamic>.from(items);
  for (int i = 0; i < list.length; i++) {
    final e = list[i];
    if (e is Map) {
      e['order'] = i + 1;
    }
  }
  print('Recalculated list: $list');
  return list;
}
