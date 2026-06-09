import 'package:flutter/material.dart';
import '../models/item.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

enum DisplayMode { list, waterfall, minimal }

class ItemCard extends StatelessWidget {
  final Item item;
  final DisplayMode mode;
  final VoidCallback? onTap;

  const ItemCard({
    super.key,
    required this.item,
    required this.mode,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    switch (mode) {
      case DisplayMode.list:
        return _buildListCard(context);
      case DisplayMode.waterfall:
        return _buildWaterfallCard(context);
      case DisplayMode.minimal:
        return _buildMinimalCard(context);
    }
  }

  // ---------- 列表模式 ----------
  Widget _buildListCard(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // 缩略图或占位
              _thumbnail(60),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (item.purchaseDate != null) ...[
                          Icon(Icons.calendar_today, size: 12, color: AppColors.textHint),
                          const SizedBox(width: 4),
                          Text(formatDate(item.purchaseDate),
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          const SizedBox(width: 12),
                        ],
                        Text(formatPrice(item.price),
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    _statusBadges(),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textHint),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- 瀑布流模式 ----------
  Widget _buildWaterfallCard(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 大图区域
            Expanded(
              flex: 3,
              child: item.imagePaths.isNotEmpty
                  ? Image.asset(item.imagePaths.first,
                      fit: BoxFit.cover, width: double.infinity)
                  : Container(
                      color: AppColors.bgSecondary,
                      child: Center(
                        child: Icon(Icons.inventory_2_outlined,
                            size: 40, color: AppColors.textHint),
                      ),
                    ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(formatPrice(item.price),
                        style:
                            TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary)),
                    const Spacer(),
                    _statusBadges(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- 极简模式 ----------
  Widget _buildMinimalCard(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: _thumbnail(44),
      title: Text(item.name, style: const TextStyle(fontSize: 15)),
      subtitle: Text(formatPrice(item.price),
          style: TextStyle(color: AppColors.primary, fontSize: 13)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (item.isLowStock)
            const Icon(Icons.warning_amber, size: 16, color: AppColors.danger),
          if (item.hasExpiryWarning)
            const Icon(Icons.timer, size: 16, color: AppColors.warning),
        ],
      ),
    );
  }

  // ---------- 缩略图 ----------
  Widget _thumbnail(double size) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: item.imagePaths.isNotEmpty
          ? Image.asset(item.imagePaths.first,
              width: size, height: size, fit: BoxFit.cover)
          : Container(
              width: size,
              height: size,
              color: AppColors.bgSecondary,
              child: Icon(Icons.photo_library_outlined, size: size * 0.4, color: AppColors.textHint),
            ),
    );
  }

  // ---------- 状态徽章 ----------
  Widget _statusBadges() {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        if (item.isLowStock)
          _badge('库存不足', AppColors.danger),
        if (item.hasExpiryWarning)
          _badge('即将到期', AppColors.warning),
        if (item.daysUntilExpiry != null && item.daysUntilExpiry! <= 7 && item.daysUntilExpiry! >= 0)
          _badge('${item.daysUntilExpiry}天后到期', AppColors.danger),
        if (item.stock > 0 && !item.isLowStock)
          _badge('库存 ${item.stock}', AppColors.accent),
      ],
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text,
          style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
    );
  }
}
