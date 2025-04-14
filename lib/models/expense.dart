
import 'package:hive/hive.dart';
part 'expense.g.dart';

@HiveType(typeId: 0)
class Expense{
  
  @HiveField(0)
  int id;
  
  @HiveField(1)
  String name;
  
  @HiveField(2)
  double price;

  @HiveField(3)
  String expenseType;
  
  @HiveField(4)
  DateTime date;
  
  @HiveField(5)
  DateTime created;
  
  @HiveField(6)
  DateTime? updated;

  @HiveField(7)
  bool isReturnable;

  Expense({
    required this.id,
    required this.name,
    required this.price,
    required this.expenseType,
    required this.date,
    required this.created,
    this.updated,
    this.isReturnable = false
    });

  Future<void> save() async{
    final box = await Hive.openBox<Expense>('expenseBox');
    box.put(id,this);
  }



}