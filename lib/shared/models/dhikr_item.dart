import 'package:equatable/equatable.dart';

class DhikrItem extends Equatable {
  final String id;
  final String category;
  final String arabicText;
  final String transliteration;
  final String translation;
  final String reference;
  final String virtue;
  final int countTarget;
  final int countCurrent;
  final String? audioUrl;

  const DhikrItem({
    required this.id,
    required this.category,
    required this.arabicText,
    required this.transliteration,
    required this.translation,
    required this.reference,
    required this.virtue,
    required this.countTarget,
    this.countCurrent = 0,
    this.audioUrl,
  });

  DhikrItem copyWith({
    String? id,
    String? category,
    String? arabicText,
    String? transliteration,
    String? translation,
    String? reference,
    String? virtue,
    int? countTarget,
    int? countCurrent,
    String? audioUrl,
  }) {
    return DhikrItem(
      id: id ?? this.id,
      category: category ?? this.category,
      arabicText: arabicText ?? this.arabicText,
      transliteration: transliteration ?? this.transliteration,
      translation: translation ?? this.translation,
      reference: reference ?? this.reference,
      virtue: virtue ?? this.virtue,
      countTarget: countTarget ?? this.countTarget,
      countCurrent: countCurrent ?? this.countCurrent,
      audioUrl: audioUrl ?? this.audioUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'arabicText': arabicText,
      'transliteration': transliteration,
      'translation': translation,
      'reference': reference,
      'virtue': virtue,
      'countTarget': countTarget,
      'countCurrent': countCurrent,
      'audioUrl': audioUrl,
    };
  }

  factory DhikrItem.fromJson(Map<String, dynamic> json) {
    return DhikrItem(
      id: json['id'] as String,
      category: (json['category'] as String?) ?? 'custom',
      arabicText: json['arabicText'] as String,
      transliteration: (json['transliteration'] as String?) ?? '',
      translation: (json['translation'] as String?) ?? '',
      reference: (json['reference'] as String?) ?? '',
      virtue: (json['virtue'] as String?) ?? '',
      countTarget: (json['countTarget'] as num?)?.toInt() ?? 1,
      countCurrent: (json['countCurrent'] as num?)?.toInt() ?? 0,
      audioUrl: json['audioUrl'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        category,
        arabicText,
        transliteration,
        translation,
        reference,
        virtue,
        countTarget,
        countCurrent,
        audioUrl,
      ];
}
