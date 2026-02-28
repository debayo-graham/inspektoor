import '../database.dart';

class InspectionsTable extends SupabaseTable<InspectionsRow> {
  @override
  String get tableName => 'inspections';

  @override
  InspectionsRow createRow(Map<String, dynamic> data) => InspectionsRow(data);
}

class InspectionsRow extends SupabaseDataRow {
  InspectionsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => InspectionsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get orgId => getField<String>('org_id')!;
  set orgId(String value) => setField<String>('org_id', value);

  String get assetId => getField<String>('asset_id')!;
  set assetId(String value) => setField<String>('asset_id', value);

  String get templateId => getField<String>('template_id')!;
  set templateId(String value) => setField<String>('template_id', value);

  String get status => getField<String>('status')!;
  set status(String value) => setField<String>('status', value);

  DateTime? get startedAt => getField<DateTime>('started_at');
  set startedAt(DateTime? value) => setField<DateTime>('started_at', value);

  DateTime? get completedAt => getField<DateTime>('completed_at');
  set completedAt(DateTime? value) => setField<DateTime>('completed_at', value);

  dynamic? get gps => getField<dynamic>('gps');
  set gps(dynamic? value) => setField<dynamic>('gps', value);

  String? get signedBy => getField<String>('signed_by');
  set signedBy(String? value) => setField<String>('signed_by', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);

  String? get createdBy => getField<String>('created_by');
  set createdBy(String? value) => setField<String>('created_by', value);

  String? get updatedBy => getField<String>('updated_by');
  set updatedBy(String? value) => setField<String>('updated_by', value);

  String? get signatureUrl => getField<String>('signature_url');
  set signatureUrl(String? value) => setField<String>('signature_url', value);
}
