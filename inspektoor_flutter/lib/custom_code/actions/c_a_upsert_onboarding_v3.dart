// Automatic FlutterFlow imports
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

// --- Helpers ---
String? _dateOnlyIso(DateTime? dt) {
  if (dt == null) return null;
  // upsert_onboarding_v2 expects DATE for dob. Send YYYY-MM-DD.
  return '${dt.year.toString().padLeft(4, "0")}-'
      '${dt.month.toString().padLeft(2, "0")}-'
      '${dt.day.toString().padLeft(2, "0")}';
}

/// Calls the Postgres RPC `upsert_onboarding_v2`.
/// Returns the `org_id` (uuid as string) on success, or throws on error.
///
/// All parameters are nullable; pass only what you have for the current step.
Future<String?> cAUpsertOnboardingV3(
  // Section 1: Profile
  String? firstName,
  String? middleName,
  String? lastName,
  String? gender,
  DateTime? dob, // DatePicker output

  // Org identifier (carry across steps)
  String? orgId,

  // Section 3: Organization
  String? orgName,
  String? street,
  String? city,
  String? stateProvince,
  String? postalCode,
  String? country,
  String? primaryContactFirstName,
  String? primaryContactLastName,
  String? primaryContactEmail,
  String? primaryContactPhone,

  // Stage marker: 'profile' | 'account' | 'org' | 'plan' | 'checkout'
  String? stage,
  String? billingEmail,

  // Section 4: Plan
  //String? planId,
) async {
  final supa = SupaFlow.client;

  final params = {
    // Profile
    'p_first_name': firstName,
    'p_middle_name': middleName,
    'p_last_name': lastName,
    'p_gender': gender,
    'p_dob': _dateOnlyIso(dob),

    // Org id
    'p_org_id': orgId,

    // Org fields
    'p_org_name': orgName,
    'p_street': street,
    'p_city': city,
    'p_state': stateProvince,
    'p_postal': postalCode,
    'p_country': country,
    'p_primary_contact_first_name': primaryContactFirstName,
    'p_primary_contact_last_name': primaryContactLastName,
    'p_primary_contact_email': primaryContactEmail,
    'p_primary_contact_phone': primaryContactPhone,

    // Plan + stage
    'p_stage': stage,
    'p_billing_email': billingEmail,
    //'p_plan_id': planId,
  };

  final res = await supa.rpc('upsert_onboarding_v3', params: params);

  //if (res.error != null) {
  //   throw res.error!;
  // }

  return res.toString();
  //return 'hi again';
}
