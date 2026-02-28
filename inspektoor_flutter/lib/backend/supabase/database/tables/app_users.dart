import '../database.dart';

class AppUsersTable extends SupabaseTable<AppUsersRow> {
  @override
  String get tableName => 'app_users';

  @override
  AppUsersRow createRow(Map<String, dynamic> data) => AppUsersRow(data);
}

class AppUsersRow extends SupabaseDataRow {
  AppUsersRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => AppUsersTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String? get firstName => getField<String>('first_name');
  set firstName(String? value) => setField<String>('first_name', value);

  String? get middleName => getField<String>('middle_name');
  set middleName(String? value) => setField<String>('middle_name', value);

  String? get lastName => getField<String>('last_name');
  set lastName(String? value) => setField<String>('last_name', value);

  String? get displayName => getField<String>('display_name');
  set displayName(String? value) => setField<String>('display_name', value);

  String? get avatarUrl => getField<String>('avatar_url');
  set avatarUrl(String? value) => setField<String>('avatar_url', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);

  String? get email => getField<String>('email');
  set email(String? value) => setField<String>('email', value);

  String? get gender => getField<String>('gender');
  set gender(String? value) => setField<String>('gender', value);

  DateTime? get dob => getField<DateTime>('dob');
  set dob(DateTime? value) => setField<DateTime>('dob', value);
}
