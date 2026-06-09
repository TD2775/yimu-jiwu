import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/item.dart';
import '../models/category.dart';
import '../models/tag.dart';
import '../models/lending.dart';
import '../models/reminder.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

class ItemProvider extends ChangeNotifier {
  final _uuid = const Uuid();

  List<Item> _items = [];
  List<Category> _categories = [];
  List<Category> _subCategories = [];
  List<Tag> _tags = [];
  List<Lending> _activeLendings = [];

  // 展示模式：0=列表, 1=瀑布流, 2=极简
  int _displayMode = 0;

  // 筛选状态
  String? _filterCategoryId;
  String? _filterSubCategoryId;
  String? _searchQuery;

  // 排序状态
  String _sortField = 'default';
  bool _sortAsc = false;

  // 功能开关
  bool _showInventory = false;
  bool _showLending = false;

  // ==================== getters ====================

  List<Item> get items => _items;
  List<Category> get categories => _categories;
  List<Category> get subCategories => _subCategories;
  List<Tag> get tags => _tags;
  List<Lending> get activeLendings => _activeLendings;
  int get displayMode => _displayMode;
  String? get filterCategoryId => _filterCategoryId;
  String? get filterSubCategoryId => _filterSubCategoryId;
  String? get searchQuery => _searchQuery;

  String get sortField => _sortField;
  bool get sortAsc => _sortAsc;
  bool get showInventory => _showInventory;
  bool get showLending => _showLending;

  void setShowInventory(bool v) { _showInventory = v; notifyListeners(); }
  void setShowLending(bool v) { _showLending = v; notifyListeners(); }

  /// 筛选 + 排序后的列表
  List<Item> get filteredItems {
    var list = List<Item>.from(_items);

    // 筛选
    if (_searchQuery != null && _searchQuery!.isNotEmpty) {
      list = list
          .where((i) =>
              i.name.contains(_searchQuery!) ||
              (i.notes?.contains(_searchQuery!) ?? false))
          .toList();
    }
    if (_filterCategoryId != null) {
      list =
          list.where((i) => i.categoryId == _filterCategoryId).toList();
    }
    if (_filterSubCategoryId != null) {
      list = list
          .where((i) => i.subCategoryId == _filterSubCategoryId)
          .toList();
    }

    // 排序
    list.sort((a, b) {
      int cmp;
      switch (_sortField) {
        case 'price':
          cmp = (a.price ?? 0).compareTo(b.price ?? 0);
          break;
        case 'purchaseDate':
          cmp = _compareDates(a.purchaseDate, b.purchaseDate);
          break;
        case 'expiryDate':
          cmp = _compareDates(a.warrantyExpiry, b.warrantyExpiry);
          break;
        case 'dailyCost':
          cmp = (a.dailyCost ?? 0).compareTo(b.dailyCost ?? 0);
          break;
        default: // default
          cmp = b.updatedAt.compareTo(a.updatedAt); // newest first default
      }
      return _sortAsc ? cmp : -cmp;
    });

    return list;
  }

  int _compareDates(DateTime? a, DateTime? b) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    return a.compareTo(b);
  }

  /// 需要提醒库存的物品
  List<Item> get lowStockItems =>
      _items.where((i) => i.isLowStock).toList();

  /// 即将到期的物品（30天内）
  List<Item> get expiringItems =>
      _items.where((i) => i.hasExpiryWarning).toList();

  /// 借出中的物品ID集合
  Set<String> get lentItemIds =>
      _activeLendings.map((l) => l.itemId).toSet();

  /// 各分类统计
  Map<String, int> get categoryCounts {
    final map = <String, int>{};
    for (var item in _items) {
      map[item.categoryId] = (map[item.categoryId] ?? 0) + 1;
    }
    return map;
  }

  /// 总资产
  double get totalValue =>
      _items.fold(0.0, (sum, i) => sum + (i.totalCost ?? 0));

  // ==================== 初始化 ====================

  Future<void> init() async {
    try { await NotificationService.init(); } catch (_) {}
    try {
      await loadAll();
      if (_categories.isEmpty) await _seedDefaultCategories();
    } catch (_) {
      // fallback: at least load items
      _items = await DatabaseService.getItems();
      notifyListeners();
    }
  }

  Future<void> _seedDefaultCategories() async {
    final defaults = [
      {'name': '电子产品', 'icon': 'phone_android', 'subs': ['手机', '电脑/平板', '耳机/音箱', '相机', '游戏机']},
      {'name': '家用电器', 'icon': 'kitchen', 'subs': ['厨房电器', '生活电器', '个护电器']},
      {'name': '服饰鞋包', 'icon': 'checkroom', 'subs': ['衣服', '鞋靴', '箱包']},
      {'name': '珠宝首饰', 'icon': 'diamond', 'subs': []},
      {'name': '虚拟会员', 'icon': 'card_membership', 'subs': ['视频会员', '音乐会员', '云存储', '其他订阅']},
      {'name': '食品药品', 'icon': 'medical_services', 'subs': ['药品', '保健品', '食品饮料']},
      {'name': '图书文具', 'icon': 'book', 'subs': []},
      {'name': '其他', 'icon': 'folder', 'subs': []},
    ];
    for (final d in defaults) {
      final parentId = _uuid.v4();
      final parent = Category(id: parentId, name: d['name'] as String, icon: d['icon'] as String);
      await DatabaseService.insertCategory(parent);
      for (final subName in (d['subs'] as List<String>)) {
        final sub = Category(id: _uuid.v4(), name: subName, icon: d['icon'] as String, parentId: parentId);
        await DatabaseService.insertCategory(sub);
      }
    }
    await loadAll();
  }

  Future<void> loadAll() async {
    _items = await DatabaseService.getItems();
    _categories = await DatabaseService.getCategories();
    _subCategories = await DatabaseService.getAllSubCategories();
    _tags = await DatabaseService.getTags();
    _activeLendings = await DatabaseService.getActiveLendings();
    notifyListeners();
  }

  // ==================== 物品操作 ====================

  Future<void> addItem(Item item) async {
    await DatabaseService.insertItem(item);
    try { await _syncRemindersForItem(item); } catch (_) {}
    await loadAll();
  }

  Future<void> updateItem(Item item) async {
    await DatabaseService.updateItem(item);
    try { await _syncRemindersForItem(item); } catch (_) {}
    await loadAll();
  }

  Future<void> deleteItem(String id) async {
    // 取消相关提醒通知
    final reminders = await DatabaseService.getReminders(itemId: id);
    for (var r in reminders) {
      await NotificationService.cancelReminder(r);
    }
    await DatabaseService.deleteItem(id);
    await loadAll();
  }

  Future<void> quickAdjustStock(String itemId, int delta) async {
    final item = _items.firstWhere((i) => i.id == itemId);
    final newStock = (item.stock + delta).clamp(0, 999999);
    await DatabaseService.updateItemStock(itemId, newStock);
    await loadAll();
  }

  /// 同步物品的所有提醒
  Future<void> _syncRemindersForItem(Item item) async {
    // 删除旧提醒
    final oldReminders = await DatabaseService.getReminders(itemId: item.id);
    for (var r in oldReminders) {
      await NotificationService.cancelReminder(r);
      await DatabaseService.deleteReminder(r.id);
    }

    // 按到期日期创建新提醒
    final reminderDates = <ReminderType, DateTime?>{
      ReminderType.expiry: item.shelfLifeExpiry,
      ReminderType.warranty: item.warrantyExpiry,
      ReminderType.membership: item.membershipExpiry,
    };

    for (var entry in reminderDates.entries) {
      if (entry.value == null) continue;
      final reminder = Reminder(
        id: _uuid.v4(),
        itemId: item.id,
        type: entry.key,
        remindDate: entry.value!,
      );
      await DatabaseService.insertReminder(reminder);
      try { await NotificationService.scheduleReminder(reminder); } catch (_) {}
    }
  }

  // ==================== 分类操作 ====================

  Future<void> addCategory(Category cat) async {
    await DatabaseService.insertCategory(cat);
    await loadAll();
  }

  Future<void> updateCategory(Category cat) async {
    await DatabaseService.updateCategory(cat);
    await loadAll();
  }

  Future<void> deleteCategory(String id) async {
    await DatabaseService.deleteCategory(id);
    await loadAll();
  }

  /// 更新分类排序顺序
  Future<void> reorderCategories(List<String> orderedIds) async {
    for (int i = 0; i < orderedIds.length; i++) {
      final cat = _categories.firstWhere((c) => c.id == orderedIds[i]);
      final updated = cat.copyWith(sortOrder: i);
      await DatabaseService.updateCategory(updated);
    }
    await loadAll();
  }

  // ==================== 标签操作 ====================

  Future<void> addTag(Tag tag) async {
    await DatabaseService.insertTag(tag);
    await loadAll();
  }

  Future<void> updateTag(Tag tag) async {
    await DatabaseService.updateTag(tag);
    await loadAll();
  }

  Future<void> deleteTag(String id) async {
    await DatabaseService.deleteTag(id);
    await loadAll();
  }

  // ==================== 借出操作 ====================

  Future<void> addLending(Lending lending) async {
    await DatabaseService.insertLending(lending);
    await loadAll();
  }

  Future<void> updateLending(Lending lending) async {
    await DatabaseService.updateLending(lending);
    await loadAll();
  }

  Future<void> markLendingReturned(String lendingId) async {
    final lending =
        _activeLendings.firstWhere((l) => l.id == lendingId);
    final updated = lending.copyWith(
      status: LendStatus.returned,
      actualReturnDate: DateTime.now(),
    );
    await DatabaseService.updateLending(updated);
    await loadAll();
  }

  Future<void> markLendingRenewed(String lendingId) async {
    final lending =
        _activeLendings.firstWhere((l) => l.id == lendingId);
    final updated = lending.copyWith(status: LendStatus.renewed);
    await DatabaseService.updateLending(updated);
    await loadAll();
  }

  Future<void> markLendingLost(String lendingId) async {
    final lending =
        _activeLendings.firstWhere((l) => l.id == lendingId);
    final updated = lending.copyWith(status: LendStatus.lost);
    await DatabaseService.updateLending(updated);
    await loadAll();
  }

  // ==================== 筛选 & 展示 ====================

  void setDisplayMode(int mode) {
    _displayMode = mode;
    notifyListeners();
  }

  void setFilterCategory(String? categoryId) {
    _filterCategoryId = categoryId;
    _filterSubCategoryId = null;
    notifyListeners();
  }

  void setFilterSubCategory(String? subCategoryId) {
    _filterSubCategoryId = subCategoryId;
    notifyListeners();
  }

  void setSearchQuery(String? query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearFilters() {
    _filterCategoryId = null;
    _filterSubCategoryId = null;
    _searchQuery = null;
    notifyListeners();
  }

  void setSort(String field, bool asc) {
    _sortField = field;
    _sortAsc = asc;
    notifyListeners();
  }

  // ==================== 统计 ====================

  Future<Map<String, int>> getLocationStats() async =>
      DatabaseService.getLocationStats();

  Future<Map<String, double>> getMonthlySpending() async =>
      DatabaseService.getMonthlySpending();
}
