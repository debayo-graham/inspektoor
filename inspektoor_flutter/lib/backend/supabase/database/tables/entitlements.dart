import '../database.dart';

class EntitlementsTable extends SupabaseTable<EntitlementsRow> {
  @override
  String get tableName => 'entitlements';

  @override
  EntitlementsRow createRow(Map<String, dynamic> data) => EntitlementsRow(data);
}

class EntitlementsRow extends SupabaseDataRow {
  EntitlementsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => EntitlementsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get orgId => getField<String>('org_id')!;
  set orgId(String value) => setField<String>('org_id', value);

  String? get planId => getField<String>('plan_id');
  set planId(String? value) => setField<String>('plan_id', value);

  String get source => getField<String>('source')!;
  set source(String value) => setField<String>('source', value);

  String get sourceRef => getField<String>('source_ref')!;
  set sourceRef(String value) => setField<String>('source_ref', value);

  int? get assetLimit => getField<int>('asset_limit');
  set assetLimit(int? value) => setField<int>('asset_limit', value);

  dynamic get features => getField<dynamic>('features')!;
  set features(dynamic value) => setField<dynamic>('features', value);

  String get status => getField<String>('status')!;
  set status(String value) => setField<String>('status', value);

  DateTime? get currentPeriodStart =>
      getField<DateTime>('current_period_start');
  set currentPeriodStart(DateTime? value) =>
      setField<DateTime>('current_period_start', value);

  DateTime? get currentPeriodEnd => getField<DateTime>('current_period_end');
  set currentPeriodEnd(DateTime? value) =>
      setField<DateTime>('current_period_end', value);

  DateTime get createdAt => getField<DateTime>('created_at')!;
  set createdAt(DateTime value) => setField<DateTime>('created_at', value);

  DateTime get updatedAt => getField<DateTime>('updated_at')!;
  set updatedAt(DateTime value) => setField<DateTime>('updated_at', value);
}
