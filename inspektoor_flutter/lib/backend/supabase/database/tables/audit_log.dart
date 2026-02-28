import '../database.dart';

class AuditLogTable extends SupabaseTable<AuditLogRow> {
  @override
  String get tableName => 'audit_log';

  @override
  AuditLogRow createRow(Map<String, dynamic> data) => AuditLogRow(data);
}

class AuditLogRow extends SupabaseDataRow {
  AuditLogRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => AuditLogTable();

  int get id => getField<int>('id')!;
  set id(int value) => setField<int>('id', value);

  String? get orgId => getField<String>('org_id');
  set orgId(String? value) => setField<String>('org_id', value);

  String? get actorId => getField<String>('actor_id');
  set actorId(String? value) => setField<String>('actor_id', value);

  String get action => getField<String>('action')!;
  set action(String value) => setField<String>('action', value);

  String get entity => getField<String>('entity')!;
  set entity(String value) => setField<String>('entity', value);

  String get entityId => getField<String>('entity_id')!;
  set entityId(String value) => setField<String>('entity_id', value);

  dynamic? get changes => getField<dynamic>('changes');
  set changes(dynamic? value) => setField<dynamic>('changes', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);
}
