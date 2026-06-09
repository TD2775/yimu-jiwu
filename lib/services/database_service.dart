import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../models/item.dart';
import '../models/category.dart';
import '../models/tag.dart';
import '../models/lending.dart';
import '../models/reminder.dart';

class DatabaseService {
  static Database? _db;
  static const _dbName = 'yimu_jiwu.db';
  static const _dbVersion = 5;

  // ---------- 单例 ----------
  static Future<Database> get database async {
    _db ??= await _init();
    return _db!;
  }

  static Future<void> forceReopen() async {
    await _db?.close();
    _db = null;
    // 不自动打开：让下次调用 database 时自动 _init
  }

  static Future<Database> _init() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _dbName);
    return openDatabase(path, version: _dbVersion, onCreate: _onCreate, onUpgrade: _onUpgrade);
  }

  static Future<void> _onCreate(Database db, int version) async {
    // 分类表
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        icon TEXT NOT NULL,
        parentId TEXT,
        sortOrder INTEGER DEFAULT 0,
        createdAt TEXT NOT NULL
      )
    ''');

    // 标签表
    await db.execute('''
      CREATE TABLE tags (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        color INTEGER NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');

    // 物品表
    await db.execute('''
      CREATE TABLE items (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        categoryId TEXT NOT NULL,
        subCategoryId TEXT,
        tagIds TEXT DEFAULT '',
        price REAL,
        purchaseDate TEXT,
        warrantyExpiry TEXT,
        shelfLifeExpiry TEXT,
        membershipExpiry TEXT,
        location TEXT,
        notes TEXT,
        imagePaths TEXT DEFAULT '',
        stock INTEGER DEFAULT 1,
        lowStockThreshold INTEGER DEFAULT 1,
        specifications TEXT,
        residualValue REAL,
        purchaseChannel TEXT,
        purchaseMethod TEXT,
        extraCost REAL,
        extraCostNote TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        FOREIGN KEY (categoryId) REFERENCES categories(id)
      )
    ''');

    // 借出记录表
    await db.execute('''
      CREATE TABLE lendings (
        id TEXT PRIMARY KEY,
        itemId TEXT NOT NULL,
        borrowerName TEXT NOT NULL,
        borrowerContact TEXT,
        borrowDate TEXT NOT NULL,
        expectedReturnDate TEXT,
        actualReturnDate TEXT,
        status INTEGER DEFAULT 0,
        notes TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        FOREIGN KEY (itemId) REFERENCES items(id) ON DELETE CASCADE
      )
    ''');

    // 提醒表
    await db.execute('''
      CREATE TABLE reminders (
        id TEXT PRIMARY KEY,
        itemId TEXT NOT NULL,
        type INTEGER NOT NULL,
        remindDate TEXT NOT NULL,
        enabled INTEGER DEFAULT 1,
        advanceDays INTEGER DEFAULT 7,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (itemId) REFERENCES items(id) ON DELETE CASCADE
      )
    ''');

    // 索引
    await db.execute('CREATE INDEX idx_items_category ON items(categoryId)');
    await db.execute('CREATE INDEX idx_items_purchase ON items(purchaseDate)');
    await db.execute('CREATE INDEX idx_lendings_status ON lendings(status)');
    await db.execute('CREATE INDEX idx_lendings_item ON lendings(itemId)');
    await db.execute('CREATE INDEX idx_reminders_item ON reminders(itemId)');

    // 设置表
    await db.execute('''
      CREATE TABLE IF NOT EXISTS settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE items ADD COLUMN purchaseChannel TEXT');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE items ADD COLUMN purchaseMethod TEXT');
    }
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE items ADD COLUMN extraCost REAL');
    }
    if (oldVersion < 5) {
      await db.execute('ALTER TABLE items ADD COLUMN extraCostNote TEXT');
    }

    // 设置表
    await db.execute('''
      CREATE TABLE IF NOT EXISTS settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  // ==================== 物品 CRUD ====================

  static Future<List<Item>> getItems({
    String? categoryId,
    String? subCategoryId,
    String? searchQuery,
    DateTime? purchaseFrom,
    DateTime? purchaseTo,
    DateTime? expiryBefore,
    DateTime? expiryAfter,
    String? location,
    String sortBy = 'updatedAt',
    bool sortDesc = true,
  }) async {
    final db = await database;
    final where = <String>[];
    final whereArgs = <dynamic>[];

    if (categoryId != null) {
      where.add('categoryId = ?');
      whereArgs.add(categoryId);
    }
    if (subCategoryId != null) {
      where.add('subCategoryId = ?');
      whereArgs.add(subCategoryId);
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      where.add('name LIKE ?');
      whereArgs.add('%$searchQuery%');
    }
    if (purchaseFrom != null) {
      where.add('purchaseDate >= ?');
      whereArgs.add(purchaseFrom.toIso8601String());
    }
    if (purchaseTo != null) {
      where.add('purchaseDate <= ?');
      whereArgs.add(purchaseTo.toIso8601String());
    }
    if (location != null) {
      where.add('location = ?');
      whereArgs.add(location);
    }
    // 到期筛选（跨三列 OR）
    // 复杂筛选走 raw query 更合适；简单场景保留
    if (expiryBefore != null || expiryAfter != null) {
      final clauses = <String>[];
      if (expiryBefore != null) {
        clauses.add(
            "(shelfLifeExpiry <= ? OR warrantyExpiry <= ? OR membershipExpiry <= ?)");
        whereArgs.addAll([expiryBefore.toIso8601String(), expiryBefore.toIso8601String(), expiryBefore.toIso8601String()]);
      }
      if (expiryAfter != null) {
        clauses.add(
            "(shelfLifeExpiry >= ? OR warrantyExpiry >= ? OR membershipExpiry >= ?)");
        whereArgs.addAll([expiryAfter.toIso8601String(), expiryAfter.toIso8601String(), expiryAfter.toIso8601String()]);
      }
      where.add(clauses.join(' AND '));
    }

    final order = sortDesc ? 'DESC' : 'ASC';
    final maps = await db.query(
      'items',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: '$sortBy $order',
    );
    return maps.map(Item.fromMap).toList();
  }

  static Future<Item?> getItem(String id) async {
    final db = await database;
    final maps = await db.query('items', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Item.fromMap(maps.first);
  }

  static Future<void> insertItem(Item item) async {
    final db = await database;
    await db.insert('items', item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> updateItem(Item item) async {
    final db = await database;
    await db.update('items', item.toMap(), where: 'id = ?', whereArgs: [item.id]);
  }

  static Future<void> deleteItem(String id) async {
    final db = await database;
    // 级联删除关联的借出记录和提醒
    await db.delete('lendings', where: 'itemId = ?', whereArgs: [id]);
    await db.delete('reminders', where: 'itemId = ?', whereArgs: [id]);
    await db.delete('items', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> updateItemStock(String id, int newStock) async {
    final db = await database;
    await db.update('items', {'stock': newStock, 'updatedAt': DateTime.now().toIso8601String()},
        where: 'id = ?', whereArgs: [id]);
  }

  // ==================== 分类 CRUD ====================

  static Future<List<Category>> getCategories({String? parentId}) async {
    final db = await database;
    final maps = await db.query('categories',
        where: parentId == null ? 'parentId IS NULL' : 'parentId = ?',
        whereArgs: parentId == null ? null : [parentId],
        orderBy: 'sortOrder ASC');
    return maps.map(Category.fromMap).toList();
  }

  static Future<List<Category>> getAllSubCategories() async {
    final db = await database;
    final maps = await db.query('categories',
        where: 'parentId IS NOT NULL', orderBy: 'sortOrder ASC');
    return maps.map(Category.fromMap).toList();
  }

  static Future<void> insertCategory(Category cat) async {
    final db = await database;
    await db.insert('categories', cat.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> updateCategory(Category cat) async {
    final db = await database;
    await db.update('categories', cat.toMap(),
        where: 'id = ?', whereArgs: [cat.id]);
  }

  static Future<void> deleteCategory(String id) async {
    final db = await database;
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== 标签 CRUD ====================

  static Future<List<Tag>> getTags() async {
    final db = await database;
    final maps = await db.query('tags', orderBy: 'createdAt DESC');
    return maps.map(Tag.fromMap).toList();
  }

  static Future<void> insertTag(Tag tag) async {
    final db = await database;
    await db.insert('tags', tag.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> updateTag(Tag tag) async {
    final db = await database;
    await db.update('tags', tag.toMap(), where: 'id = ?', whereArgs: [tag.id]);
  }

  static Future<void> deleteTag(String id) async {
    final db = await database;
    await db.delete('tags', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== 借出 CRUD ====================

  static Future<List<Lending>> getLendings({
    String? itemId,
    LendStatus? status,
  }) async {
    final db = await database;
    final where = <String>[];
    final args = <dynamic>[];
    if (itemId != null) {
      where.add('itemId = ?');
      args.add(itemId);
    }
    if (status != null) {
      where.add('status = ?');
      args.add(status.index);
    }
    final maps = await db.query('lendings',
        where: where.isEmpty ? null : where.join(' AND '),
        whereArgs: args.isEmpty ? null : args,
        orderBy: 'borrowDate DESC');
    return maps.map(Lending.fromMap).toList();
  }

  static Future<List<Lending>> getActiveLendings() async =>
      getLendings(status: LendStatus.borrowed);

  static Future<void> insertLending(Lending lending) async {
    final db = await database;
    await db.insert('lendings', lending.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> updateLending(Lending lending) async {
    final db = await database;
    await db.update('lendings', lending.toMap(),
        where: 'id = ?', whereArgs: [lending.id]);
  }

  static Future<void> deleteLending(String id) async {
    final db = await database;
    await db.delete('lendings', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== 提醒 CRUD ====================

  static Future<List<Reminder>> getReminders({String? itemId}) async {
    final db = await database;
    final maps = await db.query('reminders',
        where: itemId != null ? 'itemId = ?' : null,
        whereArgs: itemId != null ? [itemId] : null);
    return maps.map(Reminder.fromMap).toList();
  }

  static Future<List<Reminder>> getEnabledReminders() async {
    final db = await database;
    final maps = await db.query('reminders',
        where: 'enabled = 1', orderBy: 'remindDate ASC');
    return maps.map(Reminder.fromMap).toList();
  }

  static Future<void> insertReminder(Reminder reminder) async {
    final db = await database;
    await db.insert('reminders', reminder.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> updateReminder(Reminder reminder) async {
    final db = await database;
    await db.update('reminders', reminder.toMap(),
        where: 'id = ?', whereArgs: [reminder.id]);
  }

  static Future<void> deleteReminder(String id) async {
    final db = await database;
    await db.delete('reminders', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== 统计查询 ====================

  /// 各分类物品数量
  static Future<Map<String, int>> getCategoryStats() async {
    final db = await database;
    final maps = await db.rawQuery(
        'SELECT categoryId, COUNT(*) as cnt FROM items GROUP BY categoryId');
    return {for (var m in maps) m['categoryId'] as String: m['cnt'] as int};
  }

  /// 各存放位置分布
  static Future<Map<String, int>> getLocationStats() async {
    final db = await database;
    final maps = await db.rawQuery(
        "SELECT location, COUNT(*) as cnt FROM items WHERE location IS NOT NULL AND location != '' GROUP BY location");
    return {for (var m in maps) m['location'] as String: m['cnt'] as int};
  }

  /// 按购买月份统计总花费
  static Future<Map<String, double>> getMonthlySpending() async {
    final db = await database;
    final maps = await db.rawQuery(
        "SELECT substr(purchaseDate,1,7) as month, SUM(price) as total FROM items WHERE price IS NOT NULL AND purchaseDate IS NOT NULL GROUP BY month ORDER BY month");
    return {for (var m in maps) m['month'] as String: (m['total'] as num).toDouble()};
  }

  /// 总物品数
  static Future<int> getItemCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as cnt FROM items');
    return result.first['cnt'] as int;
  }

  /// 总资产价值
  static Future<double> getTotalValue() async {
    final db = await database;
    final result = await db.rawQuery(
        'SELECT SUM(price) as total FROM items WHERE price IS NOT NULL');
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  // ==================== 设置 ====================

  static Future<String?> getSetting(String key) async {
    final db = await database;
    final maps = await db.query('settings', where: 'key = ?', whereArgs: [key]);
    if (maps.isEmpty) return null;
    return maps.first['value'] as String;
  }

  static Future<void> setSetting(String key, String value) async {
    final db = await database;
    // Ensure table exists (fresh installs may not have run _onUpgrade yet)
    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS settings (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL
        )
      ''');
      await db.insert('settings', {'key': key, 'value': value},
          conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      // fallback: table might already exist, try insert
      await db.insert('settings', {'key': key, 'value': value},
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }
}
