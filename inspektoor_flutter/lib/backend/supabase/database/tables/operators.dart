import '../database.dart';

class OperatorsTable extends SupabaseTable<OperatorsRow> {
  @override
  String get tableName => 'operators';

  @override
  OperatorsRow createRow(Map<String, dynamic> data) => OperatorsRow(data);
}

class OperatorsRow extends SupabaseDataRow {
  OperatorsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => OperatorsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get orgId => getField<String>('org_id')!;
  set orgId(String value) => setField<String>('org_id', value);

  String get name => getField<String>('name')!;
  set name(String value) => setField<String>('name', value);

  String? get licenseNo => getField<String>('license_no');
  set licenseNo(String? value) => setField<String>('license_no', value);

  String? get phone => getField<String>('phone');
  set phone(String? value) => setField<String>('phone', value);

  String? get photoUrl => getField<String>('photo_url');
  set photoUrl(String? value) => setField<String>('photo_url', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);
}
