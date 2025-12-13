import 'package:hive/hive.dart';

part 'account.g.dart';

@HiveType(typeId: 11)
class Account {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String code;

  @HiveField(3)
  final String? description;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  final DateTime? updatedAt;

  @HiveField(6)
  String? smsKeyword;

  @HiveField(7)
  DateTime? lastSmsSyncedAt;

  Account({
    required this.id,
    required this.name,
    required this.code,
    this.description,
    required this.createdAt,
    this.updatedAt,
    this.smsKeyword,
    this.lastSmsSyncedAt
  });

  Account copyWith({
    int? id,
    String? name,
    String? code,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? type,
    String? smsKeyword,
    DateTime? lastSmsSyncedAt
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      smsKeyword: smsKeyword ?? this.smsKeyword,
      lastSmsSyncedAt: lastSmsSyncedAt ?? this.lastSmsSyncedAt
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'code': code,
        'description': description,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'smsKeyword': smsKeyword,
        'lastSmsSyncedAt': lastSmsSyncedAt?.toIso8601String()
      };

  factory Account.fromJson(Map<dynamic, dynamic> j) => Account(
        id: j['id'] as int,
        name: j['name'] as String,
        code: j['code'] as String,
        description: j['description'] as String?,
        createdAt: DateTime.parse(j['createdAt'] as String),
        updatedAt: j['updatedAt'] != null ? DateTime.parse(j['updatedAt'] as String) : null,
        smsKeyword: j['smsKeyword'] as String?,
        lastSmsSyncedAt: j['lastSmsSyncedAt'] != null ? DateTime.parse(j['lastSmsSyncedAt'] as String) : null,
      );
}