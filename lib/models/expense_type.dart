

import 'package:hive/hive.dart';
part 'expense_type.g.dart';

@HiveType(typeId: 1)
class ExpenseType{

  @HiveField(0)
  int id;

  @HiveField(1)
  String  name;

  @HiveField(2)
  String? description;

  @HiveField(3)
  double? limit;

  @HiveField(4)
  String? limitBy;

  @HiveField( 5)
  int? accountId;


  ExpenseType({
    required this.id,
    required this.name,
    this.description,
    this.limit,
    this.limitBy,
    this.accountId,
    });

  Map<String, dynamic> toJson() {
    return {
      'id' : id,
      'name': name,
      'description': description,
      'limit' : limit,
      'limitBy' : limitBy,
      'accountId': accountId,
    };
  }

  factory ExpenseType.fromJson(Map<String, dynamic> json) {
    return ExpenseType(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      limit: json['limit']?.toDouble(),
      limitBy: json['limitBy'],
      accountId: json['accountId'] as int?,
    );
  }
}