import '../database.dart';

class InspectionTemplatesTable extends SupabaseTable<InspectionTemplatesRow> {
  @override
  String get tableName => 'inspection_templates';

  @override
  InspectionTemplatesRow createRow(Map<String, dynamic> data) =>
      InspectionTemplatesRow(data);
}

class InspectionTemplatesRow extends SupabaseDataRow {
  InspectionTemplatesRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => InspectionTemplatesTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String? get orgId => getField<String>('org_id');
  set orgId(String? value) => setField<String>('org_id', value);

  String get name => getField<String>('name')!;
  set name(String value) => setField<String>('name', value);

  String? get category => getField<String>('category');
  set category(String? value) => setField<String>('category', value);

  dynamic get schema => getField<dynamic>('schema')!;
  set schema(dynamic value) => setField<dynamic>('schema', value);

  int? get version => getField<int>('version');
  set version(int? value) => setField<int>('version', value);

  bool? get isActive => getField<bool>('is_active');
  set isActive(bool? value) => setField<bool>('is_active', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  bool get isPredefined => getField<bool>('is_predefined')!;
  set isPredefined(bool value) => setField<bool>('is_predefined', value);

  String get createdBy => getField<String>('created_by')!;
  set createdBy(String value) => setField<String>('created_by', value);
}
