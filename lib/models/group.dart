import 'package:hive/hive.dart';

part 'group.g.dart';

@HiveType(typeId: 12)
class Group {
  @HiveField(0)
  int id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String? description;

  @HiveField(3)
  DateTime created;

  @HiveField(4)
  DateTime? updated;

  @HiveField(5)
  List<String> members;

  Group({
    required this.id,
    required this.name,
    this.description,
    required this.created,
    this.updated,
    this.members = const ['Me'],
  });

  Group copyWith({
    int? id,
    String? name,
    String? description,
    DateTime? created,
    DateTime? updated,
    List<String>? members,
  }) {
    return Group(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      created: created ?? this.created,
      updated: updated ?? this.updated,
      members: members ?? this.members,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'created': created.toIso8601String(),
      'updated': updated?.toIso8601String(),
      'members': members,
    };
  }

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'],
      name: json['name'],
      description: json['description'] as String?,
      created: DateTime.parse(json['created']),
      updated: json['updated'] != null ? DateTime.parse(json['updated']) : null,
      members: (json['members'] as List).cast<String>(),
    );
  }
}
