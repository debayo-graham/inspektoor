import '../database.dart';

class FilesTable extends SupabaseTable<FilesRow> {
  @override
  String get tableName => 'files';

  @override
  FilesRow createRow(Map<String, dynamic> data) => FilesRow(data);
}

class FilesRow extends SupabaseDataRow {
  FilesRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => FilesTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get orgId => getField<String>('org_id')!;
  set orgId(String value) => setField<String>('org_id', value);

  String? get assetId => getField<String>('asset_id');
  set assetId(String? value) => setField<String>('asset_id', value);

  String? get kind => getField<String>('kind');
  set kind(String? value) => setField<String>('kind', value);

  String get url => getField<String>('url')!;
  set url(String value) => setField<String>('url', value);

  String? get label => getField<String>('label');
  set label(String? value) => setField<String>('label', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);
}
