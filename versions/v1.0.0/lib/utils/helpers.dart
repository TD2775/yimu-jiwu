import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'constants.dart';

/// 格式化日期为 yyyy-MM-dd
String formatDate(DateTime? date, {String fallback = '未设置'}) {
  if (date == null) return fallback;
  return DateFormat('yyyy-MM-dd').format(date);
}

/// 格式化日期为相对时间描述
String formatRelativeDate(DateTime? date) {
  if (date == null) return '未设置';
  final now = DateTime.now();
  final diff = date.difference(now);
  final days = diff.inDays;

  if (days < 0) return '${-days}天前';
  if (days == 0) return '今天';
  if (days == 1) return '明天';
  if (days <= 7) return '$days天后';
  if (days <= 30) return '${days ~/ 7}周后';
  if (days <= 365) return '${days ~/ 30}个月后';
  return '${days ~/ 365}年后';
}

/// 到期剩余天数样式
(int days, bool isExpired) daysRemaining(DateTime? date) {
  if (date == null) return (0, false);
  final diff = date.difference(DateTime.now()).inDays;
  return (diff, diff < 0);
}

/// 格式化金额
String formatPrice(double? price) {
  if (price == null) return '—';
  if (price >= 10000) return '¥${(price / 10000).toStringAsFixed(1)}万';
  return '¥${price.toStringAsFixed(price == price.roundToDouble() ? 0 : 2)}';
}

/// 格式化日均成本
String formatDailyCost(double? cost) {
  if (cost == null) return '—';
  if (cost < 0.01) return '< ¥0.01/天';
  return '¥${cost.toStringAsFixed(2)}/天';
}

/// 智能图片组件：优先本地文件，回退 asset
Widget buildSmartImage(String path, {double? width, double? height, BoxFit fit = BoxFit.cover}) {
  try {
    final file = File(path);
    if (file.existsSync()) {
      return Image.file(file, width: width, height: height, fit: fit,
        errorBuilder: (_, __, ___) => _imgPlaceholder(width, height),
      );
    }
  } catch (_) {}
  try {
    return Image.asset(path, width: width, height: height, fit: fit,
        errorBuilder: (_, __, ___) => _imgPlaceholder(width, height));
  } catch (_) {
    return _imgPlaceholder(width, height);
  }
}

Widget _imgPlaceholder(double? w, double? h) =>
    Container(width: w, height: h, color: AppColors.bgSecondary,
        child: Icon(Icons.photo_library_outlined, size: (w ?? 48) * 0.4, color: AppColors.textHint));
