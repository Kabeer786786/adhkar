import 'package:flutter/material.dart';

class CustomReminder {
  final String id;
  final String title;
  final int hour; // 0..23
  final int minute; // 0..59
  final bool sound;
  final bool noSound;
  final bool vibration;
  final bool notification;
  final String soundType; // e.g. 'Azaan', 'Ringtone', 'Default Notification'
  final List<int> selectedDays; // 1=Mon ... 7=Sun
  final bool isEnabled;
  final DateTime createdAt;

  const CustomReminder({
    required this.id,
    required this.title,
    required this.hour,
    required this.minute,
    this.sound = true,
    this.noSound = false,
    this.vibration = true,
    this.notification = true,
    this.soundType = 'Azaan',
    this.selectedDays = const [1, 2, 3, 4, 5, 6, 7],
    this.isEnabled = true,
    required this.createdAt,
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
    if (selectedDays.length == 7) return 'Everyday';
    if (selectedDays.length == 5 &&
        selectedDays.contains(1) &&
        selectedDays.contains(2) &&
        selectedDays.contains(3) &&
        selectedDays.contains(4) &&
        selectedDays.contains(5)) {
      return 'Weekdays (Mon-Fri)';
    }
    if (selectedDays.length == 2 &&
        selectedDays.contains(6) &&
        selectedDays.contains(7)) {
      return 'Weekends (Sat-Sun)';
    }
    const daysMap = {
      1: 'Mon',
      2: 'Tue',
      3: 'Wed',
      4: 'Thu',
      5: 'Fri',
      6: 'Sat',
      7: 'Sun',
    };
    final sorted = List<int>.from(selectedDays)..sort();
    return sorted.map((d) => daysMap[d] ?? '').join(', ');
  }

  CustomReminder copyWith({
    String? id,
    String? title,
    int? hour,
    int? minute,
    bool? sound,
    bool? noSound,
    bool? vibration,
    bool? notification,
    String? soundType,
    List<int>? selectedDays,
    bool? isEnabled,
    DateTime? createdAt,
  }) {
    return CustomReminder(
      id: id ?? this.id,
      title: title ?? this.title,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      sound: sound ?? this.sound,
      noSound: noSound ?? this.noSound,
      vibration: vibration ?? this.vibration,
      notification: notification ?? this.notification,
      soundType: soundType ?? this.soundType,
      selectedDays: selectedDays ?? this.selectedDays,
      isEnabled: isEnabled ?? this.isEnabled,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'hour': hour,
      'minute': minute,
      'sound': sound,
      'noSound': noSound,
      'vibration': vibration,
      'notification': notification,
      'soundType': soundType,
      'selectedDays': selectedDays,
      'isEnabled': isEnabled,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory CustomReminder.fromJson(Map<String, dynamic> json) {
    return CustomReminder(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Reminder',
      hour: json['hour'] as int? ?? 8,
      minute: json['minute'] as int? ?? 0,
      sound: json['sound'] as bool? ?? true,
      noSound: json['noSound'] as bool? ?? false,
      vibration: json['vibration'] as bool? ?? true,
      notification: json['notification'] as bool? ?? true,
      soundType: json['soundType'] as String? ?? 'Azaan',
      selectedDays: (json['selectedDays'] as List<dynamic>?)
              ?.map((e) => (e is num) ? e.toInt() : int.tryParse(e.toString()) ?? 1)
              .toList() ??
          const [1, 2, 3, 4, 5, 6, 7],
      isEnabled: json['isEnabled'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }
}
