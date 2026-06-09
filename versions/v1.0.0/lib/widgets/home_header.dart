import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/item_provider.dart';
import '../utils/constants.dart';

/// 首页顶部的概览条：到期提醒、库存不足、借出待还
class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ItemProvider>();
    final expiring = provider.expiringItems;
    final lowStock = provider.lowStockItems;
    final lendings = provider.activeLendings;

    if (expiring.isEmpty && lowStock.isEmpty && lendings.isEmpty) {
      return const SizedBox(height: 4);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            if (expiring.isNotEmpty)
              _alertChip(
                Icons.timer,
                '${expiring.length} 个物品即将到期',
                AppColors.warning,
                () {},
              ),
            if (lowStock.isNotEmpty) ...[
              const SizedBox(width: 8),
              _alertChip(
                Icons.warning_amber,
                '${lowStock.length} 个物品库存不足',
                AppColors.danger,
                () {},
              ),
            ],
            if (lendings.isNotEmpty) ...[
              const SizedBox(width: 8),
              _alertChip(
                Icons.swap_horiz,
                '${lendings.length} 个物品借出中',
                AppColors.info,
                () {},
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _alertChip(IconData icon, String text, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withAlpha(80), width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(text,
                style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
