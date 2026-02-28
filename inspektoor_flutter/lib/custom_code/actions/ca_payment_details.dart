// Automatic FlutterFlow imports
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

Future<dynamic> caPaymentDetails(
  String sessionId,
  String orgId,
) async {
  final supa = SupaFlow.client;

  try {
    final resp = await supa.functions.invoke(
      'payment-details',
      body: {
        'sessionId': sessionId,
        'orgId': orgId,
      },
    );

    final data = resp.data as Map<String, dynamic>?;
    if (data == null) {
      print('payment-details: empty response');
      return {"ok": false, "error": "No response from payment-details"};
    }

    return data;
  } catch (e, st) {
    print('payment-details error: $e\n$st');
    return {"ok": false, "error": e.toString()};
  }
}
