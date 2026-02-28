import '../database.dart';

class UserOrgsExpandedTable extends SupabaseTable<UserOrgsExpandedRow> {
  @override
  String get tableName => 'user_orgs_expanded';

  @override
  UserOrgsExpandedRow createRow(Map<String, dynamic> data) =>
      UserOrgsExpandedRow(data);
}

class UserOrgsExpandedRow extends SupabaseDataRow {
  UserOrgsExpandedRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => UserOrgsExpandedTable();

  String? get userId => getField<String>('user_id');
  set userId(String? value) => setField<String>('user_id', value);

  String? get orgId => getField<String>('org_id');
  set orgId(String? value) => setField<String>('org_id', value);

  String? get id => getField<String>('id');
  set id(String? value) => setField<String>('id', value);

  String? get roleId => getField<String>('role_id');
  set roleId(String? value) => setField<String>('role_id', value);

  String? get roleKey => getField<String>('role_key');
  set roleKey(String? value) => setField<String>('role_key', value);

  String? get roleLabel => getField<String>('role_label');
  set roleLabel(String? value) => setField<String>('role_label', value);
}
