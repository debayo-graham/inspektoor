import '../database.dart';

class DefectsTable extends SupabaseTable<DefectsRow> {
  @override
  String get tableName => 'defects';

  @override
  DefectsRow createRow(Map<String, dynamic> data) => DefectsRow(data);
}

class DefectsRow extends SupabaseDataRow {
  DefectsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => DefectsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get orgId => getField<String>('org_id')!;
  set orgId(String value) => setField<String>('org_id', value);

  String get inspectionId => getField<String>('inspection_id')!;
  set inspectionId(String value) => setField<String>('inspection_id', value);

  String? get itemId => getField<String>('item_id');
  set itemId(String? value) => setField<String>('item_id', value);

  String get severity => getField<String>('severity')!;
  set severity(String value) => setField<String>('severity', value);

  String get description => getField<String>('description')!;
  set description(String value) => setField<String>('description', value);

  String get status => getField<String>('status')!;
  set status(String value) => setField<String>('status', value);

  String? get photoUrl => getField<String>('photo_url');
  set photoUrl(String? value) => setField<String>('photo_url', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get resolvedAt => getField<DateTime>('resolved_at');
  set resolvedAt(DateTime? value) => setField<DateTime>('resolved_at', value);
}
