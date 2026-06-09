import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/item.dart';
import '../models/category.dart';
import '../providers/item_provider.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import 'add_edit_item_screen.dart';
import 'item_detail_screen.dart';
import 'category_manage_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ItemProvider>();
    final items = provider.items;

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        title: const Text('一木记物', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          _buildDisplayModeBtn(provider),
          IconButton(icon: const Icon(Icons.sort), tooltip: '排序', onPressed: () => _showSortSheet(context)),
          IconButton(icon: const Icon(Icons.category_outlined), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoryManageScreen()))),
        ],
      ),
      body: Column(children: [
        _StatsHeader(items: items),
        const SizedBox(height: 8),
        _CategoryTabs(provider: provider),
        const SizedBox(height: 8),
        Expanded(child: _buildBody(provider)),
      ]),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditItemScreen())),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(ItemProvider provider) {
    final list = provider.filteredItems;
    if (list.isEmpty) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.inventory_2_outlined, size: 64, color: AppColors.textHint), const SizedBox(height: 16), Text('还没有物品，点击 + 添加', style: TextStyle(color: AppColors.textSecondary, fontSize: 16))]));

    switch (provider.displayMode) {
      case 0: return _ItemList(items: list);
      case 1: return _ItemGrid(items: list);
      case 2: return _ItemCompact(items: list);
      default: return _ItemList(items: list);
    }
  }

  void _showSortSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => const _SortSheet(),
    );
  }

  Widget _buildDisplayModeBtn(ItemProvider provider) {
    final icons = [Icons.view_list, Icons.dashboard, Icons.view_agenda];
    final labels = ['列表', '瀑布流', '极简'];
    return PopupMenuButton<int>(
      icon: Icon(icons[provider.displayMode.clamp(0, 2)]),
      tooltip: '展示模式',
      onSelected: provider.setDisplayMode,
      itemBuilder: (_) => List.generate(3, (i) => PopupMenuItem(value: i, child: Text(labels[i]))),
    );
  }
}

class _SortSheet extends StatefulWidget {
  const _SortSheet();
  @override
  State<_SortSheet> createState() => _SortSheetState();
}

class _SortSheetState extends State<_SortSheet> {
  static const sortOpts = [
    {'f': 'default', 'l': '默认排序', 'i': Icons.sort},
    {'f': 'price', 'l': '购买价格', 'i': Icons.monetization_on_outlined},
    {'f': 'purchaseDate', 'l': '购买日期', 'i': Icons.calendar_today},
    {'f': 'expiryDate', 'l': '到期日期', 'i': Icons.timer_outlined},
    {'f': 'dailyCost', 'l': '日均成本', 'i': Icons.trending_down},
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ItemProvider>();
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 20),
        const Text('排序方式', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        Wrap(spacing: 10, runSpacing: 10, children: sortOpts.map((o) {
          final f = o['f'] as String;
          final l = o['l'] as String;
          final ic = o['i'] as IconData;
          final sel = provider.sortField == f;
          return GestureDetector(
            onTap: () { provider.setSort(f, provider.sortAsc); setState(() {}); },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(color: sel ? AppColors.primary : AppColors.bgSecondary, borderRadius: BorderRadius.circular(22)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(ic, size: 18, color: sel ? Colors.white : AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(l, style: TextStyle(fontSize: 14, fontWeight: sel ? FontWeight.w600 : FontWeight.normal, color: sel ? Colors.white : AppColors.textPrimary)),
              ]),
            ),
          );
        }).toList()),
        const SizedBox(height: 24),
        const Text('排列顺序', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: GestureDetector(
            onTap: () { provider.setSort(provider.sortField, false); setState(() {}); },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(color: provider.sortAsc ? AppColors.bgSecondary : AppColors.primary, borderRadius: BorderRadius.circular(12)),
              alignment: Alignment.center,
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.arrow_downward, size: 18, color: provider.sortAsc ? AppColors.textSecondary : Colors.white),
                const SizedBox(width: 6),
                Text('降序', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: provider.sortAsc ? AppColors.textPrimary : Colors.white)),
              ]),
            ),
          )),
          const SizedBox(width: 12),
          Expanded(child: GestureDetector(
            onTap: () { provider.setSort(provider.sortField, true); setState(() {}); },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(color: provider.sortAsc ? AppColors.primary : AppColors.bgSecondary, borderRadius: BorderRadius.circular(12)),
              alignment: Alignment.center,
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.arrow_upward, size: 18, color: provider.sortAsc ? Colors.white : AppColors.textSecondary),
                const SizedBox(width: 6),
                Text('升序', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: provider.sortAsc ? Colors.white : AppColors.textPrimary)),
              ]),
            ),
          )),
        ]),
        const SizedBox(height: 24),
      ]),
    );
  }
}

// ========== 统计头 ==========
class _StatsHeader extends StatelessWidget {
  final List<Item> items;
  const _StatsHeader({required this.items});
  @override
  Widget build(BuildContext context) {
    final totalValue = items.fold(0.0, (s, i) => s + (i.totalCost ?? 0));
    final totalDaily = items.fold(0.0, (s, i) => s + (i.dailyCost ?? 0));
    final exp = items.where((i) => i.shelfLifeExpiry != null && i.shelfLifeExpiry!.isAfter(DateTime.now()) && i.shelfLifeExpiry!.difference(DateTime.now()).inDays <= 30).length;
    final mem = items.where((i) => i.membershipExpiry != null && i.membershipExpiry!.isAfter(DateTime.now()) && i.membershipExpiry!.difference(DateTime.now()).inDays <= 30).length;
    return Container(margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border, width: 0.5)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      GestureDetector(onTap: () => _showValueDetail(context, items, '总价值'), child: _s('总价值', formatPrice(totalValue))),
      GestureDetector(onTap: () => _showValueDetail(context, items, '物品数量'), child: _s('物品数量', '${items.length}')),
      _s('日均成本', formatPrice(totalDaily)), _s('保质期临期', '$exp'), _s('会员将至', '$mem'),
    ]));
  }
  Widget _s(String l, String v) => Column(children: [Text(v, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary)), const SizedBox(height: 4), Text(l, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary))]);

  void _showValueDetail(BuildContext context, List<Item> items, String label) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => _SimpleItemList(title: label, items: items)));
  }
}

class _SimpleItemList extends StatelessWidget {
  final String title;
  final List<Item> items;
  const _SimpleItemList({required this.title, required this.items});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: items.isEmpty
          ? Center(child: Text('暂无', style: TextStyle(color: AppColors.textHint)))
          : ListView.separated(padding: const EdgeInsets.only(bottom: 80), itemCount: items.length, separatorBuilder: (_,__) => const Divider(height: 1, indent: 88, endIndent: 16), itemBuilder: (_, i) {
              final item = items[i];
              return InkWell(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ItemDetailScreen(itemId: item.id))),
                child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  ClipRRect(borderRadius: BorderRadius.circular(8), child: item.imagePaths.isNotEmpty ? buildSmartImage(item.imagePaths.first, width: 64, height: 64) : Container(width: 64, height: 64, decoration: BoxDecoration(color: AppColors.bgSecondary, borderRadius: BorderRadius.circular(8)), child: Icon(Icons.photo_library_outlined, size: 24, color: AppColors.textHint))),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    // 名称 + 状态 同行
                    Row(children: [Expanded(child: Text(item.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis)), Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), decoration: BoxDecoration(color: AppColors.accent.withAlpha(25), borderRadius: BorderRadius.circular(10)), child: const Text('使用中', style: TextStyle(fontSize: 11, color: AppColors.accent, fontWeight: FontWeight.w600)))]),
                    // 使用天数 + 日均成本
                    if (item.usageDays > 0 || item.dailyCost != null)
                      Padding(padding: const EdgeInsets.only(top: 4), child: Row(children: [
                        if (item.usageDays > 0) Text(item.usageText, style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                        if (item.dailyCost != null) ...[const SizedBox(width: 10), Text('日均${formatDailyCost(item.dailyCost)}', style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w500))],
                      ])),
                    if (item.usageDays <= 0 && item.dailyCost == null && item.totalCost == null)
                      const SizedBox(height: 4),
                    const SizedBox(height: 6),
                    Row(children: [if (item.purchaseChannel != null) ...[Icon(Icons.store_outlined, size: 12, color: AppColors.textHint), const SizedBox(width: 3), Text(item.purchaseChannel!, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)), const SizedBox(width: 12)], if (item.warrantyExpiry != null) ...[Icon(Icons.shield_outlined, size: 12, color: AppColors.textHint), const SizedBox(width: 3), Text('${_warrantyTextShort(item.warrantyExpiry!)}后过保', style: TextStyle(fontSize: 12, color: AppColors.textSecondary))]]),
                  ])),
                  // 右侧总价
                  if (item.totalCost != null) ...[
                    const SizedBox(width: 8),
                    Center(child: Text(formatPrice(item.totalCost), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primary))),
                  ],
                ])),
              );
            }),
    );
  }
  String _warrantyTextShort(DateTime d) {
    final dayDiff = d.difference(DateTime.now()).inDays;
    if (dayDiff < 0) return '已过期';
    if (dayDiff < 30) return '${dayDiff}天';
    if (dayDiff < 365) return '${(dayDiff / 30).floor()}个月${dayDiff % 30 > 0 ? '${dayDiff % 30}天' : ''}';
    final years = (dayDiff / 365).floor();
    final remaining = dayDiff % 365;
    if (remaining == 0) return '${years}年';
    return '${years}年${(remaining / 30).floor()}个月';
  }
}

// ========== 分类标签（一级+二级）==========
class _CategoryTabs extends StatefulWidget {
  final ItemProvider provider;
  const _CategoryTabs({required this.provider});
  @override
  State<_CategoryTabs> createState() => _CategoryTabsState();
}

class _CategoryTabsState extends State<_CategoryTabs> {
  @override
  void initState() {
    super.initState();
    _selectedParent = widget.provider.filterCategoryId;
  }

  String? _selectedParent;

  /// 按 sortOrder 排序的一级分类列表
  List<_TabD> _buildParentTabs(ItemProvider provider) {
    final items = provider.items;
    final tabs = <_TabD>[];
    tabs.add(_TabD(null, '所有物品', items.length));

    // 收集有物品的分类ID，按 sortOrder 排序
    final catIds = <String>{};
    for (final item in items) {
      catIds.add(item.categoryId);
    }
    final sortedCats = provider.categories
        .where((c) => catIds.contains(c.id))
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    for (final cat in sortedCats) {
      final cnt = items.where((i) => i.categoryId == cat.id).length;
      tabs.add(_TabD(cat.id, cat.name, cnt));
    }
    return tabs;
  }

  /// 按 sortOrder 排序的二级分类列表
  List<_TabD> _buildSubTabs(ItemProvider provider) {
    if (_selectedParent == null) return [];
    final items = provider.items;
    final subs = provider.subCategories
        .where((c) => c.parentId == _selectedParent)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return subs.map((sub) {
      final cnt = items.where((i) => i.subCategoryId == sub.id).length;
      return _TabD(sub.id, sub.name, cnt);
    }).toList();
  }

  /// 长按弹出拖拽排序面板
  Future<void> _showReorderSheet(ItemProvider provider) async {
    // 只对有一级分类的情况
    final cats = provider.categories.toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    if (cats.isEmpty) return;

    final result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _CategoryReorderSheet(categories: cats),
    );

    if (result != null && result.length == cats.length) {
      await provider.reorderCategories(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;
    final parentTabs = _buildParentTabs(provider);
    final subTabs = _buildSubTabs(provider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 一级标签行
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: parentTabs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (_, i) {
              final t = parentTabs[i];
              final sel = t.id == null
                  ? _selectedParent == null && provider.filterCategoryId == null
                  : _selectedParent == t.id;
              return GestureDetector(
                onLongPress: t.id != null
                    ? () => _showReorderSheet(provider)
                    : null,
                onTap: () {
                  setState(() {
                    if (t.id == null) {
                      _selectedParent = null;
                      provider.setFilterCategory(null);
                      provider.setFilterSubCategory(null);
                    } else {
                      _selectedParent = t.id;
                      provider.setFilterCategory(t.id);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: sel ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: sel ? null : Border.all(color: AppColors.border),
                  ),
                  child: Text('${t.label}(${t.count})',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: sel ? Colors.white : AppColors.textPrimary)),
                ),
              );
            },
          ),
        ),
        // 二级标签行
        if (subTabs.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: SizedBox(
              height: 32,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: subTabs.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (_, i) {
                  final t = subTabs[i];
                  final sel = provider.filterSubCategoryId == t.id;
                  return GestureDetector(
                    onTap: () => provider.setFilterSubCategory(sel ? null : t.id),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: sel ? AppColors.primaryLight : AppColors.bgSecondary,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text('${t.label}(${t.count})',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: sel ? AppColors.primary : AppColors.textSecondary)),
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}
// ========== 分类拖拽排序面板 ==========
class _CategoryReorderSheet extends StatefulWidget {
  final List<Category> categories;
  const _CategoryReorderSheet({required this.categories});

  @override
  State<_CategoryReorderSheet> createState() => _CategoryReorderSheetState();
}

class _CategoryReorderSheetState extends State<_CategoryReorderSheet> {
  late List<Category> _cats;

  @override
  void initState() {
    super.initState();
    _cats = List.from(widget.categories);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(width: 36, height: 4,
            decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 16),
          const Text('拖拽排序分类', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('长按拖拽调整分类显示顺序', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.55,
            ),
            child: ReorderableListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _cats.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex--;
                  final item = _cats.removeAt(oldIndex);
                  _cats.insert(newIndex, item);
                });
              },
              itemBuilder: (_, i) {
                final cat = _cats[i];
                return ListTile(
                  key: ValueKey(cat.id),
                  leading: Icon(Icons.drag_handle, color: AppColors.textHint),
                  title: Text(cat.name, style: const TextStyle(fontSize: 15)),
                  trailing: Text('顺序 ${i + 1}', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, _cats.map((c) => c.id).toList()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('完成', style: TextStyle(fontSize: 16)),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _TabD { final String? id; final String label; final int count; _TabD(this.id, this.label, this.count); }

// ========== 物品列表 (新 UI) ==========
class _ItemList extends StatelessWidget {
  final List<Item> items;
  const _ItemList({required this.items});
  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.inventory_2_outlined, size: 64, color: AppColors.textHint), const SizedBox(height: 16), Text('还没有物品，点击 + 添加', style: TextStyle(color: AppColors.textSecondary, fontSize: 16))]));
    return ListView.separated(padding: const EdgeInsets.only(bottom: 100), itemCount: items.length, separatorBuilder: (_,__) => const Divider(height: 1, indent: 88, endIndent: 16), itemBuilder: (_, i) => _ItemCard(item: items[i], onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ItemDetailScreen(itemId: items[i].id)))));
  }
}

class _ItemCard extends StatelessWidget {
  final Item item;
  final VoidCallback onTap;
  const _ItemCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // 左侧图片
        ClipRRect(borderRadius: BorderRadius.circular(8), child: item.imagePaths.isNotEmpty ? buildSmartImage(item.imagePaths.first, width: 64, height: 64) : _placeholder()),
        const SizedBox(width: 12),
        // 中间信息
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // 第一行：名称 + 状态
          Row(children: [
            Expanded(child: Text(item.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis)),
            Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), decoration: BoxDecoration(color: AppColors.accent.withAlpha(25), borderRadius: BorderRadius.circular(10)), child: const Text('使用中', style: TextStyle(fontSize: 11, color: AppColors.accent, fontWeight: FontWeight.w600))),
          ]),
          const SizedBox(height: 2),
          // 使用天数 + 日均成本
          if (item.usageDays > 0 || item.dailyCost != null)
            Padding(padding: const EdgeInsets.only(top: 4), child: Row(children: [
              if (item.usageDays > 0) Text(item.usageText, style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              if (item.dailyCost != null) ...[const SizedBox(width: 10), Text('日均${formatDailyCost(item.dailyCost)}', style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w500))],
            ])),
          const SizedBox(height: 6),
          // 购买渠道 + 过保时间
          Row(children: [
            if (item.purchaseChannel != null) ...[Icon(Icons.store_outlined, size: 12, color: AppColors.textHint), const SizedBox(width: 3), Text(item.purchaseChannel!, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)), const SizedBox(width: 12)],
            if (item.warrantyExpiry != null) ...[Icon(Icons.shield_outlined, size: 12, color: AppColors.textHint), const SizedBox(width: 3), Text('${_warrantyText(item.warrantyExpiry!)}后过保', style: TextStyle(fontSize: 12, color: AppColors.textSecondary))],
          ]),
        ])),
        // 右侧总价
        if (item.totalCost != null) ...[
          const SizedBox(width: 8),
          Center(child: Text(formatPrice(item.totalCost), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primary))),
        ],
      ])),
    );
  }

  Widget _placeholder() => Container(width: 64, height: 64, decoration: BoxDecoration(color: AppColors.bgSecondary, borderRadius: BorderRadius.circular(8)), child: Icon(Icons.photo_library_outlined, size: 24, color: AppColors.textHint));

  String _warrantyText(DateTime d) {
    final days = d.difference(DateTime.now()).inDays;
    if (days < 0) return '已过期'; if (days < 30) return '${days}天'; if (days < 365) return '${days ~/ 30}个月'; return '${days}天';
  }
}

// ========== 瀑布流 ==========
class _ItemGrid extends StatelessWidget {
  final List<Item> items;
  const _ItemGrid({required this.items});
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.72, crossAxisSpacing: 10, mainAxisSpacing: 10),
      itemCount: items.length,
      itemBuilder: (_, i) => GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ItemDetailScreen(itemId: items[i].id))),
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: items[i].imagePaths.isNotEmpty ? buildSmartImage(items[i].imagePaths.first, fit: BoxFit.cover) : Container(color: AppColors.bgSecondary, child: const Center(child: Icon(Icons.photo, size: 32, color: AppColors.textHint)))),
            Padding(padding: const EdgeInsets.all(10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(items[i].name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text(formatPrice(items[i].price), style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary, fontSize: 12)),
              if (items[i].dailyCost != null) Text('日均${formatDailyCost(items[i].dailyCost)}', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ])),
          ]),
        ),
      ),
    );
  }
}

class _ItemCompact extends StatelessWidget {
  final List<Item> items;
  const _ItemCompact({required this.items});
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: items.length,
      separatorBuilder: (_,__) => const Divider(height: 1, indent: 16),
      itemBuilder: (_, i) => ListTile(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ItemDetailScreen(itemId: items[i].id))),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        title: Text(items[i].name, style: const TextStyle(fontSize: 15)),
        subtitle: Text(items[i].usageText, style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        trailing: Text(formatPrice(items[i].price), style: TextStyle(fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.w500)),
      ),
    );
  }
}
