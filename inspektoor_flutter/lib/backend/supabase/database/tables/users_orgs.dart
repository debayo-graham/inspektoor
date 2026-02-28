import '../database.dart';

class UsersOrgsTable extends SupabaseTable<UsersOrgsRow> {
  @override
  String get tableName => 'users_orgs';

  @override
  UsersOrgsRow createRow(Map<String, dynamic> data) => UsersOrgsRow(data);
}

class UsersOrgsRow extends SupabaseDataRow {
  UsersOrgsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => UsersOrgsTable();

  String get userId => getField<String>('user_id')!;
  set userId(String value) => setField<String>('user_id', value);

  String get orgId => getField<String>('org_id')!;
  set orgId(String value) => setField<String>('org_id', value);

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get roleId => getField<String>('role_id')!;
  set roleId(String value) => setField<String>('role_id', value);
}
