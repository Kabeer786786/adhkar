import 'package:flutter_test/flutter_test.dart';
import 'package:adhkar/core/typography/arabic_font.dart';
import 'package:adhkar/core/theme/app_typography.dart';

void main() {
  group('ArabicFont Enum and Extensions Tests', () {
    test('Default font is Digital Khatt IndoPak', () {
      expect(ArabicFont.defaultFont, equals(ArabicFont.digitalKhattIndoPak));
      expect(ArabicFont.digitalKhattIndoPak.isDefault, isTrue);
      expect(ArabicFont.notoNaskhArabic.isDefault, isFalse);
    });

    test('Font family mappings are exact', () {
      expect(ArabicFont.digitalKhattIndoPak.fontFamily, equals('DigitalKhattIndoPak'));
      expect(ArabicFont.notoNaskhArabic.fontFamily, equals('NotoNaskhArabic'));
    });

    test('fromString serialization and deserialization with fallback', () {
      expect(ArabicFont.fromString('digitalKhattIndoPak'), equals(ArabicFont.digitalKhattIndoPak));
      expect(ArabicFont.fromString('notoNaskhArabic'), equals(ArabicFont.notoNaskhArabic));
      // Removed fonts fall back to default
      expect(ArabicFont.fromString('digitalKhattV2'), equals(ArabicFont.digitalKhattIndoPak));
      expect(ArabicFont.fromString('amiri'), equals(ArabicFont.digitalKhattIndoPak));
      expect(ArabicFont.fromString('invalid_key'), equals(ArabicFont.digitalKhattIndoPak));
      expect(ArabicFont.fromString(null), equals(ArabicFont.digitalKhattIndoPak));
    });

    test('Display names and sample texts are non-empty', () {
      for (final font in ArabicFont.values) {
        expect(font.displayName.isNotEmpty, isTrue);
        expect(font.description.isNotEmpty, isTrue);
        expect(font.samplePreviewText.isNotEmpty, isTrue);
      }
    });
  });

  group('AppTypography Arabic Styles Tests', () {
    test('arabicHeader and arabicBody apply active font family', () {
      AppTypography.activeArabicFont = ArabicFont.digitalKhattIndoPak;
      final headerStyle = AppTypography.arabicHeader(fontSize: 24);
      expect(headerStyle.fontFamily, equals('DigitalKhattIndoPak'));
      expect(headerStyle.fontSize, equals(24));

      final bodyStyle = AppTypography.arabicBody(fontSize: 18);
      expect(bodyStyle.fontFamily, equals('DigitalKhattIndoPak'));
      expect(bodyStyle.fontSize, equals(18));

      // Test explicit font override
      final overrideStyle = AppTypography.arabicBody(
        arabicFont: ArabicFont.notoNaskhArabic,
        fontSize: 20,
      );
      expect(overrideStyle.fontFamily, equals('NotoNaskhArabic'));
      expect(overrideStyle.fontSize, equals(20));
    });
  });
}
