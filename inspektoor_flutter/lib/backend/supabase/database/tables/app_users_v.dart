import '../database.dart';

class AppUsersVTable extends SupabaseTable<AppUsersVRow> {
  @override
  String get tableName => 'app_users_v';

  @override
  AppUsersVRow createRow(Map<String, dynamic> data) => AppUsersVRow(data);
}

class AppUsersVRow extends SupabaseDataRow {
  AppUsersVRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => AppUsersVTable();

  String? get id => getField<String>('id');
  set id(String? value) => setField<String>('id', value);

  String? get email => getField<String>('email');
  set email(String? value) => setField<String>('email', value);

  String? get firstName => getField<String>('first_name');
  set firstName(String? value) => setField<String>('first_name', value);

  String? get middleName => getField<String>('middle_name');
  set middleName(String? value) => setField<String>('middle_name', value);

  String? get lastName => getField<String>('last_name');
  set lastName(String? value) => setField<String>('last_name', value);

  String? get fullName => getField<String>('full_name');
  set fullName(String? value) => setField<String>('full_name', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);
}
