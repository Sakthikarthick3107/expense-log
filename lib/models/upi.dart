
import 'package:hive/hive.dart';
part 'upi.g.dart';

@HiveType(typeId: 5)
class UpiLog {
  @HiveField(0)
  final String message;

  @HiveField(1)
  final DateTime timestamp;

  UpiLog({required this.message, required this.timestamp});
}