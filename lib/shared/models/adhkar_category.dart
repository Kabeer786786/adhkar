import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';

class CategoryGradientPreset {
  final String name;
  final List<Color> colors;
  final Color textColor;
  final Color accentColor;

  const CategoryGradientPreset({
    required this.name,
    required this.colors,
    required this.textColor,
    required this.accentColor,
  });
}

class AdhkarCategory extends Equatable {
  final String id;
  final String title;
  final String subtitle;
  final String titleAr;
  final String imagePath;
  final int gradientIndex;
  final bool isDefault;

  const AdhkarCategory({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.titleAr,
    required this.imagePath,
    required this.gradientIndex,
    this.isDefault = false,
  });

  static const List<CategoryGradientPreset> gradientPresets = [
    CategoryGradientPreset(
      name: 'Emerald Mint',
      colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
      textColor: Color(0xFF1B5E20),
      accentColor: Color(0xFF2E7D32),
    ),
    CategoryGradientPreset(
      name: 'Golden Dawn',
      colors: [Color(0xFFFFF8E1), Color(0xFFFFECB3)],
      textColor: Color(0xFF6D4C41),
      accentColor: Color(0xFFD9A925),
    ),
    CategoryGradientPreset(
      name: 'Sunset Lavender',
      colors: [Color(0xFFF3E5F5), Color(0xFFE1BEE7)],
      textColor: Color(0xFF4A148C),
      accentColor: Color(0xFF7B1FA2),
    ),
    CategoryGradientPreset(
      name: 'Ocean Breeze',
      colors: [Color(0xFFE0F7FA), Color(0xFFB2EBF2)],
      textColor: Color(0xFF006064),
      accentColor: Color(0xFF00838F),
    ),
    CategoryGradientPreset(
      name: 'Sky Blue',
      colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
      textColor: Color(0xFF0D47A1),
      accentColor: Color(0xFF1565C0),
    ),
    CategoryGradientPreset(
      name: 'Rose Blossom',
      colors: [Color(0xFFFCE4EC), Color(0xFFF8BBD0)],
      textColor: Color(0xFF880E4F),
      accentColor: Color(0xFFC2185B),
    ),
    CategoryGradientPreset(
      name: 'Warm Amber',
      colors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
      textColor: Color(0xFFE65100),
      accentColor: Color(0xFFF57C00),
    ),
    CategoryGradientPreset(
      name: 'Sage Harmony',
      colors: [Color(0xFFF0F4C3), Color(0xFFE6EE9C)],
      textColor: Color(0xFF33691E),
      accentColor: Color(0xFF558B2F),
    ),
    CategoryGradientPreset(
      name: 'Royal Purple',
      colors: [Color(0xFFEDE7F6), Color(0xFFD1C4E9)],
      textColor: Color(0xFF311B92),
      accentColor: Color(0xFF512DA8),
    ),
    CategoryGradientPreset(
      name: 'Soft Peach',
      colors: [Color(0xFFFFF0F0), Color(0xFFFFCDD2)],
      textColor: Color(0xFFB71C1C),
      accentColor: Color(0xFFD32F2F),
    ),
    CategoryGradientPreset(
      name: 'Teal Lagoon',
      colors: [Color(0xFFE0F2F1), Color(0xFFB2DFDB)],
      textColor: Color(0xFF004D40),
      accentColor: Color(0xFF00695C),
    ),
    CategoryGradientPreset(
      name: 'Spring Meadow',
      colors: [Color(0xFFF1F8E9), Color(0xFFDCEDC8)],
      textColor: Color(0xFF33691E),
      accentColor: Color(0xFF689F38),
    ),
    CategoryGradientPreset(
      name: 'Coral Glow',
      colors: [Color(0xFFFFF0F5), Color(0xFFFFD1DC)],
      textColor: Color(0xFF880E4F),
      accentColor: Color(0xFFAD1457),
    ),
    CategoryGradientPreset(
      name: 'Serene Slate',
      colors: [Color(0xFFECEFF1), Color(0xFFCFD8DC)],
      textColor: Color(0xFF263238),
      accentColor: Color(0xFF455A64),
    ),
    CategoryGradientPreset(
      name: 'Desert Sand',
      colors: [Color(0xFFFEF9E7), Color(0xFFFDEBD0)],
      textColor: Color(0xFF7E5109),
      accentColor: Color(0xFFB7950B),
    ),
    CategoryGradientPreset(
      name: 'Mystic Indigo',
      colors: [Color(0xFFE8EAF6), Color(0xFFC5CAE9)],
      textColor: Color(0xFF1A237E),
      accentColor: Color(0xFF283593),
    ),
    CategoryGradientPreset(
      name: 'Sunlight Yellow',
      colors: [Color(0xFFFFFDE7), Color(0xFFFFF59D)],
      textColor: Color(0xFFF57F17),
      accentColor: Color(0xFFFBC02D),
    ),
    CategoryGradientPreset(
      name: 'Pearl Mint',
      colors: [Color(0xFFEAFAF1), Color(0xFFD5F5E3)],
      textColor: Color(0xFF145A32),
      accentColor: Color(0xFF1E8449),
    ),
  ];

  static CategoryGradientPreset getGradient(int index) {
    if (index >= 0 && index < gradientPresets.length) {
      return gradientPresets[index];
    }
    return gradientPresets[0];
  }

  static const List<String> availableImages = [
    'assets/images/dua.png',
    'assets/images/tasbeeh.png',
    'assets/images/books.png',
    'assets/images/reminder.png',
    'assets/images/memorize.png',
    'assets/images/sadqa.png',
    'assets/logo.png',
    'assets/logo2.png',
  ];

  AdhkarCategory copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? titleAr,
    String? imagePath,
    int? gradientIndex,
    bool? isDefault,
  }) {
    return AdhkarCategory(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      titleAr: titleAr ?? this.titleAr,
      imagePath: imagePath ?? this.imagePath,
      gradientIndex: gradientIndex ?? this.gradientIndex,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'titleAr': titleAr,
      'imagePath': imagePath,
      'gradientIndex': gradientIndex,
      'isDefault': isDefault,
    };
  }

  factory AdhkarCategory.fromJson(Map<String, dynamic> json) {
    return AdhkarCategory(
      id: json['id'] as String,
      title: json['title'] as String,
      subtitle: (json['subtitle'] as String?) ?? '',
      titleAr: (json['titleAr'] as String?) ?? '',
      imagePath: (json['imagePath'] as String?) ?? 'assets/images/dua.png',
      gradientIndex: (json['gradientIndex'] as num?)?.toInt() ?? 0,
      isDefault: (json['isDefault'] as bool?) ?? false,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        subtitle,
        titleAr,
        imagePath,
        gradientIndex,
        isDefault,
      ];
}
