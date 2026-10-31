import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';

class CategoryGradientPreset {
  final String name;
  final List<Color> colors;
  final Color textColor;
  final Color accentColor;
  final List<Color>? darkColors;
  final Color? darkTextColor;

  const CategoryGradientPreset({
    required this.name,
    required this.colors,
    required this.textColor,
    required this.accentColor,
    this.darkColors,
    this.darkTextColor,
  });

  List<Color> getColors(bool isDark) =>
      (isDark && darkColors != null) ? darkColors! : colors;

  Color getTextColor(bool isDark) =>
      (isDark && darkTextColor != null) ? darkTextColor! : textColor;
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
      darkColors: [Color(0xFF132218), Color(0xFF1B3322)],
      darkTextColor: Color(0xFF86EFAC),
    ),
    CategoryGradientPreset(
      name: 'Golden Dawn',
      colors: [Color(0xFFFFF8E1), Color(0xFFFFECB3)],
      textColor: Color(0xFF6D4C41),
      accentColor: Color(0xFFD9A925),
      darkColors: [Color(0xFF261E0E), Color(0xFF382C15)],
      darkTextColor: Color(0xFFFDE68A),
    ),
    CategoryGradientPreset(
      name: 'Sunset Lavender',
      colors: [Color(0xFFF3E5F5), Color(0xFFE1BEE7)],
      textColor: Color(0xFF4A148C),
      accentColor: Color(0xFF7B1FA2),
      darkColors: [Color(0xFF221329), Color(0xFF331D3D)],
      darkTextColor: Color(0xFFE9D5FF),
    ),
    CategoryGradientPreset(
      name: 'Ocean Breeze',
      colors: [Color(0xFFE0F7FA), Color(0xFFB2EBF2)],
      textColor: Color(0xFF006064),
      accentColor: Color(0xFF00838F),
      darkColors: [Color(0xFF0D2226), Color(0xFF143339)],
      darkTextColor: Color(0xFFA5F3FC),
    ),
    CategoryGradientPreset(
      name: 'Sky Blue',
      colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
      textColor: Color(0xFF0D47A1),
      accentColor: Color(0xFF1565C0),
      darkColors: [Color(0xFF0F1E2E), Color(0xFF172D45)],
      darkTextColor: Color(0xFFBAE6FD),
    ),
    CategoryGradientPreset(
      name: 'Rose Blossom',
      colors: [Color(0xFFFCE4EC), Color(0xFFF8BBD0)],
      textColor: Color(0xFF880E4F),
      accentColor: Color(0xFFC2185B),
      darkColors: [Color(0xFF28111B), Color(0xFF3B1828)],
      darkTextColor: Color(0xFFFBCFE8),
    ),
    CategoryGradientPreset(
      name: 'Warm Amber',
      colors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
      textColor: Color(0xFFE65100),
      accentColor: Color(0xFFF57C00),
      darkColors: [Color(0xFF2A190C), Color(0xFF3D2411)],
      darkTextColor: Color(0xFFFED7AA),
    ),
    CategoryGradientPreset(
      name: 'Sage Harmony',
      colors: [Color(0xFFF0F4C3), Color(0xFFE6EE9C)],
      textColor: Color(0xFF33691E),
      accentColor: Color(0xFF558B2F),
      darkColors: [Color(0xFF1D2412), Color(0xFF2B361B)],
      darkTextColor: Color(0xFFD9F99D),
    ),
    CategoryGradientPreset(
      name: 'Royal Purple',
      colors: [Color(0xFFEDE7F6), Color(0xFFD1C4E9)],
      textColor: Color(0xFF311B92),
      accentColor: Color(0xFF512DA8),
      darkColors: [Color(0xFF1C132E), Color(0xFF2A1D45)],
      darkTextColor: Color(0xFFDDD6FE),
    ),
    CategoryGradientPreset(
      name: 'Soft Peach',
      colors: [Color(0xFFFFF0F0), Color(0xFFFFCDD2)],
      textColor: Color(0xFFB71C1C),
      accentColor: Color(0xFFD32F2F),
      darkColors: [Color(0xFF2B1212), Color(0xFF3D1919)],
      darkTextColor: Color(0xFFFECACA),
    ),
    CategoryGradientPreset(
      name: 'Teal Lagoon',
      colors: [Color(0xFFE0F2F1), Color(0xFFB2DFDB)],
      textColor: Color(0xFF004D40),
      accentColor: Color(0xFF00695C),
      darkColors: [Color(0xFF0E221F), Color(0xFF15332E)],
      darkTextColor: Color(0xFF99F6E4),
    ),
    CategoryGradientPreset(
      name: 'Spring Meadow',
      colors: [Color(0xFFF1F8E9), Color(0xFFDCEDC8)],
      textColor: Color(0xFF33691E),
      accentColor: Color(0xFF689F38),
      darkColors: [Color(0xFF172413), Color(0xFF23361D)],
      darkTextColor: Color(0xFFBEF264),
    ),
    CategoryGradientPreset(
      name: 'Coral Glow',
      colors: [Color(0xFFFFF0F5), Color(0xFFFFD1DC)],
      textColor: Color(0xFF880E4F),
      accentColor: Color(0xFFAD1457),
      darkColors: [Color(0xFF2A1118), Color(0xFF3D1823)],
      darkTextColor: Color(0xFFFDA4AF),
    ),
    CategoryGradientPreset(
      name: 'Serene Slate',
      colors: [Color(0xFFECEFF1), Color(0xFFCFD8DC)],
      textColor: Color(0xFF263238),
      accentColor: Color(0xFF455A64),
      darkColors: [Color(0xFF171E22), Color(0xFF232D33)],
      darkTextColor: Color(0xFFE2E8F0),
    ),
    CategoryGradientPreset(
      name: 'Desert Sand',
      colors: [Color(0xFFFEF9E7), Color(0xFFFDEBD0)],
      textColor: Color(0xFF7E5109),
      accentColor: Color(0xFFB7950B),
      darkColors: [Color(0xFF271E10), Color(0xFF382C17)],
      darkTextColor: Color(0xFFFDE047),
    ),
    CategoryGradientPreset(
      name: 'Mystic Indigo',
      colors: [Color(0xFFE8EAF6), Color(0xFFC5CAE9)],
      textColor: Color(0xFF1A237E),
      accentColor: Color(0xFF283593),
      darkColors: [Color(0xFF12162E), Color(0xFF1B2145)],
      darkTextColor: Color(0xFFC7D2FE),
    ),
    CategoryGradientPreset(
      name: 'Sunlight Yellow',
      colors: [Color(0xFFFFFDE7), Color(0xFFFFF59D)],
      textColor: Color(0xFFF57F17),
      accentColor: Color(0xFFFBC02D),
      darkColors: [Color(0xFF26200A), Color(0xFF382F0F)],
      darkTextColor: Color(0xFFFEF08A),
    ),
    CategoryGradientPreset(
      name: 'Pearl Mint',
      colors: [Color(0xFFEAFAF1), Color(0xFFD5F5E3)],
      textColor: Color(0xFF145A32),
      accentColor: Color(0xFF1E8449),
      darkColors: [Color(0xFF112217), Color(0xFF193322)],
      darkTextColor: Color(0xFFA7F3D0),
    ),
  ];

  static CategoryGradientPreset getGradient(int index) {
    if (index >= 0 && index < gradientPresets.length) {
      return gradientPresets[index];
    }
    return gradientPresets.first;
  }

  static const List<String> availableImages = [
    'assets/images/adhkar/morning_adhkar.png',
    'assets/images/adhkar/evening_adhkar.png',
    'assets/images/adhkar/after_salah_adhkar.png',
    'assets/images/adhkar/night_adhkar.png',
    'assets/images/adhkar/daily_duaeen.png',
    'assets/images/adhkar/duaeen_adhkar.png',
    'assets/images/adhkar/quranic_adhkar.png',
    'assets/images/adhkar/ramadhan_adhkar.png',
    'assets/images/adhkar/travelling_adhkar.png',
    'assets/images/adhkar/health_issues_adhkar.png',
    'assets/images/adhkar/debt_free_adhkar.png',
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
      imagePath: (json['imagePath'] as String?) ?? 'assets/images/adhkar/morning_adhkar.png',
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
