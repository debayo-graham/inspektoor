import '../database.dart';

class EmailOtpCodesTable extends SupabaseTable<EmailOtpCodesRow> {
  @override
  String get tableName => 'email_otp_codes';

  @override
  EmailOtpCodesRow createRow(Map<String, dynamic> data) =>
      EmailOtpCodesRow(data);
}

class EmailOtpCodesRow extends SupabaseDataRow {
  EmailOtpCodesRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => EmailOtpCodesTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get userId => getField<String>('user_id')!;
  set userId(String value) => setField<String>('user_id', value);

  String get challengeId => getField<String>('challenge_id')!;
  set challengeId(String value) => setField<String>('challenge_id', value);

  String get codeHash => getField<String>('code_hash')!;
  set codeHash(String value) => setField<String>('code_hash', value);

  DateTime get expiresAt => getField<DateTime>('expires_at')!;
  set expiresAt(DateTime value) => setField<DateTime>('expires_at', value);

  DateTime? get consumedAt => getField<DateTime>('consumed_at');
  set consumedAt(DateTime? value) => setField<DateTime>('consumed_at', value);

  DateTime get createdAt => getField<DateTime>('created_at')!;
  set createdAt(DateTime value) => setField<DateTime>('created_at', value);
}
