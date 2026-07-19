import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class VoiceParseResult {
  final String? amount;
  final String? typeName;
  final bool? isCredit;
  final String? accountName;
  final String? groupName;
  final String? groupUserName;
  final String fullText;

  VoiceParseResult({
    this.amount,
    this.typeName,
    this.isCredit,
    this.accountName,
    this.groupName,
    this.groupUserName,
    required this.fullText,
  });
}

VoiceParseResult parseVoiceInput(
  String text,
  List<String> expenseTypeNames, {
  List<String> accountNames = const [],
  List<String> groupNames = const [],
  List<String> groupMemberNames = const [],
}) {
  final cleaned = text.trim();
  if (cleaned.isEmpty) return VoiceParseResult(fullText: text);

  final amountRegex = RegExp(r'(\d+(?:[.,]\d+)?)');
  final amountMatch = amountRegex.firstMatch(cleaned);
  final amount = amountMatch?.group(1)?.replaceAll(',', '.');

  final lower = cleaned.toLowerCase();
  bool? isCredit;
  if (RegExp(r'\b(received|got|credited|salary|cashback|refund)\b').hasMatch(lower)) {
    isCredit = true;
  } else if (RegExp(r'\b(spent|paid|bought|purchased|expense|buy|pay|spend|cost)\b').hasMatch(lower)) {
    isCredit = false;
  }

  String? matchedType;
  final withoutAmount = amount != null
      ? cleaned.replaceFirst(amountRegex, '').trim()
      : cleaned;
  for (final type in expenseTypeNames) {
    if (withoutAmount.toLowerCase().contains(type.toLowerCase())) {
      matchedType = type;
      break;
    }
  }
  if (matchedType == null) {
    for (final type in expenseTypeNames) {
      for (final word in withoutAmount.toLowerCase().split(RegExp(r'\s+'))) {
        if (word.length >= 3 && type.toLowerCase().contains(word)) {
          matchedType = type;
          break;
        }
      }
      if (matchedType != null) break;
    }
  }

  String? matchedAccount;
  for (final acc in accountNames) {
    if (lower.contains(acc.toLowerCase())) {
      matchedAccount = acc;
      break;
    }
  }

  String? matchedGroup;
  for (final g in groupNames) {
    if (lower.contains(g.toLowerCase())) {
      matchedGroup = g;
      break;
    }
  }

  String? matchedGroupUser;
  for (final m in groupMemberNames) {
    if (lower.contains(m.toLowerCase())) {
      matchedGroupUser = m;
      break;
    }
  }

  return VoiceParseResult(
    amount: amount,
    typeName: matchedType,
    isCredit: isCredit,
    accountName: matchedAccount,
    groupName: matchedGroup,
    groupUserName: matchedGroupUser,
    fullText: cleaned,
  );
}

class VoiceInputButton extends StatefulWidget {
  final void Function(VoiceParseResult result) onResult;
  final List<String> expenseTypeNames;
  final List<String> accountNames;
  final List<String> groupNames;
  final List<String> groupMemberNames;

  const VoiceInputButton({
    super.key,
    required this.onResult,
    required this.expenseTypeNames,
    this.accountNames = const [],
    this.groupNames = const [],
    this.groupMemberNames = const [],
  });

  @override
  State<VoiceInputButton> createState() => _VoiceInputButtonState();
}

class _VoiceInputButtonState extends State<VoiceInputButton> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;

  Future<void> _listen() async {
    if (_isListening) {
      _speech.stop();
      if (mounted) setState(() => _isListening = false);
      return;
    }

    final available = await _speech.initialize();
    if (!available) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Speech recognition not available on this device')),
        );
      }
      return;
    }

    setState(() => _isListening = true);
    _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          final parsed = parseVoiceInput(
            result.recognizedWords,
            widget.expenseTypeNames,
            accountNames: widget.accountNames,
            groupNames: widget.groupNames,
            groupMemberNames: widget.groupMemberNames,
          );
          widget.onResult(parsed);
          if (mounted) setState(() => _isListening = false);
        }
      },
      listenOptions: stt.SpeechListenOptions(localeId: 'en_US'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        _isListening ? Icons.mic : Icons.mic_none,
        size: 20,
        color: _isListening ? Colors.red : Colors.grey[600],
      ),
      onPressed: _listen,
      tooltip: _isListening ? 'Listening...' : 'Voice input',
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      padding: const EdgeInsets.all(6),
    );
  }
}
