import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/item.dart';
import '../providers/item_provider.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ItemProvider>();
    final items = provider.items;
    final totalValue = items.fold(0.0, (s, i) => s + (i.totalCost ?? 0));
    final totalDaily = items.fold(0.0, (s, i) => s + (i.dailyCost ?? 0));
    final categories = provider.categories;

    if (items.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('统计')),
        body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.bar_chart_outlined, size: 64, color: AppColors.textHint), const SizedBox(height: 16), Text('暂无数据', style: TextStyle(color: AppColors.textSecondary, fontSize: 16))])),
      );
    }

    // 按分类分组
    final catMap = <String, List<Item>>{};
    for (final i in items) {
      catMap.putIfAbsent(i.categoryId, () => []).add(i);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('统计')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        // ---- 概览卡片 ----
        Row(children: [
          _card('总价值', formatPrice(totalValue), Icons.monetization_on, AppColors.primary),
          const SizedBox(width: 10),
          _card('物品数量', '${items.length}', Icons.inventory_2, AppColors.accent),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          _card('日均成本', formatPrice(totalDaily), Icons.trending_down, AppColors.warning),
          const SizedBox(width: 10),
          _card('分类数', '${categories.length}', Icons.category, AppColors.info),
        ]),
        const SizedBox(height: 20),

        // ---- 分类分布 ----
        if (catMap.length > 1) ...[
          const Text('分类分布', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: PieChart(PieChartData(
              sections: catMap.entries.map((e) {
                final cat = categories.where((c) => c.id == e.key).firstOrNull;
                final colors = [AppColors.primary, AppColors.accent, AppColors.warning, AppColors.info, AppColors.danger, const Color(0xFFBA68C8)];
                final idx = catMap.keys.toList().indexOf(e.key);
                return PieChartSectionData(
                  value: e.value.length.toDouble(),
                  title: '${e.value.length}',
                  radius: 50,
                  color: colors[idx % colors.length],
                  titleStyle: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                );
              }).toList(),
              centerSpaceRadius: 30,
            )),
          ),
          const SizedBox(height: 8),
          ...catMap.entries.map((e) {
            final cat = categories.where((c) => c.id == e.key).firstOrNull;
            final totalPrice = e.value.fold(0.0, (s, i) => s + (i.totalCost ?? 0));
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(children: [
                Container(width: 12, height: 12, decoration: BoxDecoration(color: _catColor(catMap.keys.toList().indexOf(e.key)), borderRadius: BorderRadius.circular(3))),
                const SizedBox(width: 8),
                Text(cat?.name ?? e.key, style: const TextStyle(fontSize: 14)),
                const Spacer(),
                Text('${e.value.length}件  ${formatPrice(totalPrice)}', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              ]),
            );
          }),
          const SizedBox(height: 20),
        ],

        // ---- 物品日均成本排行 ----
        Row(children: [const Text('日均成本 TOP', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)), const Spacer(), Text('${items.length}件物品', style: TextStyle(fontSize: 13, color: AppColors.textSecondary))]),
        const SizedBox(height: 10),
        ..._topDailyItems(items),

        // ---- 月度花费 ----
        if (items.any((i) => i.purchaseDate != null && i.totalCost != null)) ...[
          const SizedBox(height: 24),
          const Text('月度花费', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _MonthlyChart(items: items),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 40),
      ]),
    );
  }

  List<Widget> _topDailyItems(List<Item> items) {
    final sorted = items.where((i) => i.dailyCost != null).toList()
      ..sort((a, b) => b.dailyCost!.compareTo(a.dailyCost!));
    return sorted.take(10).map((i) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Text(i.name, style: const TextStyle(fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
        const Spacer(),
        Text(formatDailyCost(i.dailyCost), style: TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w500)),
      ]),
    )).toList();
  }

  Widget _card(String label, String value, IconData icon, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border, width: 0.5)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ]),
    ),
  );

  Color _catColor(int i) {
    const c = [AppColors.primary, AppColors.accent, AppColors.warning, AppColors.info, AppColors.danger, Color(0xFFBA68C8)];
    return c[i % c.length];
  }
}

class _MonthlyChart extends StatelessWidget {
  final List<Item> items;
  const _MonthlyChart({required this.items});

  @override
  Widget build(BuildContext context) {
    // 按月汇总
    final monthMap = <String, double>{};
    for (final i in items) {
      if (i.purchaseDate == null || i.totalCost == null) continue;
      final key = '${i.purchaseDate!.year}-${i.purchaseDate!.month.toString().padLeft(2, '0')}';
      monthMap[key] = (monthMap[key] ?? 0) + i.totalCost!;
    }
    final entries = monthMap.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    final recent = entries.length > 12 ? entries.sublist(entries.length - 12) : entries;
    if (recent.isEmpty) return const SizedBox();

    final maxY = recent.map((e) => e.value).reduce((a, b) => a > b ? a : b) * 1.3;
    return SizedBox(
      height: 160,
      child: BarChart(BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        barGroups: recent.asMap().entries.map((e) => BarChartGroupData(
          x: e.key,
          barRods: [BarChartRodData(toY: e.value.value, color: AppColors.primary, width: 18, borderRadius: BorderRadius.circular(4))],
        )).toList(),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) {
            final idx = v.toInt();
            if (idx < 0 || idx >= recent.length) return const SizedBox();
            final parts = recent[idx].key.split('-');
            return Text('${parts[1]}月', style: const TextStyle(fontSize: 10));
          })),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
      )),
    );
  }
}
