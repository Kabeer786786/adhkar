/// Supported Arabic fonts for Quran, Adhkar, Dua, and Islamic content.
enum ArabicFont {
  digitalKhattIndoPak,
  notoNaskhArabic;

  /// Default Arabic font across the entire application.
  static const ArabicFont defaultFont = ArabicFont.digitalKhattIndoPak;

  /// Parses a string key into an [ArabicFont], defaulting to [defaultFont].
  static ArabicFont fromString(String? value) {
    if (value == null) return defaultFont;
    for (final font in ArabicFont.values) {
      if (font.name == value || font.fontFamily == value) {
        return font;
      }
    }
    return defaultFont;
  }
}

/// Centralized configuration and metadata extension for [ArabicFont].
extension ArabicFontExtension on ArabicFont {
  /// User-facing display name in Settings and UI.
  String get displayName {
    switch (this) {
      case ArabicFont.digitalKhattIndoPak:
        return 'IndoPak';
      case ArabicFont.notoNaskhArabic:
        return 'Noto Naskh Arabic';
    }
  }

  /// Font family string matching the `pubspec.yaml` registration.
  String get fontFamily {
    switch (this) {
      case ArabicFont.digitalKhattIndoPak:
        return 'DigitalKhattIndoPak';
      case ArabicFont.notoNaskhArabic:
        return 'NotoNaskhArabic';
    }
  }

  /// Whether this font is the app's default font.
  bool get isDefault => this == ArabicFont.digitalKhattIndoPak;

  /// Subtitle or script style description.
  String get description {
    switch (this) {
      case ArabicFont.digitalKhattIndoPak:
        return 'IndoPak Quranic script (Default)';
      case ArabicFont.notoNaskhArabic:
        return 'Clean standard Naskh Arabic';
    }
  }

  /// Representative Quranic sample text with various diacritical marks
  /// (Fathah, Kasrah, Dammah, Sukūn/Jazm, Shaddah, Madd, and Quranic marks).
  String get samplePreviewText => 'بِسْمِ ٱللَّهِ الرَّحْمٰنِ ٱلرَّحِيمِ\nٱلْحَمْدُ لِلَّهِ رَبِّ الْعٰلَمِيْنَ';
}