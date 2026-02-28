import '../database.dart';

class PaymentsTable extends SupabaseTable<PaymentsRow> {
  @override
  String get tableName => 'payments';

  @override
  PaymentsRow createRow(Map<String, dynamic> data) => PaymentsRow(data);
}

class PaymentsRow extends SupabaseDataRow {
  PaymentsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => PaymentsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get orgId => getField<String>('org_id')!;
  set orgId(String value) => setField<String>('org_id', value);

  String? get stripeCustomerId => getField<String>('stripe_customer_id');
  set stripeCustomerId(String? value) =>
      setField<String>('stripe_customer_id', value);

  String? get stripeSessionId => getField<String>('stripe_session_id');
  set stripeSessionId(String? value) =>
      setField<String>('stripe_session_id', value);

  String? get stripePaymentIntentId =>
      getField<String>('stripe_payment_intent_id');
  set stripePaymentIntentId(String? value) =>
      setField<String>('stripe_payment_intent_id', value);

  String? get stripeInvoiceId => getField<String>('stripe_invoice_id');
  set stripeInvoiceId(String? value) =>
      setField<String>('stripe_invoice_id', value);

  int get amountPaidCents => getField<int>('amount_paid_cents')!;
  set amountPaidCents(int value) => setField<int>('amount_paid_cents', value);

  String get currency => getField<String>('currency')!;
  set currency(String value) => setField<String>('currency', value);

  String? get cardLast4 => getField<String>('card_last4');
  set cardLast4(String? value) => setField<String>('card_last4', value);

  String? get paymentMethodBrand => getField<String>('payment_method_brand');
  set paymentMethodBrand(String? value) =>
      setField<String>('payment_method_brand', value);

  String? get receiptUrl => getField<String>('receipt_url');
  set receiptUrl(String? value) => setField<String>('receipt_url', value);

  String get status => getField<String>('status')!;
  set status(String value) => setField<String>('status', value);

  DateTime get paidAt => getField<DateTime>('paid_at')!;
  set paidAt(DateTime value) => setField<DateTime>('paid_at', value);

  DateTime get createdAt => getField<DateTime>('created_at')!;
  set createdAt(DateTime value) => setField<DateTime>('created_at', value);

  String? get paymentMethodType => getField<String>('payment_method_type');
  set paymentMethodType(String? value) =>
      setField<String>('payment_method_type', value);
}
