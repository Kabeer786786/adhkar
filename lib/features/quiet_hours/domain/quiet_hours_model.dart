import 'package:flutter/material.dart';

class QuietHours {
  final String id;
  final String title;
  final String? description;
  final int startHour; // 0..23
  final int startMinute; // 0..59
  final int endHour; // 0..23
  final int endMinute; // 0..59
  final bool enabled;
  final bool repeatDaily;
  final List<int> weekdays; // 1=Mon, 2=Tue, ..., 7=Sun
  final int? originalDndFilter; // Captured system DND filter prior to activation
  final bool adhkarOwnsDnd; // True if Adhkar initiated active DND state
  final DateTime createdAt;
  final DateTime updatedAt;

  const QuietHours({
    required this.id,
    this.title = 'Quiet Hours',
    this.description,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
    this.enabled = true,
    this.repeatDaily = true,
    this.weekdays = const [1, 2, 3, 4, 5, 6, 7],
    this.originalDndFilter,
    this.adhkarOwnsDnd = false,
    required this.createdAt,
    required this.updatedAt,
  });

  TimeOfDay get startTime => TimeOfDay(hour: startHour, minute: startMinute);
  TimeOfDay get endTime => TimeOfDay(hour: endHour, minute: endMinute);

  bool get isOvernight {
    if (startHour > endHour) return true;
    if (startHour == endHour && startMinute > endMinute) return true;
    return false;
  }

  /// Calculates whether [now] falls within the Quiet Hours active period.
  bool isTimeInQuietHours(DateTime now) {
    if (!enabled) return false;

    final nowMinutes = now.hour * 60 + now.minute;
    final startMinutes = startHour * 60 + startMinute;
    final endMinutes = endHour * 60 + endMinute;

    if (startMinutes == endMinutes) {
      return false;
    }

    if (!isOvernight) {
      // Same-day range (e.g. 13:15 to 13:40)
      if (!repeatDaily && !weekdays.contains(now.weekday)) {
        return false;
      }
      return nowMinutes >= startMinutes && nowMinutes < endMinutes;
    } else {
      // Overnight range (e.g. 22:00 to 06:00)
      if (nowMinutes >= startMinutes) {
        // Evening part (today)
        if (!repeatDaily && !weekdays.contains(now.weekday)) {
          return false;
        }
        return true;
      } else if (nowMinutes < endMinutes) {
        // Morning part (started previous evening)
        final prevWeekday = now.weekday == 1 ? 7 : now.weekday - 1;
        if (!repeatDaily && !weekdays.contains(prevWeekday)) {
          return false;
        }
        return true;
      }
      return false;
    }
  }

  /// Calculates the next [DateTime] when Quiet Hours start should trigger from [from].
  DateTime getNextStartOccurrence(DateTime from) {
    DateTime candidate = DateTime(
      from.year,
      from.month,
      from.day,
      startHour,
      startMinute,
    );

    if (candidate.isBefore(from) || candidate.isAtSameMomentAs(from)) {
      candidate = candidate.add(const Duration(days: 1));
    }

    if (!repeatDaily) {
      while (!weekdays.contains(candidate.weekday)) {
        candidate = candidate.add(const Duration(days: 1));
      }
    }

    return candidate;
  }

  /// Calculates the next [DateTime] when Quiet Hours end should trigger from [from].
  DateTime getNextEndOccurrence(DateTime from) {
    DateTime candidate = DateTime(
      from.year,
      from.month,
      from.day,
      endHour,
      endMinute,
    );

    if (!isOvernight) {
      if (candidate.isBefore(from) || candidate.isAtSameMomentAs(from)) {
        candidate = candidate.add(const Duration(days: 1));
      }
    } else {
      final nowMinutes = from.hour * 60 + from.minute;
      final startMinutes = startHour * 60 + startMinute;
      if (nowMinutes >= startMinutes) {
        candidate = candidate.add(const Duration(days: 1));
      } else if (candidate.isBefore(from) || candidate.isAtSameMomentAs(from)) {
        candidate = candidate.add(const Duration(days: 1));
      }
    }

    return candidate;
  }

  QuietHours copyWith({
    String? id,
    String? title,
    String? description,
    int? startHour,
    int? startMinute,
    int? endHour,
    int? endMinute,
    bool? enabled,
    bool? repeatDaily,
    List<int>? weekdays,
    int? originalDndFilter,
    bool? adhkarOwnsDnd,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return QuietHours(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startHour: startHour ?? this.startHour,
      startMinute: startMinute ?? this.startMinute,
      endHour: endHour ?? this.endHour,
      endMinute: endMinute ?? this.endMinute,
      enabled: enabled ?? this.enabled,
      repeatDaily: repeatDaily ?? this.repeatDaily,
      weekdays: weekdays ?? this.weekdays,
      originalDndFilter: originalDndFilter ?? this.originalDndFilter,
      adhkarOwnsDnd: adhkarOwnsDnd ?? this.adhkarOwnsDnd,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'startHour': startHour,
      'startMinute': startMinute,
      'endHour': endHour,
      'endMinute': endMinute,
      'enabled': enabled,
      'repeatDaily': repeatDaily,
      'weekdays': weekdays,
      'originalDndFilter': originalDndFilter,
      'adhkarOwnsDnd': adhkarOwnsDnd,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory QuietHours.fromJson(Map<String, dynamic> json) {
    return QuietHours(
      id: json['id'] as String? ?? 'quiet_hours_${DateTime.now().millisecondsSinceEpoch}',
      title: json['title'] as String? ?? 'Quiet Hours',
      description: json['description'] as String?,
      startHour: json['startHour'] as int? ?? 13,
      startMinute: json['startMinute'] as int? ?? 15,
      endHour: json['endHour'] as int? ?? 13,
      endMinute: json['endMinute'] as int? ?? 40,
      enabled: json['enabled'] as bool? ?? true,
      repeatDaily: json['repeatDaily'] as bool? ?? true,
      weekdays: (json['weekdays'] as List?)?.map((e) => (e as num).toInt()).toList() ??
          [1, 2, 3, 4, 5, 6, 7],
      originalDndFilter: json['originalDndFilter'] as int?,
      adhkarOwnsDnd: json['adhkarOwnsDnd'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  static List<QuietHours> defaultSchedules() {
    final now = DateTime.now();
    return [
      QuietHours(
        id: 'predefined_quiet_fajr',
        title: 'Fajr Quiet Hours',
        description: 'Silence calls and alerts during Fajr prayer time',
        startHour: 5,
        startMinute: 15,
        endHour: 5,
        endMinute: 30,
        enabled: false,
        repeatDaily: true,
        weekdays: const [1, 2, 3, 4, 5, 6, 7],
        createdAt: now,
        updatedAt: now,
      ),
      QuietHours(
        id: 'predefined_quiet_dhuhr',
        title: 'Dhuhr Quiet Hours',
        description: 'Silence calls and alerts during Dhuhr prayer time',
        startHour: 12,
        startMinute: 30,
        endHour: 12,
        endMinute: 45,
        enabled: false,
        repeatDaily: true,
        weekdays: const [1, 2, 3, 4, 5, 6, 7],
        createdAt: now,
        updatedAt: now,
      ),
      QuietHours(
        id: 'predefined_quiet_asr',
        title: 'Asr Quiet Hours',
        description: 'Silence calls and alerts during Asr prayer time',
        startHour: 15,
        startMinute: 45,
        endHour: 16,
        endMinute: 0,
        enabled: false,
        repeatDaily: true,
        weekdays: const [1, 2, 3, 4, 5, 6, 7],
        createdAt: now,
        updatedAt: now,
      ),
      QuietHours(
        id: 'predefined_quiet_maghrib',
        title: 'Maghrib Quiet Hours',
        description: 'Silence calls and alerts during Maghrib prayer time',
        startHour: 18,
        startMinute: 15,
        endHour: 18,
        endMinute: 30,
        enabled: false,
        repeatDaily: true,
        weekdays: const [1, 2, 3, 4, 5, 6, 7],
        createdAt: now,
        updatedAt: now,
      ),
      QuietHours(
        id: 'predefined_quiet_isha',
        title: 'Isha Quiet Hours',
        description: 'Silence calls and alerts during Isha prayer time',
        startHour: 19,
        startMinute: 45,
        endHour: 20,
        endMinute: 0,
        enabled: false,
        repeatDaily: true,
        weekdays: const [1, 2, 3, 4, 5, 6, 7],
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }
}
