import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../models/reminder.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _plugin.initialize(settings);
    _initialized = true;
  }

  /// 根据 reminder 安排一个本地通知
  static Future<void> scheduleReminder(Reminder reminder) async {
    await _plugin.cancel(reminder.id.hashCode);

    final now = DateTime.now();
    final scheduleDt = reminder.remindDate.isAfter(now)
        ? reminder.remindDate
        : now.add(const Duration(minutes: 1));
    final scheduledDate = tz.TZDateTime.from(scheduleDt, tz.local);

    final androidDetails = AndroidNotificationDetails(
      'reminder_channel',
      '物品提醒',
      channelDescription: '保质期、保修、会员到期提醒',
      importance: Importance.high,
      priority: Priority.high,
    );
    final iosDetails = const DarwinNotificationDetails();
    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.zonedSchedule(
      reminder.id.hashCode,
      '⏰ ${reminder.typeLabel}',
      '物品即将到期，点击查看详情',
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// 立即弹出一个通知
  static Future<void> showImmediate(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'general_channel',
      '通用通知',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const details = NotificationDetails(android: androidDetails);
    await _plugin.show(DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title, body, details);
  }

  /// 取消某个 reminder 的通知
  static Future<void> cancelReminder(Reminder reminder) async {
    await _plugin.cancel(reminder.id.hashCode);
  }
}
