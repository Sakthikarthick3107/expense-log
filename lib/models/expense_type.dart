

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
}