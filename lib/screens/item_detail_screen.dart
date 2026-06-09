import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/item.dart';
import '../models/lending.dart';
import '../providers/item_provider.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../widgets/lending_card.dart';
import 'add_edit_item_screen.dart';

class ItemDetailScreen extends StatelessWidget {
  final String itemId;
  const ItemDetailScreen({super.key, required this.itemId});

  void _confirmDelete(BuildContext context, Item item) {
    showDialog(
      context: context,
      builder: (dctx) => AlertDialog(
        title: const Text('删除物品'),
        content: Text('确定要删除「${item.name}」吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dctx), child: const Text('取消')),
          TextButton(
            onPressed: () async {
              await context.read<ItemProvider>().deleteItem(item.id);
              Navigator.pop(dctx);
              Navigator.pop(context); // back to list
            },
            child: const Text('删除', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ItemProvider>();
    final item = provider.items.where((i) => i.id == itemId).firstOrNull;

    if (item == null) {
      return Scaffold(appBar: AppBar(), body: const Center(child: Text('物品不存在')));
    }

    final lendings = provider.activeLendings.where((l) => l.itemId == itemId).toList();
    final category = provider.categories.where((c) => c.id == item.categoryId).firstOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text(item.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.danger),
            tooltip: '删除物品',
            onPressed: () => _confirmDelete(context, item),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddEditItemScreen(item: item))),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (item.imagePaths.isNotEmpty) _imageGallery(item.imagePaths),
          const SizedBox(height: 12),
          _buildBasicInfo(context, item, category),
          const SizedBox(height: 12),
          _buildCostCard(item),
          const SizedBox(height: 12),
          _buildTimelineCard(item),
          const SizedBox(height: 12),
          if (provider.showInventory) ...[_buildStockCard(context, item, provider), const SizedBox(height: 12)],
          if (provider.showLending) ...[_buildLendingCard(context, item, lendings, provider), const SizedBox(height: 12)],
          if (item.notes != null && item.notes!.isNotEmpty) ...[_buildNotesCard(item), const SizedBox(height: 12)],
          SizedBox(height: 44, child: OutlinedButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddEditItemScreen(item: item))),
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('编辑物品'),
          )),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ---------- 图库 ----------
  Widget _imageGallery(List<String> paths) {
    return SizedBox(
      height: 220,
      child: PageView.builder(
        itemCount: paths.length,
        itemBuilder: (context, index) => GestureDetector(
          onTap: () => _showFullScreenImage(context, paths, index),
          child: ClipRRect(borderRadius: BorderRadius.circular(12), child: _buildImage(paths[index])),
        ),
      ),
    );
  }

  Widget _buildImage(String path) => buildSmartImage(path);

  void _showFullScreenImage(BuildContext context, List<String> paths, int initialIndex) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white, title: Text('${initialIndex + 1}/${paths.length}')),
      body: PageView.builder(
        itemCount: paths.length,
        controller: PageController(initialPage: initialIndex),
        itemBuilder: (_, i) => InteractiveViewer(child: Center(child: _buildImage(paths[i]))),
      ),
    )));
  }

  // ---------- 基本信息 ----------
  Widget _buildBasicInfo(BuildContext context, Item item, dynamic category) {
    return Card(
      child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          if (category != null) ...[Icon(Icons.folder_outlined, size: 18, color: AppColors.primary), const SizedBox(width: 4), Text(category.name, style: TextStyle(color: AppColors.primary)), const Spacer()],
          Text(formatPrice(item.totalCost), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        ]),
        const Divider(height: 24),
        _infoRow('购买渠道', item.purchaseChannel ?? '未设置'),
        if (item.purchaseMethod != null) _infoRow('购买方式', item.purchaseMethod!),
        _infoRow('购买日期', formatDate(item.purchaseDate)),
        if (item.price != null) ...[
          _infoRow('购入价格', formatPrice(item.price)),
          if (item.extraCost != null && item.extraCost! > 0) ...[
            _infoRow('额外费用', formatPrice(item.extraCost)),
            if (item.extraCostNote != null && item.extraCostNote!.isNotEmpty)
              _infoRow('费用说明', item.extraCostNote!),
          ],
        ],
        _infoRow('存放位置', item.location ?? '未设置'),
        _infoRow('规格型号', item.specifications ?? '未设置'),
        _infoRow('标签', item.tagIds.isEmpty ? '无' : ''),
        if (item.tagIds.isNotEmpty) ...[const SizedBox(height: 4), _buildTags(context, item.tagIds)],
      ])),
    );
  }

  Widget _buildTags(BuildContext context, List<String> tagIds) {
    final tags = context.read<ItemProvider>().tags;
    return Wrap(spacing: 6, runSpacing: 4, children: tagIds.map((id) {
      final tag = tags.where((t) => t.id == id).firstOrNull;
      return Chip(
        label: Text(tag?.name ?? '未知', style: const TextStyle(fontSize: 12)),
        backgroundColor: Color(tag?.color ?? 0xFFBDBDBD).withAlpha(40),
        side: BorderSide.none, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, visualDensity: VisualDensity.compact,
      );
    }).toList());
  }

  // ---------- 时间线 ----------
  Widget _buildTimelineCard(Item item) {
    final dates = <_DateEntry>[
      _DateEntry('购买日期', item.purchaseDate, AppColors.primary),
      _DateEntry('保修到期', item.warrantyExpiry, AppColors.warning),
      _DateEntry('保质期到期', item.shelfLifeExpiry, AppColors.danger),
      _DateEntry('会员到期', item.membershipExpiry, AppColors.info),
    ].where((d) => d.date != null).toList();

    return Card(
      child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('⏰ 时间线', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        ...dates.map((d) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [
          Container(width: 4, height: 32, decoration: BoxDecoration(color: d.color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(d.label, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)), Text(formatDate(d.date), style: const TextStyle(fontWeight: FontWeight.w500))]),
          const Spacer(),
          if (d.date != null) _expiryBadge(d.date!),
        ]))),
      ])),
    );
  }

  Widget _expiryBadge(DateTime date) {
    final (days, expired) = daysRemaining(date);
    final color = expired ? AppColors.danger : days <= 7 ? AppColors.danger : days <= 30 ? AppColors.warning : AppColors.accent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(12)),
      child: Text(expired ? '已过期' : '剩${days}天', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
    );
  }

  // ---------- 成本分析 ----------
  Widget _buildCostCard(Item item) {
    return Card(
      child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('💰 成本分析', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _costStat('购买价格', formatPrice(item.price)),
          _costStat('当前残值', formatPrice(item.residualValue)),
          _costStat('日均成本', formatDailyCost(item.dailyCost)),
        ]),
        const Divider(height: 24),
        Row(children: [
          Text('已拥有 ${item.usageDays} 天', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const Spacer(),
          if (item.dailyCost != null) Text('每天花费不到一杯咖啡 ☕', style: TextStyle(color: AppColors.accent, fontSize: 13)),
        ]),
      ])),
    );
  }

  Widget _costStat(String label, String value) => Column(children: [
    Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    const SizedBox(height: 4),
    Text(label, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
  ]);

  // ---------- 库存 ----------
  Widget _buildStockCard(BuildContext context, Item item, ItemProvider provider) {
    return Card(
      child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [const Text('📦 库存', style: TextStyle(fontWeight: FontWeight.w600)), const Spacer(),
          if (item.isLowStock) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: AppColors.danger.withAlpha(25), borderRadius: BorderRadius.circular(12)), child: const Text('库存不足', style: TextStyle(fontSize: 12, color: AppColors.danger, fontWeight: FontWeight.w600)))]),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _stockBtn(Icons.remove, () => provider.quickAdjustStock(item.id, -1)),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: Text('${item.stock}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold))),
          _stockBtn(Icons.add, () => provider.quickAdjustStock(item.id, 1)),
        ]),
        Center(child: Text('低库存预警: ≤ ${item.lowStockThreshold}', style: TextStyle(fontSize: 12, color: AppColors.textSecondary))),
      ])),
    );
  }

  Widget _stockBtn(IconData icon, VoidCallback onTap) => Material(
    color: AppColors.bgSecondary, borderRadius: BorderRadius.circular(20),
    child: InkWell(borderRadius: BorderRadius.circular(20), onTap: onTap, child: Padding(padding: const EdgeInsets.all(8), child: Icon(icon, size: 28, color: AppColors.primary))),
  );

  // ---------- 借出 ----------
  Widget _buildLendingCard(BuildContext context, Item item, List<Lending> lendings, ItemProvider provider) {
    final isLent = lendings.any((l) => l.status == LendStatus.borrowed);
    return Card(
      child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [const Text('🔄 借出管理', style: TextStyle(fontWeight: FontWeight.w600)), const Spacer(),
          if (isLent) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: AppColors.warning.withAlpha(25), borderRadius: BorderRadius.circular(12)), child: const Text('借出中', style: TextStyle(fontSize: 12, color: AppColors.warning, fontWeight: FontWeight.w600)))]),
        const SizedBox(height: 8),
        if (lendings.isNotEmpty) ...lendings.map((l) => LendingCard(lending: l, onReturn: () => provider.markLendingReturned(l.id), onRenew: () => provider.markLendingRenewed(l.id), onLost: () => provider.markLendingLost(l.id)))
        else Padding(padding: const EdgeInsets.all(8), child: Text('暂无借出记录', style: TextStyle(color: AppColors.textHint))),
        const SizedBox(height: 8),
        SizedBox(width: double.infinity, height: 36, child: OutlinedButton.icon(
          onPressed: () => _showAddLendingDialog(context, item, provider),
          icon: const Icon(Icons.add, size: 16), label: const Text('添加借出记录'),
        )),
      ])),
    );
  }

  void _showAddLendingDialog(BuildContext context, Item item, ItemProvider provider) {
    final nameCtrl = TextEditingController(); final contactCtrl = TextEditingController();
    DateTime borrowDate = DateTime.now(); DateTime? expectedReturn;
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(ctx).viewInsets.bottom + 16), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('借出物品', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)), const SizedBox(height: 12),
        TextField(controller: nameCtrl, decoration: const InputDecoration(hintText: '借用人姓名 *')),
        const SizedBox(height: 12),
        TextField(controller: contactCtrl, decoration: const InputDecoration(hintText: '联系方式（选填）'), keyboardType: TextInputType.phone),
        const SizedBox(height: 12),
        Row(children: [const Text('借出日期: '), TextButton(onPressed: () async { final d = await showDatePicker(context: ctx, initialDate: borrowDate, firstDate: DateTime(2000), lastDate: DateTime(2100)); if (d != null) borrowDate = d; }, child: Text(formatDate(borrowDate)))]),
        Row(children: [const Text('预计归还: '), TextButton(onPressed: () async { final d = await showDatePicker(context: ctx, initialDate: DateTime.now().add(const Duration(days: 7)), firstDate: DateTime(2000), lastDate: DateTime(2100)); if (d != null) expectedReturn = d; }, child: Text(formatDate(expectedReturn, fallback: '不设置')))]),
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, height: 44, child: ElevatedButton(
          onPressed: () {
            if (nameCtrl.text.trim().isEmpty) return;
            provider.addLending(Lending(id: const Uuid().v4(), itemId: item.id, borrowerName: nameCtrl.text.trim(), borrowerContact: contactCtrl.text.trim().isEmpty ? null : contactCtrl.text.trim(), borrowDate: borrowDate, expectedReturnDate: expectedReturn));
            Navigator.pop(ctx);
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
          child: const Text('确认借出'),
        )),
        const SizedBox(height: 8),
      ])),
    );
  }

  // ---------- 备注 ----------
  Widget _buildNotesCard(Item item) {
    return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('📝 备注', style: TextStyle(fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      Text(item.notes!, style: TextStyle(color: AppColors.textSecondary)),
    ])));
  }

  Widget _infoRow(String label, String value) {
    return Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 72, child: Text(label, style: TextStyle(fontSize: 13, color: AppColors.textSecondary))),
      Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
    ]));
  }
}

class _DateEntry {
  final String label;
  final DateTime? date;
  final Color color;
  _DateEntry(this.label, this.date, this.color);
}
