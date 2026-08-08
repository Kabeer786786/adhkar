import 'package:flutter/material.dart';

class ScientificReference {
  final String title;
  final String source;
  final String description;

  const ScientificReference({
    required this.title,
    required this.source,
    required this.description,
  });
}

class SciIslamItem {
  final String id;
  final String title;
  final String category;
  final String shortDescription;
  final String arabicVerse;
  final String verseTranslation;
  final String surahReference;
  final String detailedExplanation;
  final List<String> keyFacts;
  final List<ScientificReference> references;
  final IconData icon;
  final Color themeColor;
  final String badgeText;

  const SciIslamItem({
    required this.id,
    required this.title,
    required this.category,
    required this.shortDescription,
    required this.arabicVerse,
    required this.verseTranslation,
    required this.surahReference,
    required this.detailedExplanation,
    required this.keyFacts,
    required this.references,
    required this.icon,
    required this.themeColor,
    required this.badgeText,
  });
}
