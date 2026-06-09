import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/item.dart';
import '../providers/item_provider.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import 'item_detail_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ItemProvider>();
    final items = provider.items;

    // 只收集有购买日期的物品，按日期分组
    final dayItems = <DateTime, List<Item>>{};
    for (final item in items) {
      if (item.purchaseDate != null) {
        final d = DateTime(item.purchaseDate!.year, item.purchaseDate!.month, item.purchaseDate!.day);
        dayItems.putIfAbsent(d, () => []).add(item);
      }
    }

    // 默认选中今天
    final selected = _selectedDay ?? DateTime.now();
    final strip = (DateTime dt) => DateTime(dt.year, dt.month, dt.day);
    final todaysItems = dayItems[strip(selected)] ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('日历视图')),
      body: Column(children: [
        TableCalendar(
          firstDay: DateTime(2000),
          lastDay: DateTime(2100),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          calendarFormat: CalendarFormat.month,
          eventLoader: (day) {
            final d = strip(day);
            return dayItems[d] ?? [];
          },
          onDaySelected: (sel, foc) => setState(() {
            _selectedDay = sel;
            _focusedDay = foc;
          }),
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(color: AppColors.primary.withAlpha(30), shape: BoxShape.circle),
            selectedDecoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
            markerDecoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
          ),
          headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true, titleTextStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
        const Divider(),
        // 当天购买列表
        if (todaysItems.isEmpty)
          Expanded(child: Center(child: Text('当天无购买记录', style: TextStyle(color: AppColors.textHint))))
        else
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
              itemCount: todaysItems.length,
              separatorBuilder: (_,__) => const Divider(height: 1, indent: 88, endIndent: 16),
              itemBuilder: (_, i) {
                final item = todaysItems[i];
                return InkWell(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ItemDetailScreen(itemId: item.id))),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      ClipRRect(borderRadius: BorderRadius.circular(8), child: item.imagePaths.isNotEmpty ? buildSmartImage(item.imagePaths.first, width: 64, height: 64) : Container(width: 64, height: 64, decoration: BoxDecoration(color: AppColors.bgSecondary, borderRadius: BorderRadius.circular(8)), child: Icon(Icons.shopping_bag_outlined, size: 24, color: AppColors.textHint))),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Expanded(child: Text(item.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis)),
                          Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), decoration: BoxDecoration(color: AppColors.accent.withAlpha(25), borderRadius: BorderRadius.circular(10)), child: const Text('使用中', style: TextStyle(fontSize: 11, color: AppColors.accent, fontWeight: FontWeight.w600))),
                        ]),
                        const SizedBox(height: 2),
                        Row(children: [
                          const Spacer(),
                          if (item.totalCost != null) Text(formatPrice(item.totalCost), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
                        ]),
                        const SizedBox(height: 4),
                        Row(children: [
                          Text(item.usageText, style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                          if (item.dailyCost != null) ...[const SizedBox(width: 8), Text('日均${formatDailyCost(item.dailyCost)}', style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w500))],
                        ]),
                        const SizedBox(height: 6),
                        Row(children: [
                          if (item.purchaseChannel != null) ...[Icon(Icons.store_outlined, size: 12, color: AppColors.textHint), const SizedBox(width: 3), Text(item.purchaseChannel!, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)), const SizedBox(width: 12)],
                          if (item.warrantyExpiry != null) ...[Icon(Icons.shield_outlined, size: 12, color: AppColors.textHint), const SizedBox(width: 3), Text('${_warrantyText(item.warrantyExpiry!)}后过保', style: TextStyle(fontSize: 12, color: AppColors.textSecondary))],
                        ]),
                      ])),
                    ]),
                  ),
                );
              },
            ),
          ),
      ]),
    );
  }

  String _warrantyText(DateTime d) {
    final dayDiff = d.difference(DateTime.now()).inDays;
    if (dayDiff < 0) return '已过期';
    if (dayDiff < 30) return '${dayDiff}天';
    if (dayDiff < 365) return '${(dayDiff / 30).floor()}个月';
    final years = (dayDiff / 365).floor();
    return '${years}年';
  }
}

String formatDate(DateTime? date, {String fallback = '未设置'}) {
  if (date == null) return fallback;
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
