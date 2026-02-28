import '../database.dart';

class OrgsTable extends SupabaseTable<OrgsRow> {
  @override
  String get tableName => 'orgs';

  @override
  OrgsRow createRow(Map<String, dynamic> data) => OrgsRow(data);
}

class OrgsRow extends SupabaseDataRow {
  OrgsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => OrgsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get name => getField<String>('name')!;
  set name(String value) => setField<String>('name', value);

  int? get assetLimit => getField<int>('asset_limit');
  set assetLimit(int? value) => setField<int>('asset_limit', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  String? get status => getField<String>('status');
  set status(String? value) => setField<String>('status', value);

  String? get onboardingStage => getField<String>('onboarding_stage');
  set onboardingStage(String? value) =>
      setField<String>('onboarding_stage', value);

  String? get streetAddress => getField<String>('street_address');
  set streetAddress(String? value) => setField<String>('street_address', value);

  String? get city => getField<String>('city');
  set city(String? value) => setField<String>('city', value);

  String? get stateProvince => getField<String>('state_province');
  set stateProvince(String? value) => setField<String>('state_province', value);

  String? get postalCode => getField<String>('postal_code');
  set postalCode(String? value) => setField<String>('postal_code', value);

  String? get country => getField<String>('country');
  set country(String? value) => setField<String>('country', value);

  String? get primaryContactEmail => getField<String>('primary_contact_email');
  set primaryContactEmail(String? value) =>
      setField<String>('primary_contact_email', value);

  String? get primaryContactPhone => getField<String>('primary_contact_phone');
  set primaryContactPhone(String? value) =>
      setField<String>('primary_contact_phone', value);

  String? get primaryContactFirstName =>
      getField<String>('primary_contact_first_name');
  set primaryContactFirstName(String? value) =>
      setField<String>('primary_contact_first_name', value);

  String? get primaryContactLastName =>
      getField<String>('primary_contact_last_name');
  set primaryContactLastName(String? value) =>
      setField<String>('primary_contact_last_name', value);

  String? get stripeCustomerId => getField<String>('stripe_customer_id');
  set stripeCustomerId(String? value) =>
      setField<String>('stripe_customer_id', value);

  String? get stripeSubscriptionId =>
      getField<String>('stripe_subscription_id');
  set stripeSubscriptionId(String? value) =>
      setField<String>('stripe_subscription_id', value);

  String? get billingEmail => getField<String>('billing_email');
  set billingEmail(String? value) => setField<String>('billing_email', value);

  String? get planId => getField<String>('plan_id');
  set planId(String? value) => setField<String>('plan_id', value);
}
