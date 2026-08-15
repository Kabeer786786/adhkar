import 'package:flutter/material.dart';

/// Represents an individual sub-prayer / rak'at unit (e.g. Sunnat, Farz, Nafl, Awabeen, Wajib).
class SubPrayerItem {
  final String id;
  final String title;
  final int rakats;
  final bool isCompleted;

  const SubPrayerItem({
    required this.id,
    required this.title,
    required this.rakats,
    this.isCompleted = false,
  });

  SubPrayerItem copyWith({bool? isCompleted}) {
    return SubPrayerItem(
      id: id,
      title: title,
      rakats: rakats,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

/// Details for a prayer card in the timetable.
class PrayerDetail {
  final String key;
  final String title;
  final String subtitle;
  final IconData icon;
  final DateTime time;
  final List<SubPrayerItem> subPrayers;
  final bool isZawal;

  const PrayerDetail({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.time,
    this.subPrayers = const [],
    this.isZawal = false,
  });
}

/// Sound & Notification configurations for a prayer.
class PrayerNotificationConfig {
  final bool sound;
  final bool noSound;
  final bool vibration;
  final bool notification;
  final String soundType; // 'Makkah Azaan', 'Madinah Azaan', 'Mishary Alafasy Azaan', 'Takbeer', 'Default Notification', 'Ringtone'
  final String? customAudioUrl;
  final List<int> selectedDays; // 1 = Mon ... 7 = Sun

  const PrayerNotificationConfig({
    this.sound = true,
    this.noSound = false,
    this.vibration = true,
    this.notification = true,
    this.soundType = 'Makkah Azaan',
    this.customAudioUrl,
    this.selectedDays = const [1, 2, 3, 4, 5, 6, 7],
  });

  bool get isMuted => noSound || (!sound && !vibration && !notification);

  static const Map<String, String> soundAudioUrls = {
    'Makkah Azaan': 'https://www.islamcan.com/audio/adhan/azan1.mp3',
    'Madinah Azaan': 'https://www.islamcan.com/audio/adhan/azan2.mp3',
    'Mishary Alafasy Azaan': 'https://www.islamcan.com/audio/adhan/azan3.mp3',
    'Takbeer': 'https://www.islamcan.com/audio/adhan/takbeer.mp3',
    'Azaan': 'https://www.islamcan.com/audio/adhan/azan1.mp3',
  };

  String? get resolvedAudioUrl {
    if (customAudioUrl != null && customAudioUrl!.isNotEmpty) {
      return customAudioUrl;
    }
    return soundAudioUrls[soundType];
  }

  PrayerNotificationConfig copyWith({
    bool? sound,
    bool? noSound,
    bool? vibration,
    bool? notification,
    String? soundType,
    String? customAudioUrl,
    List<int>? selectedDays,
  }) {
    return PrayerNotificationConfig(
      sound: sound ?? this.sound,
      noSound: noSound ?? this.noSound,
      vibration: vibration ?? this.vibration,
      notification: notification ?? this.notification,
      soundType: soundType ?? this.soundType,
      customAudioUrl: customAudioUrl ?? this.customAudioUrl,
      selectedDays: selectedDays ?? this.selectedDays,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sound': sound,
      'noSound': noSound,
      'vibration': vibration,
      'notification': notification,
      'soundType': soundType,
      'customAudioUrl': customAudioUrl,
      'selectedDays': selectedDays,
    };
  }

  factory PrayerNotificationConfig.fromJson(Map<String, dynamic> json) {
    return PrayerNotificationConfig(
      sound: json['sound'] as bool? ?? true,
      noSound: json['noSound'] as bool? ?? false,
      vibration: json['vibration'] as bool? ?? true,
      notification: json['notification'] as bool? ?? true,
      soundType: json['soundType'] as String? ?? 'Makkah Azaan',
      customAudioUrl: json['customAudioUrl'] as String?,
      selectedDays: (json['selectedDays'] as List<dynamic>?)
              ?.map((e) => (e is num) ? e.toInt() : int.tryParse(e.toString()) ?? 1)
              .toList() ??
          const [1, 2, 3, 4, 5, 6, 7],
    );
  }
}
