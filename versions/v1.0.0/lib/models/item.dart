/// 物品核心模型
class Item {
  final String id;
  final String name;
  final String categoryId;
  final String? subCategoryId;
  final List<String> tagIds;
  final double? price; // 购买价格
  final double? extraCost; // 额外费用（运费/关税等）
  final String? extraCostNote; // 额外费用备注
  final DateTime? purchaseDate;
  final DateTime? warrantyExpiry;
  final DateTime? shelfLifeExpiry;
  final DateTime? membershipExpiry;
  final String? location;
  final String? notes;
  final List<String> imagePaths;
  final int stock;
  final int lowStockThreshold;
  final String? specifications;
  final double? residualValue;
  final String? purchaseChannel;
  final String? purchaseMethod;
  final DateTime createdAt;
  final DateTime updatedAt;

  Item({
    required this.id,
    required this.name,
    required this.categoryId,
    this.subCategoryId,
    List<String>? tagIds,
    this.price,
    this.extraCost,
    this.extraCostNote,
    this.purchaseDate,
    this.warrantyExpiry,
    this.shelfLifeExpiry,
    this.membershipExpiry,
    this.location,
    this.notes,
    List<String>? imagePaths,
    this.stock = 1,
    this.lowStockThreshold = 1,
    this.specifications,
    this.residualValue,
    this.purchaseChannel,
    this.purchaseMethod,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : tagIds = tagIds ?? [],
        imagePaths = imagePaths ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // ---------- 总成本 ----------
  double? get totalCost {
    final p = price;
    if (p == null) return extraCost;
    return p + (extraCost ?? 0);
  }

  // ---------- 计算属性 ----------

  int get usageDays {
    if (purchaseDate == null) return 0;
    return DateTime.now().difference(purchaseDate!).inDays;
  }

  String get usageText {
    final d = usageDays;
    if (d == 0) return '今天';
    if (d < 30) return '使用${d}天';
    if (d < 365) return '使用${d ~/ 30}月${d % 30 > 0 ? '${d % 30}天' : ''}';
    return '使用${d ~/ 365}年';
  }

  double? get dailyCost {
    final cost = totalCost;
    if (cost == null || purchaseDate == null) return null;
    final days = DateTime.now().difference(purchaseDate!).inDays;
    if (days <= 0) return null;
    final effectiveResidual = residualValue ?? _estimateResidualValue();
    return (cost - effectiveResidual) / days;
  }

  bool get isLowStock => stock <= lowStockThreshold;

  bool get hasExpiryWarning {
    final now = DateTime.now();
    final soon = now.add(const Duration(days: 30));
    return (shelfLifeExpiry != null && shelfLifeExpiry!.isBefore(soon)) ||
        (warrantyExpiry != null && warrantyExpiry!.isBefore(soon)) ||
        (membershipExpiry != null && membershipExpiry!.isBefore(soon));
  }

  int? get daysUntilExpiry {
    final dates = <DateTime>[
      if (shelfLifeExpiry != null) shelfLifeExpiry!,
      if (warrantyExpiry != null) warrantyExpiry!,
      if (membershipExpiry != null) membershipExpiry!,
    ];
    if (dates.isEmpty) return null;
    dates.sort();
    return dates.first.difference(DateTime.now()).inDays;
  }

  double _estimateResidualValue() {
    if (totalCost == null || purchaseDate == null) return 0;
    final years = DateTime.now().difference(purchaseDate!).inDays / 365.0;
    if (years <= 1) return totalCost! * 0.7;
    if (years <= 3) return totalCost! * 0.4;
    if (years <= 5) return totalCost! * 0.2;
    return totalCost! * 0.05;
  }

  // ---------- 序列化 ----------

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'categoryId': categoryId,
        'subCategoryId': subCategoryId,
        'tagIds': tagIds.join(','),
        'price': price,
        'extraCost': extraCost,
        'extraCostNote': extraCostNote,
        'purchaseDate': purchaseDate?.toIso8601String(),
        'warrantyExpiry': warrantyExpiry?.toIso8601String(),
        'shelfLifeExpiry': shelfLifeExpiry?.toIso8601String(),
        'membershipExpiry': membershipExpiry?.toIso8601String(),
        'location': location,
        'notes': notes,
        'imagePaths': imagePaths.join(','),
        'stock': stock,
        'lowStockThreshold': lowStockThreshold,
        'specifications': specifications,
        'residualValue': residualValue,
        'purchaseChannel': purchaseChannel,
        'purchaseMethod': purchaseMethod,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Item.fromMap(Map<String, dynamic> map) => Item(
        id: map['id'],
        name: map['name'],
        categoryId: map['categoryId'],
        subCategoryId: map['subCategoryId'],
        tagIds: (map['tagIds'] as String?)?.split(',').where((s) => s.isNotEmpty).toList() ?? [],
        price: map['price'],
        extraCost: map['extraCost'],
        extraCostNote: map['extraCostNote'],
        purchaseDate: map['purchaseDate'] != null ? DateTime.parse(map['purchaseDate']) : null,
        warrantyExpiry: map['warrantyExpiry'] != null ? DateTime.parse(map['warrantyExpiry']) : null,
        shelfLifeExpiry: map['shelfLifeExpiry'] != null ? DateTime.parse(map['shelfLifeExpiry']) : null,
        membershipExpiry: map['membershipExpiry'] != null ? DateTime.parse(map['membershipExpiry']) : null,
        location: map['location'],
        notes: map['notes'],
        imagePaths: (map['imagePaths'] as String?)?.split(',').where((s) => s.isNotEmpty).toList() ?? [],
        stock: map['stock'] ?? 1,
        lowStockThreshold: map['lowStockThreshold'] ?? 1,
        specifications: map['specifications'],
        residualValue: map['residualValue'],
        purchaseChannel: map['purchaseChannel'],
        purchaseMethod: map['purchaseMethod'],
        createdAt: DateTime.parse(map['createdAt']),
        updatedAt: DateTime.parse(map['updatedAt']),
      );

  Item copyWith({
    String? name,
    String? categoryId,
    String? subCategoryId,
    List<String>? tagIds,
    double? price,
    double? extraCost,
    String? extraCostNote,
    DateTime? purchaseDate,
    DateTime? warrantyExpiry,
    DateTime? shelfLifeExpiry,
    DateTime? membershipExpiry,
    String? location,
    String? notes,
    List<String>? imagePaths,
    int? stock,
    int? lowStockThreshold,
    String? specifications,
    double? residualValue,
    String? purchaseChannel,
    String? purchaseMethod,
  }) =>
      Item(
        id: id,
        name: name ?? this.name,
        categoryId: categoryId ?? this.categoryId,
        subCategoryId: subCategoryId ?? this.subCategoryId,
        tagIds: tagIds ?? this.tagIds,
        price: price ?? this.price,
        extraCost: extraCost ?? this.extraCost,
        extraCostNote: extraCostNote ?? this.extraCostNote,
        purchaseDate: purchaseDate ?? this.purchaseDate,
        warrantyExpiry: warrantyExpiry ?? this.warrantyExpiry,
        shelfLifeExpiry: shelfLifeExpiry ?? this.shelfLifeExpiry,
        membershipExpiry: membershipExpiry ?? this.membershipExpiry,
        location: location ?? this.location,
        notes: notes ?? this.notes,
        imagePaths: imagePaths ?? this.imagePaths,
        stock: stock ?? this.stock,
        lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
        specifications: specifications ?? this.specifications,
        residualValue: residualValue ?? this.residualValue,
        purchaseChannel: purchaseChannel ?? this.purchaseChannel,
        purchaseMethod: purchaseMethod ?? this.purchaseMethod,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );
}
