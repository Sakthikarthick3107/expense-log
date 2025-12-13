class ParsedSmsTxn {
  final double amount;
  final bool isDebit;
  final DateTime date;
  final String description;
  final String rawBody;

  ParsedSmsTxn({
    required this.amount,
    required this.isDebit,
    required this.date,
    required this.description,
    required this.rawBody,
  });

  ParsedSmsTxn copyWith({
    double? amount,
    bool? isDebit,
    DateTime? date,
    String? description,
    String? rawBody,
  }) {
    return ParsedSmsTxn(
      amount: amount ?? this.amount,
      isDebit: isDebit ?? this.isDebit,
      date: date ?? this.date,
      description: description ?? this.description,
      rawBody: rawBody ?? this.rawBody,
    );
  }
}
