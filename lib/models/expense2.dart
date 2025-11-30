import 'package:hive/hive.dart';

import 'expense_type.dart';
part 'expense2.g.dart';

@HiveType(typeId: 2)
class Expense2{
  @HiveField(0)
  int id;

  @HiveField(1)
  String name;

  @HiveField(2)
  double price;

  @HiveField(3)
  ExpenseType expenseType;

  @HiveField(4)
  DateTime date;

  @HiveField(5)
  DateTime created;

  @HiveField(6)
  DateTime? updated;

  @HiveField(7)
  int? accountId;

  @HiveField(8)
  String? description;


  Expense2({
    required this.id,
    required this.name,
    required this.price,
    required this.expenseType,
    required this.date,
    required this.created,
    this.updated,
    this.accountId,
    this.description
  });

  Expense2 copyWith({
    int? id,
    String? name,
    double? price,
    DateTime? date,
    ExpenseType? expenseType,
    DateTime? created,
    DateTime? updated,
    int? accountId,
    String? description
  }) {
    return Expense2(
        id: id ?? this.id,
        name: name ?? this.name,
        price: price ?? this.price,
        expenseType: expenseType ?? this.expenseType,
        date: date ?? this.date,
        created: created ?? this.created,
        updated: updated ?? this.updated,
        accountId: accountId ?? this.accountId,
        description: description ?? this.description
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name':name,
      'price': price,
      'expenseType': expenseType.toJson(),
      'date': date.toIso8601String() ,
      'created': created.toIso8601String(),
      'updated': updated?.toIso8601String(),
      'accountId': accountId,
      'description' : description
    };
  }

  factory Expense2.fromJson(Map<String, dynamic> json) {
    return Expense2(
      id: json['id'],
      name: json['name'],
      price: (json['price'] as num).toDouble(),
      expenseType: ExpenseType.fromJson(json['expenseType']),
      date: DateTime.parse(json['date']),
      created: DateTime.parse(json['created']),
      updated: json['updated'] != null ? DateTime.parse(json['updated']) : null,
      accountId: json['accountId'] as int?,
      description: json['description'] as String?
    );
  }
}