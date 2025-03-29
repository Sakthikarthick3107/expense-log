

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

  ExpenseType({
    required this.id,
    required this.name,
    this.description
    });

  Map<String, dynamic> toJson() {
    return {
      'id' : id,
      'name': name,
      'description': description,
    };
  }

  factory ExpenseType.fromJson(Map<String, dynamic> json) {
    return ExpenseType(
      id: json['id'],
      name: json['name'],
      description: json['description'],
    );
  }
}