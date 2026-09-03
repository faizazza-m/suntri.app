import 'dart:io' show Platform;
import 'package:flutter/material.dart' show Color;
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  // Mapping hari Indonesia ke weekday Dart (1=Monday ... 7=Sunday)
  static const Map<String, int> _hariToWeekday = {
    'Senin': DateTime.monday,
    'Selasa': DateTime.tuesday,
    'Rabu': DateTime.wednesday,
    'Kamis': DateTime.thursday,
    'Jumat': DateTime.friday,
    'Sabtu': DateTime.saturday,
    'Minggu': DateTime.sunday,
  };

  /// Inisialisasi plugin notifikasi. Panggil sekali di main().
  static Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const linuxSettings =
        LinuxInitializationSettings(defaultActionName: 'Open notification');
    const initSettings = InitializationSettings(
      android: androidSettings,
      linux: linuxSettings,
    );

    await _plugin.initialize(initSettings);

    // Minta izin notifikasi (Android 13+ only)
    if (Platform.isAndroid) {
      final androidImpl = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidImpl?.requestNotificationsPermission();
      await androidImpl?.requestExactAlarmsPermission();
    }

    _initialized = true;
    debugPrint('NotificationService initialized');
  }

  /// Jadwalkan pengingat untuk semua jadwal mengajar guru.
  /// Notifikasi dikirim pada H-1 pukul 19:00 WIB.
  static Future<void> scheduleGuruReminders(
    List<Map<String, dynamic>> schedules,
    String guruId,
  ) async {
    // zonedSchedule hanya tersedia di Android/iOS, skip di desktop
    if (!Platform.isAndroid && !Platform.isIOS) {
      debugPrint('Notification scheduling skipped (not on mobile)');
      return;
    }
    if (!_initialized) await init();

    // Batalkan semua notifikasi lama milik guru ini dulu
    await cancelAllGuruReminders();

    final now = tz.TZDateTime.now(tz.local);

    int notifId = 1000; // base id untuk guru reminders

    for (final schedule in schedules) {
      final String hari = schedule['day'] ?? '';
      final String mapel = schedule['subject'] ?? 'Mengajar';
      final String kelas = schedule['class'] ?? '';
      final String jamMulai = schedule['timeStart'] ?? '';

      final targetWeekday = _hariToWeekday[hari];
      if (targetWeekday == null) continue;

      // Cari tanggal mengajar berikutnya (termasuk minggu ini)
      DateTime teachingDate = _nextOccurrence(now.toLocal(), targetWeekday);

      // Notifikasi dikirim H-1 pukul 19:00
      final reminderDate = teachingDate.subtract(const Duration(days: 1));
      final reminderDateTime = DateTime(
        reminderDate.year,
        reminderDate.month,
        reminderDate.day,
        19, // jam 19:00 WIB
        0,
      );

      // Lewati jika waktu pengingat sudah lewat
      if (reminderDateTime.isBefore(now.toLocal())) {
        // Coba minggu depan
        teachingDate = teachingDate.add(const Duration(days: 7));
        final nextReminder = teachingDate.subtract(const Duration(days: 1));
        final nextReminderDT = DateTime(
          nextReminder.year, nextReminder.month, nextReminder.day, 19, 0);
        if (nextReminderDT.isBefore(now.toLocal())) continue;
        await _scheduleOne(notifId, mapel, kelas, jamMulai, hari, nextReminderDT);
      } else {
        await _scheduleOne(notifId, mapel, kelas, jamMulai, hari, reminderDateTime);
      }

      notifId++;
    }

    debugPrint('Scheduled ${schedules.length} guru reminders');
  }

  static Future<void> _scheduleOne(
    int id,
    String mapel,
    String kelas,
    String jam,
    String hari,
    DateTime scheduledTime,
  ) async {
    final tzScheduled = tz.TZDateTime.from(scheduledTime, tz.local);

    const androidDetails = AndroidNotificationDetails(
      'guru_reminder_channel',
      'Pengingat Jadwal Mengajar',
      channelDescription: 'Notifikasi pengingat jadwal mengajar sehari sebelumnya',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF107B5C),
    );

    try {
      await _plugin.zonedSchedule(
        id,
        '📚 Pengingat Jadwal Besok',
        'Besok $hari: Mengajar $mapel di $kelas pukul $jam',
        tzScheduled,
        const NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    } catch (e) {
      debugPrint('Gagal menjadwalkan notifikasi guru: $e');
    }

    debugPrint('Scheduled notif #$id → $mapel ($hari) at $tzScheduled');
  }

  /// Batalkan semua notifikasi reminder guru (id 1000–1999)
  static Future<void> cancelAllGuruReminders() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    for (int i = 1000; i < 2000; i++) {
      await _plugin.cancel(i);
    }
  }

  /// Hitung tanggal occurrence berikutnya dari weekday tertentu
  static DateTime _nextOccurrence(DateTime from, int targetWeekday) {
    int daysAhead = targetWeekday - from.weekday;
    if (daysAhead < 0) daysAhead += 7;
    return from.add(Duration(days: daysAhead));
  }

  /// Jadwalkan pengingat absensi Musyrif Senin-Sabtu jam 11:00.
  static Future<void> scheduleMusyrifReminders() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    if (!_initialized) await init();

    await cancelAllMusyrifReminders();

    final now = tz.TZDateTime.now(tz.local);
    int notifId = 2000;

    final weekdays = [
      DateTime.monday,
      DateTime.tuesday,
      DateTime.wednesday,
      DateTime.thursday,
      DateTime.friday,
      DateTime.saturday,
    ];

    for (final weekday in weekdays) {
      DateTime notifDate = _nextOccurrence(now.toLocal(), weekday);
      
      const androidDetails = AndroidNotificationDetails(
        'musyrif_reminder_channel',
        'Pengingat Absensi Musyrif',
        channelDescription: 'Notifikasi pengingat absensi harian musyrif',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: Color(0xFF107B5C),
      );

      // 1. Notifikasi 06:00 WIB
      DateTime scheduledDT1 = DateTime(notifDate.year, notifDate.month, notifDate.day, 6, 0);
      if (scheduledDT1.isBefore(now.toLocal())) {
        scheduledDT1 = scheduledDT1.add(const Duration(days: 7));
      }
      try {
        await _plugin.zonedSchedule(
          notifId++,
          '☀️ Selamat Pagi paraa Musyrif!',
          'Awali hari dengan bismillah, semangat mendampingi para santri MTRQ hari ini!',
          tz.TZDateTime.from(scheduledDT1, tz.local),
          const NotificationDetails(android: androidDetails),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
      } catch (e) {
        debugPrint('Gagal menjadwalkan notif musyrif pagi: $e');
      }

      // 2. Notifikasi 10:00 WIB
      DateTime scheduledDT2 = DateTime(notifDate.year, notifDate.month, notifDate.day, 10, 0);
      if (scheduledDT2.isBefore(now.toLocal())) {
        scheduledDT2 = scheduledDT2.add(const Duration(days: 7));
      }
      try {
        await _plugin.zonedSchedule(
          notifId++,
          '📖 Waktu Halaqoh Pertama',
          'Halaqoh sudah dimulai, jangan lupa untuk mencatat absensi dan setoran santri.',
          tz.TZDateTime.from(scheduledDT2, tz.local),
          const NotificationDetails(android: androidDetails),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
      } catch (e) {
        debugPrint('Gagal menjadwalkan notif musyrif siang 1: $e');
      }

      // 3. Notifikasi 13:00 WIB
      DateTime scheduledDT3 = DateTime(notifDate.year, notifDate.month, notifDate.day, 13, 0);
      if (scheduledDT3.isBefore(now.toLocal())) {
        scheduledDT3 = scheduledDT3.add(const Duration(days: 7));
      }
      try {
        await _plugin.zonedSchedule(
          notifId++,
          '✅ Halaqoh Terakhir',
          'Waktunya halaqoh terakhir hari ini! Pastikan semua data setoran dan absensi sudah lengkap, jangan lebih dari abis ashar yakk.',
          tz.TZDateTime.from(scheduledDT3, tz.local),
          const NotificationDetails(android: androidDetails),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
      } catch (e) {
        debugPrint('Gagal menjadwalkan notif musyrif siang 2: $e');
      }
    }
  }

  static Future<void> cancelAllMusyrifReminders() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    for (int i = 2000; i < 2030; i++) {
      await _plugin.cancel(i);
    }
  }
}
