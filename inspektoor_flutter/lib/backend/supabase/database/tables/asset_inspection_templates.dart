import '../database.dart';

class AssetInspectionTemplatesTable
    extends SupabaseTable<AssetInspectionTemplatesRow> {
  @override
  String get tableName => 'asset_inspection_templates';

  @override
  AssetInspectionTemplatesRow createRow(Map<String, dynamic> data) =>
      AssetInspectionTemplatesRow(data);
}

class AssetInspectionTemplatesRow extends SupabaseDataRow {
  AssetInspectionTemplatesRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => AssetInspectionTemplatesTable();

  String get assetId => getField<String>('asset_id')!;
  set assetId(String value) => setField<String>('asset_id', value);

  String get inspectionTemplateId =>
      getField<String>('inspection_template_id')!;
  set inspectionTemplateId(String value) =>
      setField<String>('inspection_template_id', value);

  DateTime get createdAt => getField<DateTime>('created_at')!;
  set createdAt(DateTime value) => setField<DateTime>('created_at', value);

  String? get createdBy => getField<String>('created_by');
  set createdBy(String? value) => setField<String>('created_by', value);
}
