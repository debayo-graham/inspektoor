import '../database.dart';

class InspectionItemValuesTable extends SupabaseTable<InspectionItemValuesRow> {
  @override
  String get tableName => 'inspection_item_values';

  @override
  InspectionItemValuesRow createRow(Map<String, dynamic> data) =>
      InspectionItemValuesRow(data);
}

class InspectionItemValuesRow extends SupabaseDataRow {
  InspectionItemValuesRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => InspectionItemValuesTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get inspectionItemId => getField<String>('inspection_item_id')!;
  set inspectionItemId(String value) =>
      setField<String>('inspection_item_id', value);

  String get key => getField<String>('key')!;
  set key(String value) => setField<String>('key', value);

  String? get label => getField<String>('label');
  set label(String? value) => setField<String>('label', value);

  String? get value => getField<String>('value');
  set value(String? value) => setField<String>('value', value);

  String? get photoUrl => getField<String>('photo_url');
  set photoUrl(String? value) => setField<String>('photo_url', value);

  String? get comment => getField<String>('comment');
  set comment(String? value) => setField<String>('comment', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);
}
