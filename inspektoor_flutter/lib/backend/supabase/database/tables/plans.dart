import '../database.dart';

class PlansTable extends SupabaseTable<PlansRow> {
  @override
  String get tableName => 'plans';

  @override
  PlansRow createRow(Map<String, dynamic> data) => PlansRow(data);
}

class PlansRow extends SupabaseDataRow {
  PlansRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => PlansTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get code => getField<String>('code')!;
  set code(String value) => setField<String>('code', value);

  String get name => getField<String>('name')!;
  set name(String value) => setField<String>('name', value);

  String get stripePriceId => getField<String>('stripe_price_id')!;
  set stripePriceId(String value) => setField<String>('stripe_price_id', value);

  String get interval => getField<String>('interval')!;
  set interval(String value) => setField<String>('interval', value);

  String get currency => getField<String>('currency')!;
  set currency(String value) => setField<String>('currency', value);

  double get unitPrice => getField<double>('unit_price')!;
  set unitPrice(double value) => setField<double>('unit_price', value);

  bool get isPerAsset => getField<bool>('is_per_asset')!;
  set isPerAsset(bool value) => setField<bool>('is_per_asset', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);

  int? get assetLimit => getField<int>('asset_limit');
  set assetLimit(int? value) => setField<int>('asset_limit', value);
}
