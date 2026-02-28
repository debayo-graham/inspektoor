import '../database.dart';

class AppErrorsTable extends SupabaseTable<AppErrorsRow> {
  @override
  String get tableName => 'app_errors';

  @override
  AppErrorsRow createRow(Map<String, dynamic> data) => AppErrorsRow(data);
}

class AppErrorsRow extends SupabaseDataRow {
  AppErrorsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => AppErrorsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String? get userId => getField<String>('user_id');
  set userId(String? value) => setField<String>('user_id', value);

  String? get orgId => getField<String>('org_id');
  set orgId(String? value) => setField<String>('org_id', value);

  String get env => getField<String>('env')!;
  set env(String value) => setField<String>('env', value);

  String? get platform => getField<String>('platform');
  set platform(String? value) => setField<String>('platform', value);

  String? get appVersion => getField<String>('app_version');
  set appVersion(String? value) => setField<String>('app_version', value);

  String? get screen => getField<String>('screen');
  set screen(String? value) => setField<String>('screen', value);

  String? get errorType => getField<String>('error_type');
  set errorType(String? value) => setField<String>('error_type', value);

  String get message => getField<String>('message')!;
  set message(String value) => setField<String>('message', value);

  String? get stack => getField<String>('stack');
  set stack(String? value) => setField<String>('stack', value);

  dynamic? get extra => getField<dynamic>('extra');
  set extra(dynamic? value) => setField<dynamic>('extra', value);

  DateTime get occurredAt => getField<DateTime>('occurred_at')!;
  set occurredAt(DateTime value) => setField<DateTime>('occurred_at', value);
}
