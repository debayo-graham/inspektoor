import '../database.dart';

class AssetStatusesTable extends SupabaseTable<AssetStatusesRow> {
  @override
  String get tableName => 'asset_statuses';

  @override
  AssetStatusesRow createRow(Map<String, dynamic> data) =>
      AssetStatusesRow(data);
}

class AssetStatusesRow extends SupabaseDataRow {
  AssetStatusesRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => AssetStatusesTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get code => getField<String>('code')!;
  set code(String value) => setField<String>('code', value);

  String get label => getField<String>('label')!;
  set label(String value) => setField<String>('label', value);

  String? get color => getField<String>('color');
  set color(String? value) => setField<String>('color', value);

  int get sortOrder => getField<int>('sort_order')!;
  set sortOrder(int value) => setField<int>('sort_order', value);

  bool get isDefault => getField<bool>('is_default')!;
  set isDefault(bool value) => setField<bool>('is_default', value);

  bool get isTerminal => getField<bool>('is_terminal')!;
  set isTerminal(bool value) => setField<bool>('is_terminal', value);

  DateTime get createdAt => getField<DateTime>('created_at')!;
  set createdAt(DateTime value) => setField<DateTime>('created_at', value);

  DateTime get updatedAt => getField<DateTime>('updated_at')!;
  set updatedAt(DateTime value) => setField<DateTime>('updated_at', value);
}
