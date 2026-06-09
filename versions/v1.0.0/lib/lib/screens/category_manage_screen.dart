import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/category.dart';
import '../providers/item_provider.dart';
import '../utils/constants.dart';
import 'web_search_screen.dart';

class CategoryManageScreen extends StatefulWidget {
  const CategoryManageScreen({super.key});

  @override
  State<CategoryManageScreen> createState() => _CategoryManageScreenState();
}

class _CategoryManageScreenState extends State<CategoryManageScreen> {
  String? _selectedParentId; // 查看二级分类

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ItemProvider>();
    final cats = _selectedParentId == null
        ? provider.categories
        : provider.subCategories
            .where((c) => c.parentId == _selectedParentId)
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedParentId == null ? '分类管理' : '二级分类'),
        leading: _selectedParentId != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _selectedParentId = null),
              )
            : null,
      ),
      body: ReorderableListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: cats.length,
        onReorder: (oldIndex, newIndex) {
          // 简化处理：just refresh
          setState(() {});
        },
        itemBuilder: (context, index) {
          final cat = cats[index];
          return Card(
            key: Key(cat.id),
            child: ListTile(
              leading: Icon(_iconForCategory(cat.icon)),
              title: Text(cat.name),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (cat.parentId == null)
                    IconButton(
                      icon: const Icon(Icons.subdirectory_arrow_right, size: 20),
                      onPressed: () =>
                          setState(() => _selectedParentId = cat.id),
                      tooltip: '查看二级分类',
                    ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    onPressed: () => _showEditDialog(cat),
                  ),
                  IconButton(
                    icon:
                        const Icon(Icons.delete_outline, size: 20, color: AppColors.danger),
                    onPressed: () => _confirmDelete(cat),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  static const _iconOptions = [
    'folder', 'phone_android', 'kitchen', 'medical_services',
    'diamond', 'card_membership', 'checkroom', 'book',
    'laptop', 'watch', 'headphones', 'camera_alt',
    'chair', 'toys', 'sports_esports', 'flight',
    'local_shipping', 'pets', 'school', 'fitness_center',
  ];

  IconData _iconForCategory(String iconName) {
    switch (iconName) {
      case 'phone_android': return Icons.phone_android;
      case 'kitchen': return Icons.kitchen;
      case 'medical_services': return Icons.medical_services;
      case 'diamond': return Icons.diamond;
      case 'card_membership': return Icons.card_membership;
      case 'checkroom': return Icons.checkroom;
      case 'book': return Icons.book;
      case 'laptop': return Icons.laptop;
      case 'watch': return Icons.watch;
      case 'headphones': return Icons.headphones;
      case 'camera_alt': return Icons.camera_alt;
      case 'chair': return Icons.chair;
      case 'toys': return Icons.toys;
      case 'sports_esports': return Icons.sports_esports;
      case 'flight': return Icons.flight;
      case 'local_shipping': return Icons.local_shipping;
      case 'pets': return Icons.pets;
      case 'school': return Icons.school;
      case 'fitness_center': return Icons.fitness_center;
      default: return Icons.folder;
    }
  }

  void _showAddDialog() {
    final nameCtrl = TextEditingController();
    final isSub = _selectedParentId != null;

    showDialog(
      context: context,
      builder: (ctx) {
        String icon = 'folder';
        return StatefulBuilder(
          builder: (ctx, setSt) => AlertDialog(
            title: Text(isSub ? '添加二级分类' : '添加分类'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(hintText: '分类名称'), autofocus: true),
            const SizedBox(height: 12),
            // 图标选择
            const SizedBox(height: 12), const Text('选择图标', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              ..._iconOptions.map((i) => GestureDetector(
                onTap: () { icon = i; setSt(() {}); },
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: icon == i ? AppColors.primary : AppColors.bgSecondary,
                    borderRadius: BorderRadius.circular(8),
                    border: icon == i ? null : Border.all(color: AppColors.border),
                  ),
                  child: Icon(_iconForCategory(i), size: 20, color: icon == i ? Colors.white : AppColors.textSecondary),
                ),
              )),
              GestureDetector(
                onTap: () => _searchIconsOnline(),
                child: Container(width: 40, height: 40, decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.info, style: BorderStyle.solid)), child: Icon(Icons.search, size: 18, color: AppColors.info)),
              ),
            ]),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              if (nameCtrl.text.trim().isNotEmpty) {
                final cat = Category(
                  id: const Uuid().v4(),
                  name: nameCtrl.text.trim(),
                  icon: icon,
                  parentId: _selectedParentId,
                );
                context.read<ItemProvider>().addCategory(cat);
                Navigator.pop(ctx);
              }
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  });
  }

  void _searchIconsOnline() async {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => WebSearchScreen(searchQuery: 'material icon'),
    ));
  }

  void _showEditDialog(Category cat) {
    final nameCtrl = TextEditingController(text: cat.name);

    showDialog(
      context: context,
      builder: (ctx) {
        String dialogIcon = cat.icon;
        return StatefulBuilder(
          builder: (ctx, setSt) => AlertDialog(
            title: const Text('编辑分类'),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(hintText: '分类名称')),
              const SizedBox(height: 12), const Text('选择图标', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: [
                ..._iconOptions.map((i) => GestureDetector(
                  onTap: () { dialogIcon = i; setSt(() {}); },
                  child: Container(width: 40, height: 40, decoration: BoxDecoration(color: dialogIcon == i ? AppColors.primary : AppColors.bgSecondary, borderRadius: BorderRadius.circular(8), border: dialogIcon == i ? null : Border.all(color: AppColors.border)), child: Icon(_iconForCategory(i), size: 20, color: dialogIcon == i ? Colors.white : AppColors.textSecondary)),
                )),
                GestureDetector(onTap: () => _searchIconsOnline(), child: Container(width: 40, height: 40, decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.info, style: BorderStyle.solid)), child: Icon(Icons.search, size: 18, color: AppColors.info))),
              ]),
            ]),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
              TextButton(onPressed: () {
                if (nameCtrl.text.trim().isNotEmpty) {
                  context.read<ItemProvider>().updateCategory(cat.copyWith(name: nameCtrl.text.trim(), icon: dialogIcon));
                  Navigator.pop(ctx);
                }
              }, child: const Text('保存')),
            ],
          ),
        );
      },
    );
  }

  void _confirmDelete(Category cat) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除分类'),
        content: Text('确定要删除「${cat.name}」吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              context.read<ItemProvider>().deleteCategory(cat.id);
              Navigator.pop(ctx);
            },
            child: const Text('删除', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}
