// Automatic FlutterFlow imports
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

Future<dynamic> caBootstrap() async {
  final supa = SupaFlow.client;

  try {
    //print('[caBootstrap] Calling bootstrap RPC...');
    final resp = await supa.rpc('bootstrap', params: {});
    //print('[caBootstrap] RPC response runtimeType: ${resp.runtimeType}');
    //print('[caBootstrap] RPC response (stringified): $resp');

    // Some environments return PostgrestResponse with .data, others return a raw Map.
    dynamic raw;
    try {
      // Try to access .data if it exists
      // This uses dynamic to avoid importing specific PostgrestResponse types.
      raw = (resp as dynamic).data;
      //print('[caBootstrap] Using resp.data path. raw type: ${raw.runtimeType}');
    } catch (_) {
      raw = resp;
      //print('[caBootstrap] Using raw resp path. raw type: ${raw.runtimeType}');
    }

    Map<String, dynamic> payload;
    if (raw is Map) {
      payload = Map<String, dynamic>.from(raw as Map);
    } else if (raw is String) {
      payload = jsonDecode(raw) as Map<String, dynamic>;
    } else if (raw is List && raw.isNotEmpty && raw.first is Map) {
      // Defensive: some RPCs can return a single-row list
      payload = Map<String, dynamic>.from(raw.first as Map);
    } else {
      //print('[caBootstrap] Unexpected RPC return type: ${raw.runtimeType}');
      return {
        'ok': false,
        'error': 'Unexpected RPC return type: ${raw.runtimeType}',
      };
    }

    //print('[caBootstrap] Parsed payload: $payload');

    final orgs = (payload['orgs'] as List?) ?? const [];
    final ents = (payload['entitlements'] as List?) ?? const [];

    //print('[caBootstrap] orgs: $orgs');
    //print('[caBootstrap] entitlements: $ents');

    if (orgs.isEmpty) {
      //print('[caBootstrap] No orgs found');
      return {
        'ok': false,
        'error':
            'No organization found for user. Please visit https://www.inspektoor.com to subscribe.',
      };
    }
    if (ents.isEmpty) {
      //print('[caBootstrap] No entitlements found');
      return {
        'ok': false,
        'error':
            'No entitlement found for user. Please visit https://www.inspektoor.com to subscribe.',
      };
    }

    // MVP: first org
    final currentOrg = Map<String, dynamic>.from(orgs.first as Map);
    final currentOrgId = currentOrg['id'] as String?;
    if (currentOrgId == null || currentOrgId.isEmpty) {
      //print('[caBootstrap] Current org missing id: $currentOrg');
      return {
        'ok': false,
        'error': 'Organization record missing id.',
      };
    }
    //print('[caBootstrap] Current orgId: $currentOrgId');

    // Find entitlement for that org
    Map<String, dynamic>? ent;
    try {
      ent = ents
          .map((e) => Map<String, dynamic>.from(e as Map))
          .firstWhere((e) => e['org_id'] == currentOrgId);
      //print('[caBootstrap] Found entitlement: $ent');
    } catch (_) {
      //print('[caBootstrap] No entitlement matched org $currentOrgId');
      ent = null;
    }

    final status = ent?['status'] as String? ?? 'none';
    final assetLimit = (ent?['asset_limit'] is int)
        ? ent!['asset_limit'] as int
        : int.tryParse('${ent?['asset_limit'] ?? 0}') ?? 0;
    final features = (ent?['features'] is Map)
        ? Map<String, dynamic>.from(ent!['features'] as Map)
        : <String, dynamic>{};

    final planId = ent?['plan_id'] as String?;
    final sourceRef = ent?['source_ref'] as String?; // stripe subscription id
    final periodEnd = ent?['period_end'] as String?; // ISO timestamp
    final periodStart = ent?['period_start'] as String?; // ISO timestamp

    /*print('[caBootstrap] Final values -> '
        'status: $status, assetLimit: $assetLimit, planId: $planId, '
        'sourceRef: $sourceRef, periodStart: $periodStart, periodEnd: $periodEnd, '
        'features: $features');*/

    return {
      'ok': true,
      'orgId': currentOrgId,
      'status': status,
      'assetLimit': assetLimit,
      'features': features,
      'planId': planId,
      'sourceRef': sourceRef,
      'periodStart': periodStart,
      'periodEnd': periodEnd,
    };
  } catch (e, st) {
    print('[caBootstrap] ERROR: $e');
    print('[caBootstrap] STACK: $st');
    return {'ok': false, 'error': e.toString()};
  }
}
