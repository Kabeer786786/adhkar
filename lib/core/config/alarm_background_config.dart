import 'package:flutter/material.dart';

/// Centralized configuration for Alarm Screen background wallpapers and gradients.
class AlarmBackgroundConfig {
  static const List<String> imageList = [
    'assets/images/alarm-bgs/bg1.jpg',
    'assets/images/alarm-bgs/bg2.jpg',
    'assets/images/alarm-bgs/bg3.jpg',
    'assets/images/alarm-bgs/bg4.jpg',
    'assets/images/alarm-bgs/bg5.jpg',
    'assets/images/alarm-bgs/bg6.jpg',
    'assets/images/alarm-bgs/bg7.jpg',
    'assets/images/alarm-bgs/bg8.jpg',
    'assets/images/alarm-bgs/bg9.jpg',
    'assets/images/alarm-bgs/bg10.jpg',
    'assets/images/alarm-bgs/bg11.jpg',
    'assets/images/alarm-bgs/bg12.jpg',
    'assets/images/alarm-bgs/bg13.jpg',
    'assets/images/alarm-bgs/bg14.jpg',
  ];

  static const List<Map<String, dynamic>> gradientList = [
    {
      'id': 'emerald_twilight',
      'name': 'Emerald Dusk',
      'colors': [Color(0xFF04160C), Color(0xFF0A2B19), Color(0xFF13452A)],
    },
    {
      'id': 'midnight_aurora',
      'name': 'Midnight Sky',
      'colors': [Color(0xFF090E18), Color(0xFF101F36), Color(0xFF1C385E)],
    },
    {
      'id': 'dark_obsidian',
      'name': 'Obsidian Slate',
      'colors': [Color(0xFF0C0D10), Color(0xFF171A21), Color(0xFF222733)],
    },
    {
      'id': 'royal_amethyst',
      'name': 'Royal Amethyst',
      'colors': [Color(0xFF13091F), Color(0xFF24133B), Color(0xFF381F59)],
    },
    {
      'id': 'mystic_teal',
      'name': 'Mystic Teal',
      'colors': [Color(0xFF061819), Color(0xFF0D3235), Color(0xFF184C4F)],
    },
    {
      'id': 'rain_mist',
      'name': 'Rainy Mist',
      'colors': [Color(0xFF111A20), Color(0xFF1F2D36), Color(0xFF2F424E)],
    },
  ];

  static List<Color> getGradientColors(String id) {
    final found = gradientList.firstWhere(
      (g) => g['id'] == id,
      orElse: () => gradientList.first,
    );
    return (found['colors'] as List).cast<Color>();
  }
}
