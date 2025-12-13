import 'package:expense_log/models/ParsedSmsTxn.dart';
import 'package:expense_log/models/account.dart';
import 'package:flutter/material.dart';
import 'package:telephony/telephony.dart';

class SmsSyncService with ChangeNotifier {
  final Telephony _telephony = Telephony.instance;

  Future<List<ParsedSmsTxn>> sync(Account account) async {
    final hasPermission =
        await _telephony.requestPhoneAndSmsPermissions ?? false;

    if (!hasPermission) return [];

    final since = (account.lastSmsSyncedAt?.millisecondsSinceEpoch ?? 5).toString();


    final messages = await _telephony.getInboxSms(
      columns: [SmsColumn.BODY, SmsColumn.DATE],
      filter: SmsFilter.where(SmsColumn.DATE).greaterThan(since),
    );

    final filtered = messages.where((sms) =>
        sms.body != null &&
        sms.body!.toLowerCase().contains(account.smsKeyword!.toLowerCase()) &&
        _containsTxnWords(sms.body!));

    return filtered
        .map((sms) => _parseSms(sms))
        .whereType<ParsedSmsTxn>()
        .toList();
  }

  bool _containsTxnWords(String body) {
    final b = body.toLowerCase();
    return b.contains('debit') ||
        b.contains('credit') ||
        b.contains('upi') ||
        b.contains('imps') ||
        b.contains('neft');
  }

  ParsedSmsTxn? _parseSms(SmsMessage sms) {
  final body = sms.body!.toLowerCase();

  final amountRegex =
      RegExp(r'(rs\.?|inr)\s?([0-9,]+\.?[0-9]*)');
  final match = amountRegex.firstMatch(body);
  if (match == null) return null;

  final amount =
      double.parse(match.group(2)!.replaceAll(',', ''));

  final isDebit =
      body.contains('debit') || body.contains('spent');

  return ParsedSmsTxn(
    amount: amount,
    isDebit: isDebit,
    date: DateTime.fromMillisecondsSinceEpoch(sms.date!),
    description: body,
    rawBody: sms.body!,
  );
}

}