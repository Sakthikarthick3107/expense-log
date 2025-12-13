import 'package:expense_log/models/ParsedSmsTxn.dart';
import 'package:expense_log/models/account.dart';
import 'package:flutter/material.dart';
import 'package:telephony/telephony.dart';

class SmsSyncService with ChangeNotifier {
  final Telephony _telephony = Telephony.instance;

  Future<List<ParsedSmsTxn>> sync(Account account) async {
    final hasPermission = await (_telephony.requestPhoneAndSmsPermissions) ?? false;
    if (!hasPermission) return [];

    // if lastSmsSyncedAt missing, use 5 days ago (not epoch 5)
    final sinceMillis = account.lastSmsSyncedAt?.millisecondsSinceEpoch ??
        DateTime.now().subtract(const Duration(days: 5)).millisecondsSinceEpoch;
    final since = sinceMillis.toString();

    final messages = await _telephony.getInboxSms(
      columns: [SmsColumn.BODY, SmsColumn.DATE],
      filter: SmsFilter.where(SmsColumn.DATE).greaterThan(since),
    );

    if (messages.isEmpty) return [];

    final keyword = (account.smsKeyword ?? '').toLowerCase();

    // improved amount regex: handles ₹, Rs, INR and plain amounts with commas and decimals
    final amountRegex = RegExp(r'(?:(?:₹|rs|inr)\s*[:\-]?\s*|amount\s*[:=]?\s*)([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{1,2})?|[0-9]+(?:\.[0-9]{1,2})?)',
        caseSensitive: false);

    // transaction words for debit/credit detection (explicit words preferred)
    bool looksLikeTxn(String body) {
      final b = body.toLowerCase();
      // reject common promotional indicators early
      if (b.contains('congrat') || b.contains('claim') || b.contains('offer') || b.contains('free') || b.contains('promo')) return false;

      // must contain an explicit amount
      final hasAmount = amountRegex.hasMatch(b);
      if (!hasAmount) return false;

      // require explicit transaction word (focus on clear debit/credit verbs)
      final txnWords = [
        'debited',
        'debited by',
        'debit',
        'credited',
        'credit',
        'paid',
        'payment',
        'txn',
        'transaction',
        'success',
        'failed',
        'withdrawn',
        'spent',
        'received',
        'deposit'
      ];
      final hasTxnWord = txnWords.any((w) => b.contains(w));
      if (!hasTxnWord) return false;

      if (keyword.isNotEmpty && !b.contains(keyword)) return false;
      return true;
    }

    final filtered = messages.where((sms) =>
        sms.body != null && looksLikeTxn(sms.body!));

    List<ParsedSmsTxn> parsed = [];
    for (final sms in filtered) {
      final body = sms.body!.toLowerCase();

      final match = amountRegex.firstMatch(body);
      if (match == null) continue;
      final amountRaw = match.group(1)!.replaceAll(',', '');
      double? amount = double.tryParse(amountRaw);
      if (amount == null) continue;

      // determine debit vs credit with preference to explicit 'credited'/'debited'
      bool isDebit;
      if (body.contains('credited') || body.contains('received') || body.contains('deposit') || body.contains('refund')) {
        isDebit = false;
      } else if (body.contains('debited') || body.contains('debit') || body.contains('spent') || body.contains('payment') || body.contains('withdrawn')) {
        isDebit = true;
      } else {
        // fallback: presence of 'to' or 'by' may hint direction, but default to debit
        isDebit = true;
      }

      parsed.add(ParsedSmsTxn(
        amount: amount,
        isDebit: isDebit,
        date: DateTime.fromMillisecondsSinceEpoch(sms.date ?? sinceMillis),
        description: sms.body ?? '',
        rawBody: sms.body ?? '',
      ));
    }

    return parsed;
  }
}