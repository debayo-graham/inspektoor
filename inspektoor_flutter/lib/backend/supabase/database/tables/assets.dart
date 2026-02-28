import '../database.dart';

class AssetsTable extends SupabaseTable<AssetsRow> {
  @override
  String get tableName => 'assets';

  @override
  AssetsRow createRow(Map<String, dynamic> data) => AssetsRow(data);
}

class AssetsRow extends SupabaseDataRow {
  AssetsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => AssetsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get orgId => getField<String>('org_id')!;
  set orgId(String value) => setField<String>('org_id', value);

  String get name => getField<String>('name')!;
  set name(String value) => setField<String>('name', value);

  String get category => getField<String>('category')!;
  set category(String value) => setField<String>('category', value);

  String? get make => getField<String>('make');
  set make(String? value) => setField<String>('make', value);

  String? get model => getField<String>('model');
  set model(String? value) => setField<String>('model', value);

  String? get serialOrVin => getField<String>('serial_or_vin');
  set serialOrVin(String? value) => setField<String>('serial_or_vin', value);

  String? get status => getField<String>('status');
  set status(String? value) => setField<String>('status', value);

  String? get location => getField<String>('location');
  set location(String? value) => setField<String>('location', value);

  dynamic? get tags => getField<dynamic>('tags');
  set tags(dynamic? value) => setField<dynamic>('tags', value);

  String? get meterType => getField<String>('meter_type');
  set meterType(String? value) => setField<String>('meter_type', value);

  String? get meterUnit => getField<String>('meter_unit');
  set meterUnit(String? value) => setField<String>('meter_unit', value);

  double? get meterValue => getField<double>('meter_value');
  set meterValue(double? value) => setField<double>('meter_value', value);

  dynamic? get attributes => getField<dynamic>('attributes');
  set attributes(dynamic? value) => setField<dynamic>('attributes', value);

  DateTime? get lastInspectedAt => getField<DateTime>('last_inspected_at');
  set lastInspectedAt(DateTime? value) =>
      setField<DateTime>('last_inspected_at', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);

  String? get createdBy => getField<String>('created_by');
  set createdBy(String? value) => setField<String>('created_by', value);

  String? get updatedBy => getField<String>('updated_by');
  set updatedBy(String? value) => setField<String>('updated_by', value);

  String get statusId => getField<String>('status_id')!;
  set statusId(String value) => setField<String>('status_id', value);

  DateTime? get deletedAt => getField<DateTime>('deleted_at');
  set deletedAt(DateTime? value) => setField<DateTime>('deleted_at', value);

  String? get deletedBy => getField<String>('deleted_by');
  set deletedBy(String? value) => setField<String>('deleted_by', value);

  String? get deleteReason => getField<String>('delete_reason');
  set deleteReason(String? value) => setField<String>('delete_reason', value);

  String? get picUrl => getField<String>('picUrl');
  set picUrl(String? value) => setField<String>('picUrl', value);
}
