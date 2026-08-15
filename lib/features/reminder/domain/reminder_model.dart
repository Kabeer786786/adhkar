import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum ReminderFrequency {
  once,
  daily,
  weekly,
  monthly,
  custom,
}

extension ReminderFrequencyExtension on ReminderFrequency {
  String get displayName {
    switch (this) {
      case ReminderFrequency.once:
        return 'Once';
      case ReminderFrequency.daily:
        return 'Daily';
      case ReminderFrequency.weekly:
        return 'Weekly';
      case ReminderFrequency.monthly:
        return 'Monthly';
      case ReminderFrequency.custom:
        return 'Custom Days';
    }
  }
}

enum AlarmDuration {
  seconds5,
  seconds10,
  seconds15,
  seconds30,
  minute1,
  minutes2,
  minutes5,
}

extension AlarmDurationExtension on AlarmDuration {
  int get inSeconds {
    switch (this) {
      case AlarmDuration.seconds5:
        return 5;
      case AlarmDuration.seconds10:
        return 10;
      case AlarmDuration.seconds15:
        return 15;
      case AlarmDuration.seconds30:
        return 30;
      case AlarmDuration.minute1:
        return 60;
      case AlarmDuration.minutes2:
        return 120;
      case AlarmDuration.minutes5:
        return 300;
    }
  }

  String get displayName {
    switch (this) {
      case AlarmDuration.seconds5:
        return '5 Seconds';
      case AlarmDuration.seconds10:
        return '10 Seconds';
      case AlarmDuration.seconds15:
        return '15 Seconds';
      case AlarmDuration.seconds30:
        return '30 Seconds';
      case AlarmDuration.minute1:
        return '1 Minute';
      case AlarmDuration.minutes2:
        return '2 Minutes';
      case AlarmDuration.minutes5:
        return '5 Minutes';
    }
  }
}

class CustomReminder {
  final String id;
  final String title;
  final String? description;
  final int hour; // 0..23
  final int minute; // 0..59
  final DateTime? startDate;
  final ReminderFrequency frequency;
  final List<int> customDays; // 1=Mon, 2=Tue, ..., 7=Sun
  final AlarmDuration duration;
  final bool soundEnabled;
  final String? soundType; // e.g. Makkah Azaan, Madinah Azaan, Default Ringtone, etc.
  final bool vibrationEnabled;
  final bool notificationEnabled;
  final bool isEnabled;
  final String? turnedOffDate; // YYYY-MM-DD when skipped today
  final DateTime createdAt;
  final DateTime updatedAt;
  final String timezone;

  const CustomReminder({
    required this.id,
    required this.title,
    this.description,
    required this.hour,
    required this.minute,
    this.startDate,
    this.frequency = ReminderFrequency.daily,
    this.customDays = const [1, 2, 3, 4, 5, 6, 7],
    this.duration = AlarmDuration.seconds30,
    this.soundEnabled = true,
    this.soundType = 'Makkah Azaan',
    this.vibrationEnabled = true,
    this.notificationEnabled = true,
    this.isEnabled = true,
    this.turnedOffDate,
    required this.createdAt,
    required this.updatedAt,
    required this.timezone,
  });

  TimeOfDay get timeOfDay => TimeOfDay(hour: hour, minute: minute);

  String get formattedTime {
    final tod = timeOfDay;
    final hour12 = tod.hourOfPeriod == 0 ? 12 : tod.hourOfPeriod;
    final minuteStr = tod.minute.toString().padLeft(2, '0');
    final period = tod.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour12:$minuteStr $period';
  }

  String get formattedDays {
    if (frequency == ReminderFrequency.once) {
      if (startDate != null) {
        return DateFormat('dd MMM yyyy').format(startDate!);
      }
      return DateFormat('dd MMM yyyy').format(DateTime.now());
    }
    if (frequency == ReminderFrequency.daily) return 'Every day';
    if (frequency == ReminderFrequency.monthly) return 'Monthly';

    if (customDays.length == 7) return 'Every day';
    if (customDays.length == 5 &&
        customDays.contains(1) &&
        customDays.contains(2) &&
        customDays.contains(3) &&
        customDays.contains(4) &&
        customDays.contains(5)) {
      return 'Weekdays';
    }
    if (customDays.length == 2 &&
        customDays.contains(6) &&
        customDays.contains(7)) {
      return 'Weekends';
    }

    final map = {
      1: 'Mon',
      2: 'Tue',
      3: 'Wed',
      4: 'Thu',
      5: 'Fri',
      6: 'Sat',
      7: 'Sun',
    };

    final sorted = List<int>.from(customDays)..sort();
    return sorted.map((d) => map[d]!).join(', ');
  }

  bool isTurnedOffFor(DateTime date) {
    if (turnedOffDate == null) return false;
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    return turnedOffDate == dateStr;
  }

  /// Calculate next occurrence of this reminder from [now]
  DateTime? calculateNextOccurrence(DateTime now) {
    if (!isEnabled) return null;
    if (isTurnedOffFor(now)) {
      now = DateTime(now.year, now.month, now.day + 1, 0, 0);
    }

    if (frequency == ReminderFrequency.once) {
      final targetDate = startDate ?? now;
      final candidate = DateTime(
        targetDate.year,
        targetDate.month,
        targetDate.day,
        hour,
        minute,
      );

      if (candidate.isAfter(now)) {
        return candidate;
      } else {
        return null; // Past once reminder
      }
    }

    DateTime candidate = DateTime(
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (candidate.isBefore(now) || candidate.isAtSameMomentAs(now)) {
      candidate = candidate.add(const Duration(days: 1));
    }

    if (frequency == ReminderFrequency.daily) {
      return candidate;
    }

    if (frequency == ReminderFrequency.custom ||
        frequency == ReminderFrequency.weekly) {
      while (!customDays.contains(candidate.weekday)) {
        candidate = candidate.add(const Duration(days: 1));
      }
      return candidate;
    }

    if (frequency == ReminderFrequency.monthly) {
      final targetDay = startDate?.day ?? candidate.day;
      while (candidate.day != targetDay) {
        candidate = candidate.add(const Duration(days: 1));
      }
      return candidate;
    }

    return candidate;
  }

  CustomReminder copyWith({
    String? id,
    String? title,
    String? description,
    int? hour,
    int? minute,
    DateTime? startDate,
    ReminderFrequency? frequency,
    List<int>? customDays,
    AlarmDuration? duration,
    bool? soundEnabled,
    String? soundType,
    bool? vibrationEnabled,
    bool? notificationEnabled,
    bool? isEnabled,
    String? turnedOffDate,
    bool clearTurnedOffDate = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? timezone,
  }) {
    return CustomReminder(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      startDate: startDate ?? this.startDate,
      frequency: frequency ?? this.frequency,
      customDays: customDays ?? this.customDays,
      duration: duration ?? this.duration,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      soundType: soundType ?? this.soundType,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
      isEnabled: isEnabled ?? this.isEnabled,
      turnedOffDate: clearTurnedOffDate
          ? null
          : (turnedOffDate ?? this.turnedOffDate),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      timezone: timezone ?? this.timezone,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'hour': hour,
      'minute': minute,
      'startDate': startDate?.toIso8601String(),
      'frequency': frequency.name,
      'customDays': customDays,
      'duration': duration.name,
      'soundEnabled': soundEnabled,
      'soundType': soundType,
      'vibrationEnabled': vibrationEnabled,
      'notificationEnabled': notificationEnabled,
      'isEnabled': isEnabled,
      'turnedOffDate': turnedOffDate,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'timezone': timezone,
    };
  }

  factory CustomReminder.fromJson(Map<String, dynamic> json) {
    return CustomReminder(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      hour: json['hour'] as int,
      minute: json['minute'] as int,
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'] as String)
          : null,
      frequency: ReminderFrequency.values.firstWhere(
        (e) => e.name == json['frequency'],
        orElse: () => ReminderFrequency.daily,
      ),
      customDays:
          (json['customDays'] as List?)?.map((e) => (e as num).toInt()).toList() ??
              const [1, 2, 3, 4, 5, 6, 7],
      duration: AlarmDuration.values.firstWhere(
        (e) => e.name == json['duration'],
        orElse: () => AlarmDuration.seconds30,
      ),
      soundEnabled: json['soundEnabled'] as bool? ?? true,
      soundType: json['soundType'] as String? ?? 'Makkah Azaan',
      vibrationEnabled: json['vibrationEnabled'] as bool? ?? true,
      notificationEnabled: json['notificationEnabled'] as bool? ?? true,
      isEnabled: json['isEnabled'] as bool? ?? true,
      turnedOffDate: json['turnedOffDate'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      timezone: json['timezone'] as String? ?? 'UTC',
    );
  }
}
