import 'package:expense_log/models/expense2.dart';
import 'package:hive/hive.dart';
part 'collection.g.dart';


@HiveType(typeId: 3)
class Collection{
  @HiveField(0)
  int id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String? description;

  @HiveField(3)
  List<Expense2> expenseList;

  @HiveField(4)
  DateTime created;

  @HiveField(5)
  DateTime? updated;

  Collection({
      required this.id,
      required this.name,
    this.description,
    required this.expenseList,
    required this.created,
    this.updated
      });


}