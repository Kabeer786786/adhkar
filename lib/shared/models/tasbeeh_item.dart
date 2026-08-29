import 'package:flutter/material.dart';

class TasbeehItem {
  final String id;
  final String textAr;
  final String textEn;
  final String translation;
  final String description;
  final int targetGoal;
  final int colorValue;
  final bool isCustom;
  final String marbleAsset;

  const TasbeehItem({
    required this.id,
    required this.textAr,
    required this.textEn,
    this.translation = '',
    required this.description,
    this.targetGoal = 33,
    this.colorValue = 0xFF2A531D,
    this.isCustom = false,
    this.marbleAsset = 'assets/images/marble1.png',
  });

  Color get color => Color(colorValue);

  String get effectiveTranslation {
    if (translation.isNotEmpty) return translation;
    for (final d in defaults) {
      if (d.id == id && d.translation.isNotEmpty) {
        return d.translation;
      }
    }
    return '';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'textAr': textAr,
      'textEn': textEn,
      'translation': translation,
      'description': description,
      'targetGoal': targetGoal,
      'colorValue': colorValue,
      'isCustom': isCustom,
      'marbleAsset': marbleAsset,
    };
  }

  factory TasbeehItem.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String;
    String translation = json['translation'] as String? ?? '';
    if (translation.isEmpty) {
      for (final d in defaults) {
        if (d.id == id && d.translation.isNotEmpty) {
          translation = d.translation;
          break;
        }
      }
    }
    return TasbeehItem(
      id: id,
      textAr: json['textAr'] as String,
      textEn: json['textEn'] as String,
      translation: translation,
      description: json['description'] as String? ?? '',
      targetGoal: (json['targetGoal'] as num?)?.toInt() ?? 33,
      colorValue: (json['colorValue'] as num?)?.toInt() ?? 0xFF2A531D,
      isCustom: json['isCustom'] as bool? ?? false,
      marbleAsset:
          json['marbleAsset'] as String? ?? 'assets/images/marble1.png',
    );
  }

  TasbeehItem copyWith({
    String? id,
    String? textAr,
    String? textEn,
    String? translation,
    String? description,
    int? targetGoal,
    int? colorValue,
    bool? isCustom,
    String? marbleAsset,
  }) {
    return TasbeehItem(
      id: id ?? this.id,
      textAr: textAr ?? this.textAr,
      textEn: textEn ?? this.textEn,
      translation: translation ?? this.translation,
      description: description ?? this.description,
      targetGoal: targetGoal ?? this.targetGoal,
      colorValue: colorValue ?? this.colorValue,
      isCustom: isCustom ?? this.isCustom,
      marbleAsset: marbleAsset ?? this.marbleAsset,
    );
  }

  static const List<TasbeehItem> defaults = [
    TasbeehItem(
      id: 'subhanallah',
      textAr: 'سُبۡحَانَ اللَّهِ',
      textEn: 'SubhanAllah',
      translation: 'Glory be to Allah',
      description:
          'Glory be to Allah. Reciting this 33 times after every obligatory prayer wipes away sins. The Prophet (ﷺ) said: "Whoever glorifies Allah 33 times after every prayer will have their sins forgiven even if they were like the foam of the sea." (Sahih Muslim)',
      targetGoal: 33,
      colorValue: 0xFF0284C7, // Sky Blue
      marbleAsset: 'assets/images/marble1.png',
    ),
    TasbeehItem(
      id: 'alhamdulillah',
      textAr: 'الۡحَمۡدُ لِلَّهِ',
      textEn: 'Alhamdulillah',
      translation: 'All praise is due to Allah',
      description:
          'All praise is due to Allah. Expressing gratitude increases divine blessings and brings tranquillity to the heart. Allah says in the Quran: "If you are grateful, I will surely increase you in favor." (Surah Ibrahim 14:7)',
      targetGoal: 33,
      colorValue: 0xFF16A34A, // Emerald Green
      marbleAsset: 'assets/images/marble2.png',
    ),
    TasbeehItem(
      id: 'allahuakbar',
      textAr: 'اللَّهُ أَكۡبَرُ',
      textEn: 'Allahu Akbar',
      translation: 'Allah is the Greatest',
      description:
          'Allah is the Greatest. Reminds the believer of the supreme majesty and greatness of Allah over everything in existence.',
      targetGoal: 33,
      colorValue: 0xFFEA580C, // Orange
      marbleAsset: 'assets/images/marble3.png',
    ),
    TasbeehItem(
      id: 'lailahaillallah',
      textAr: 'لَا إِلَهَ إِلَّا اللَّهُ',
      textEn: 'La ilaha illallah',
      translation: 'There is no god but Allah',
      description:
          'There is no god but Allah. The foundation of faith and the supreme form of remembrance. The Prophet (ﷺ) said: "The best dhikr is La ilaha illallah." (Tirmidhi)',
      targetGoal: 100,
      colorValue: 0xFF9333EA, // Purple
      marbleAsset: 'assets/images/marble4.png',
    ),
    TasbeehItem(
      id: 'astagfirullah',
      textAr: 'أَسۡتَغۡفِرُ اللَّهَ',
      textEn: 'Astaghfirullah',
      translation: 'I seek forgiveness from Allah',
      description:
          'I seek forgiveness from Allah. Reciting istighfar opens doors of sustenance and peace of mind.',
      targetGoal: 100,
      colorValue: 0xFF059669, // Teal
      marbleAsset: 'assets/images/marble5.png',
    ),
    TasbeehItem(
      id: 'subhanallah_bihamdihi',
      textAr: 'سُبۡحَانَ اللَّهِ وَبِحَمۡدِهِ سُبۡحَانَ اللَّهِ الۡعَظِيمِ',
      textEn: 'SubhanAllahi wa bihamdihi, SubhanAllahil Azim',
      translation:
          'Glory be to Allah and His is the praise, Glory be to Allah the Supreme',
      description:
          'Glory be to Allah and His is the praise, Glory be to Allah the Supreme. Two phrases light on the tongue but heavy on the scale of deeds. (Sahih al-Bukhari)',
      targetGoal: 100,
      colorValue: 0xFF2563EB, // Royal Blue
      marbleAsset: 'assets/images/marble1.png',
    ),
    TasbeehItem(
      id: 'salawat',
      textAr: 'اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ',
      textEn: 'Allahumma Salli Ala Muhammad',
      translation: 'O Allah, send blessings upon Muhammad',
      description:
          'O Allah, send blessings upon Muhammad and his family. The Prophet (ﷺ) said: "Whoever sends blessings upon me once, Allah sends blessings upon him ten times." (Sahih Muslim)',
      targetGoal: 100,
      colorValue: 0xFFD97724, // Amber
      marbleAsset: 'assets/images/marble2.png',
    ),
    TasbeehItem(
      id: 'lahawla',
      textAr: 'لَا حَوۡلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ',
      textEn: 'La hawla wa la quwwata illa billah',
      translation: 'There is no power nor strength except with Allah',
      description:
          'There is no power nor strength except with Allah. A treasure from the treasures of Paradise. (Sahih al-Bukhari)',
      targetGoal: 100,
      colorValue: 0xFF0D9488, // Dark Teal
      marbleAsset: 'assets/images/marble3.png',
    ),
    TasbeehItem(
      id: 'hasbunallah',
      textAr: 'حَسۡبُنَا اللَّهُ وَنِعۡمَ الۡوَكِيلُ',
      textEn: 'Hasbunallahu wa Ni\'mal Wakeel',
      translation:
          'Sufficient for us is Allah, and He is the best Disposer of affairs',
      description:
          'Sufficient for us is Allah, and He is the best Disposer of affairs. Recited by Prophet Ibrahim (AS) in fire and Prophet Muhammad (ﷺ) at Uhud.',
      targetGoal: 100,
      colorValue: 0xFFBE123C, // Crimson Rose
      marbleAsset: 'assets/images/marble4.png',
    ),
  ];
}
