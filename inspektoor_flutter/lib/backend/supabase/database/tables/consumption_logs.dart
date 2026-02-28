import '../database.dart';

class ConsumptionLogsTable extends SupabaseTable<ConsumptionLogsRow> {
  @override
  String get tableName => 'consumption_logs';

  @override
  ConsumptionLogsRow createRow(Map<String, dynamic> data) =>
      ConsumptionLogsRow(data);
}

class ConsumptionLogsRow extends SupabaseDataRow {
  ConsumptionLogsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => ConsumptionLogsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get orgId => getField<String>('org_id')!;
  set orgId(String value) => setField<String>('org_id', value);

  String get assetId => getField<String>('asset_id')!;
  set assetId(String value) => setField<String>('asset_id', value);

  DateTime get date => getField<DateTime>('date')!;
  set date(DateTime value) => setField<DateTime>('date', value);

  String get type => getField<String>('type')!;
  set type(String value) => setField<String>('type', value);

  double get qty => getField<double>('qty')!;
  set qty(double value) => setField<double>('qty', value);

  String get unit => getField<String>('unit')!;
  set unit(String value) => setField<String>('unit', value);

  double? get cost => getField<double>('cost');
  set cost(double? value) => setField<double>('cost', value);

  double? get meterValue => getField<double>('meter_value');
  set meterValue(double? value) => setField<double>('meter_value', value);

  String? get receiptUrl => getField<String>('receipt_url');
  set receiptUrl(String? value) => setField<String>('receipt_url', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);
}
