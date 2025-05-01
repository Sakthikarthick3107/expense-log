import 'package:hive/hive.dart';
part 'message.g.dart';

@HiveType(typeId: 6)
class Message {
  @HiveField(0)
  int id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String content;

  @HiveField(3)
  DateTime date;

  @HiveField(4)
  bool isRead;

  @HiveField(5)
  String type;

  @HiveField(6)
  String? attachment;

  @HiveField(7)
  String? ctaLink;

  Message({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
    required this.isRead,
    required this.type,
    this.attachment,
    this.ctaLink,
  });

  void markAsRead() {
    isRead = true;
  }
}
