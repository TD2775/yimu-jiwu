/// 物品分类模型
class Category {
  final String id;
  final String name;
  final String icon; // Material Icons 代号
  final String? parentId; // null = 一级分类
  final int sortOrder;
  final DateTime createdAt;

  Category({
    required this.id,
    required this.name,
    required this.icon,
    this.parentId,
    this.sortOrder = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'icon': icon,
        'parentId': parentId,
        'sortOrder': sortOrder,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Category.fromMap(Map<String, dynamic> map) => Category(
        id: map['id'],
        name: map['name'],
        icon: map['icon'],
        parentId: map['parentId'],
        sortOrder: map['sortOrder'] ?? 0,
        createdAt: DateTime.parse(map['createdAt']),
      );

  Category copyWith({
    String? id,
    String? name,
    String? icon,
    String? parentId,
    int? sortOrder,
  }) =>
      Category(
        id: id ?? this.id,
        name: name ?? this.name,
        icon: icon ?? this.icon,
        parentId: parentId ?? this.parentId,
        sortOrder: sortOrder ?? this.sortOrder,
        createdAt: createdAt,
      );
}
