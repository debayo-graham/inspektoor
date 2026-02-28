// Automatic FlutterFlow imports
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

Future<List<dynamic>> rpcSearchFormTemplates(
  String orgId,
  String scope,
  String searchText,
) async {
  try {
    final client = SupaFlow.client;
    final res = await client.rpc('search_inspection_templates', params: {
      'p_org': orgId,
      'p_scope': scope,
      'p_q': searchText,
    });

    print('RPC response type: ${res.runtimeType}, value: $res');

    if (res is List) {
      return res;
    } else if (res is Map) {
      return [res];
    } else {
      return [];
    }
  } catch (e, st) {
    print('RPC error: $e\n$st');
    return [];
  }
}
