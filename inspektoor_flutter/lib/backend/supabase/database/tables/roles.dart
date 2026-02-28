import '../database.dart';

class RolesTable extends SupabaseTable<RolesRow> {
  @override
  String get tableName => 'roles';

  @override
  RolesRow createRow(Map<String, dynamic> data) => RolesRow(data);
}

class RolesRow extends SupabaseDataRow {
  RolesRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => RolesTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get roleKey => getField<String>('role_key')!;
  set roleKey(String value) => setField<String>('role_key', value);

  String get label => getField<String>('label')!;
  set label(String value) => setField<String>('label', value);

  DateTime get createdAt => getField<DateTime>('created_at')!;
  set createdAt(DateTime value) => setField<DateTime>('created_at', value);
}
