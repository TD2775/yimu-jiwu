import 'package:flutter/material.dart';
import '../models/lending.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

/// 借出卡片组件
class LendingCard extends StatelessWidget {
  final Lending lending;
  final VoidCallback? onReturn;
  final VoidCallback? onRenew;
  final VoidCallback? onLost;

  const LendingCard({
    super.key,
    required this.lending,
    this.onReturn,
    this.onRenew,
    this.onLost,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = lending.status == LendStatus.borrowed;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isActive ? AppColors.warning.withAlpha(10) : AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(10),
        border: isActive ? Border.all(color: AppColors.warning.withAlpha(40)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: isActive ? AppColors.warning.withAlpha(30) : AppColors.textHint.withAlpha(30),
                child: Icon(
                  isActive ? Icons.person_outline : Icons.check,
                  size: 18,
                  color: isActive ? AppColors.warning : AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(lending.borrowerName,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    Text('借出: ${formatDate(lending.borrowDate)}',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor(lending.status).withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(lending.statusLabel,
                    style: TextStyle(fontSize: 12, color: _statusColor(lending.status))),
              ),
            ],
          ),
          if (lending.expectedReturnDate != null) ...[
            const SizedBox(height: 6),
            Text('预计归还: ${formatDate(lending.expectedReturnDate)}',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
          if (lending.actualReturnDate != null) ...[
            const SizedBox(height: 6),
            Text('实际归还: ${formatDate(lending.actualReturnDate)}',
                style: TextStyle(fontSize: 12, color: AppColors.accent)),
          ],
          // 操作按钮
          if (isActive) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _actionButton('归还', AppColors.accent, onReturn),
                const SizedBox(width: 8),
                _actionButton('续借', AppColors.info, onRenew),
                const SizedBox(width: 8),
                _actionButton('丢失', AppColors.danger, onLost),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _actionButton(String label, Color color, VoidCallback? onTap) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        minimumSize: Size.zero,
      ),
      child: Text(label, style: const TextStyle(fontSize: 13)),
    );
  }

  Color _statusColor(LendStatus status) {
    switch (status) {
      case LendStatus.borrowed:
        return AppColors.warning;
      case LendStatus.returned:
        return AppColors.accent;
      case LendStatus.renewed:
        return AppColors.info;
      case LendStatus.lost:
        return AppColors.danger;
    }
  }
}
