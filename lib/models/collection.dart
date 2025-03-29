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

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "description": description,
    "expenseList": expenseList.map((e) => e.toJson()).toList(), // Convert each Expense2 object to JSON
    "created": created.toIso8601String(),
    "updated": updated?.toIso8601String(),
  };

  factory Collection.fromJson(Map<String, dynamic> json) {
    return Collection(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      expenseList: (json['expenseList'] as List)
          .map((e) => Expense2.fromJson(e))
          .toList(),
      created: DateTime.parse(json['created']),
      updated: json['updated'] != null ? DateTime.parse(json['updated']) : null,
    );
  }

}