import '../database.dart';

class InspectionItemsTable extends SupabaseTable<InspectionItemsRow> {
  @override
  String get tableName => 'inspection_items';

  @override
  InspectionItemsRow createRow(Map<String, dynamic> data) =>
      InspectionItemsRow(data);
}

class InspectionItemsRow extends SupabaseDataRow {
  InspectionItemsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => InspectionItemsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get inspectionId => getField<String>('inspection_id')!;
  set inspectionId(String value) => setField<String>('inspection_id', value);

  String get templateItemKey => getField<String>('template_item_key')!;
  set templateItemKey(String value) =>
      setField<String>('template_item_key', value);

  String get type => getField<String>('type')!;
  set type(String value) => setField<String>('type', value);

  String get label => getField<String>('label')!;
  set label(String value) => setField<String>('label', value);

  int get order => getField<int>('order')!;
  set order(int value) => setField<int>('order', value);

  dynamic? get config => getField<dynamic>('config');
  set config(dynamic? value) => setField<dynamic>('config', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);

  String? get createdBy => getField<String>('created_by');
  set createdBy(String? value) => setField<String>('created_by', value);

  String? get updatedBy => getField<String>('updated_by');
  set updatedBy(String? value) => setField<String>('updated_by', value);
}
