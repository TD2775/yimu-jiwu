/// 标签模型
class Tag {
  final String id;
  final String name;
  final int color; // 0xAARRGGBB
  final DateTime createdAt;

  Tag({
    required this.id,
    required this.name,
    required this.color,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'color': color,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Tag.fromMap(Map<String, dynamic> map) => Tag(
        id: map['id'],
        name: map['name'],
        color: map['color'],
        createdAt: DateTime.parse(map['createdAt']),
      );

  Tag copyWith({String? id, String? name, int? color}) => Tag(
        id: id ?? this.id,
        name: name ?? this.name,
        color: color ?? this.color,
        createdAt: createdAt,
      );
}
