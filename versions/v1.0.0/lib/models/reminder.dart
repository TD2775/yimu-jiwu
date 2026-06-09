/// 提醒类型
enum ReminderType { expiry, warranty, membership, lowStock }

/// 提醒模型
class Reminder {
  final String id;
  final String itemId;
  final ReminderType type;
  final DateTime remindDate;
  final bool enabled;
  final int advanceDays; // 提前多少天提醒
  final DateTime createdAt;

  Reminder({
    required this.id,
    required this.itemId,
    required this.type,
    required this.remindDate,
    this.enabled = true,
    this.advanceDays = 7,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  String get typeLabel {
    switch (type) {
      case ReminderType.expiry:
        return '保质期到期';
      case ReminderType.warranty:
        return '保修到期';
      case ReminderType.membership:
        return '会员到期';
      case ReminderType.lowStock:
        return '库存不足';
    }
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'itemId': itemId,
        'type': type.index,
        'remindDate': remindDate.toIso8601String(),
        'enabled': enabled ? 1 : 0,
        'advanceDays': advanceDays,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Reminder.fromMap(Map<String, dynamic> map) => Reminder(
        id: map['id'],
        itemId: map['itemId'],
        type: ReminderType.values[map['type'] ?? 0],
        remindDate: DateTime.parse(map['remindDate']),
        enabled: (map['enabled'] ?? 1) == 1,
        advanceDays: map['advanceDays'] ?? 7,
        createdAt: DateTime.parse(map['createdAt']),
      );
}
