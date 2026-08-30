import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_islamic_icons/flutter_islamic_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_typography.dart';
import '../../../core/typography/arabic_font.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../widgets/app_header_bar.dart';
import '../data/surah_model.dart';

class SurahInfoScreen extends ConsumerStatefulWidget {
  final SurahModel surah;

  const SurahInfoScreen({super.key, required this.surah});

  @override
  ConsumerState<SurahInfoScreen> createState() => _SurahInfoScreenState();
}

class _SurahInfoScreenState extends ConsumerState<SurahInfoScreen> {
  // 'en' for English, 'ur' for Urdu
  String _selectedLang = 'en';

  @override
  void initState() {
    super.initState();
    // Default language matching Quran translation preference or English
    final currentTransLang = ref
        .read(storageServiceProvider)
        .getQuranTranslationLanguage();
    if (currentTransLang == 'urdu') {
      _selectedLang = 'ur';
    } else {
      _selectedLang = 'en';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final storage = ref.watch(storageServiceProvider);
    final arabicFont = ArabicFont.fromString(storage.getArabicFont());

    final surah = widget.surah;
    final isUrdu = _selectedLang == 'ur';
    final langInfo = isUrdu ? surah.surahInfo.ur : surah.surahInfo.en;

    final String htmlText = langInfo.text ?? '';
    final String? shortText = langInfo.shortText;

    final isMakkah =
        surah.revelationType.toLowerCase().contains('makk') ||
        surah.revelationType.toLowerCase().contains('mecc');

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF131E18)
          : const Color(0xFFFCFBF7),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AppHeaderBar(
          title: 'Surah Information',
          showBackButton: true,
          centerTitle: false,
          leadingWidth: 54,
          systemOverlayStyle: isDark
              ? SystemUiOverlayStyle.light
              : SystemUiOverlayStyle.dark,
          backgroundColor: isDark ? const Color(0xFF192520) : Colors.white,
          iconColor: isDark ? Colors.white : const Color(0xFF2A531D),
          titleWidget: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF233827)
                      : const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF2A531D).withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  '${surah.number}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? const Color(0xFFA3E635)
                        : const Color(0xFF2A531D),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  surah.nameEnglish,
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF2A531D),
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // HERO CARD: Surah Overview & Key Metadata Badges
            _buildHeroCard(
              surah: surah,
              isDark: isDark,
              arabicFont: arabicFont,
              isMakkah: isMakkah,
            ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.05, end: 0),

            const SizedBox(height: 16),

            // LANGUAGE TOGGLE SEGMENT (English vs. اردو)
            _buildLanguageSelector(
              isDark: isDark,
            ).animate().fadeIn(delay: 100.ms, duration: 300.ms),

            const SizedBox(height: 16),

            // SHORT SUMMARY CARD (if available)
            if (shortText != null && shortText.trim().isNotEmpty) ...[
              _buildShortSummaryCard(
                shortText: shortText.trim(),
                isUrdu: isUrdu,
                isDark: isDark,
              ).animate().fadeIn(delay: 150.ms, duration: 350.ms),
              const SizedBox(height: 16),
            ],

            // MAIN CONTENT CARD WITH HTML RENDERING
            _buildContentCard(
              htmlContent: htmlText,
              isUrdu: isUrdu,
              isDark: isDark,
            ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard({
    required SurahModel surah,
    required bool isDark,
    required ArabicFont arabicFont,
    required bool isMakkah,
  }) {
    final revelationOrder = surah.revelationOrder;
    final totalVerses = surah.versesCount ?? surah.verseCount;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E3A15), const Color(0xFF0F1A0E)]
              : [const Color(0xFF437A2C), const Color(0xFF204616)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2A531D).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // English Titles & Meaning
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      surah.nameEnglish,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                    if (surah.nameTranslation.isNotEmpty)
                      Text(
                        surah.nameTranslation,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Arabic Calligraphy Header
              Text(
                surah.nameArabic,
                textDirection: TextDirection.rtl,
                style: AppTypography.arabicHeader(
                  arabicFont: arabicFont,
                  fontSize: 28,
                  color: const Color(0xFFD1FFBE),
                  height: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 14),

          // Metadata Pills Wrap (Revelation Place, Order, Total Verses)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // Revelation Place Badge
              _buildMetaBadge(
                icon: isMakkah
                    ? FlutterIslamicIcons.kaaba
                    : FlutterIslamicIcons.solidMosque,
                label: isMakkah ? 'Makki (Makkah)' : 'Madani (Madinah)',
                bgColor: Colors.white.withValues(alpha: 0.15),
                textColor: const Color(0xFFD1FFBE),
              ),

              // Revelation Chronological Order Badge
              if (revelationOrder != null)
                // Surah Position in Mushaf
                _buildMetaBadge(
                  icon: Icons.menu_book_rounded,
                  label: 'Surah #${surah.number} of 114',
                  bgColor: Colors.white.withValues(alpha: 0.15),
                  textColor: Colors.white,
                ),

              _buildMetaBadge(
                icon: Icons.history_edu_rounded,
                label: 'Revelation Order: #$revelationOrder',
                bgColor: Colors.white.withValues(alpha: 0.15),
                textColor: Colors.white,
              ),

              // Total Verses Badge
              _buildMetaBadge(
                icon: Icons.format_list_numbered_rounded,
                label: '$totalVerses Verses',
                bgColor: Colors.white.withValues(alpha: 0.15),
                textColor: Colors.white,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetaBadge({
    required IconData icon,
    required String label,
    required Color bgColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector({required bool isDark}) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2D24) : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white10
              : const Color(0xFF2A531D).withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildLangOption(
              key: 'en',
              title: 'English',
              isSelected: _selectedLang == 'en',
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildLangOption(
              key: 'ur',
              title: 'Urdu',
              isSelected: _selectedLang == 'ur',
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLangOption({
    required String key,
    required String title,
    required bool isSelected,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: () {
        if (_selectedLang != key) {
          HapticFeedback.selectionClick();
          setState(() {
            _selectedLang = key;
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF2A531D) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected
                  ? (isDark ? const Color(0xFFD1FFBE) : const Color(0xFF2A531D))
                  : (isDark ? Colors.white60 : Colors.grey.shade700),
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildShortSummaryCard({
    required String shortText,
    required bool isUrdu,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B2B20) : const Color(0xFFF1F8EE),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF2A531D).withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: isUrdu
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isUrdu
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            children: [
              Icon(
                Icons.lightbulb_outline_rounded,
                size: 18,
                color: isDark
                    ? const Color(0xFFA3E635)
                    : const Color(0xFF2A531D),
              ),
              const SizedBox(width: 6),
              Text(
                isUrdu ? 'خلاصہ تعارف' : 'Quick Summary',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? const Color(0xFFA3E635)
                      : const Color(0xFF2A531D),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            shortText,
            textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
            style: isUrdu
                ? GoogleFonts.notoNaskhArabic(
                    fontSize: 15.5,
                    height: 1.8,
                    color: isDark
                        ? const Color(0xFFE2E8F0)
                        : const Color(0xFF1E293B),
                  )
                : TextStyle(
                    fontSize: 14,
                    height: 1.55,
                    color: isDark
                        ? const Color(0xFFE2E8F0)
                        : const Color(0xFF334155),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentCard({
    required String htmlContent,
    required bool isUrdu,
    required bool isDark,
  }) {
    if (htmlContent.trim().isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF192520) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.grey.shade200,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 40,
              color: isDark ? Colors.white38 : Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              isUrdu
                  ? 'اس سورت کی تفصیلی معلومات فی الحال دستیاب نہیں ہے۔'
                  : 'Detailed information for this Surah is currently not available.',
              style: TextStyle(
                color: isDark ? Colors.white60 : Colors.grey.shade600,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Colors for HTML rendering
    final textColor = isDark
        ? const Color(0xFFE2E8F0)
        : const Color(0xFF1E293B);
    final headerColor = isDark
        ? const Color(0xFF86EFAC)
        : const Color(0xFF2A531D);
    final linkColor = isDark
        ? const Color(0xFF60A5FA)
        : const Color(0xFF2563EB);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF192520) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark
              ? Colors.white10
              : const Color(0xFF2A531D).withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Directionality(
        textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
        child: HtmlWidget(
          htmlContent,
          onTapUrl: (url) async {
            try {
              final uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
                return true;
              }
            } catch (_) {}
            return false;
          },
          textStyle: isUrdu
              ? GoogleFonts.notoNaskhArabic(
                  fontSize: 16.5,
                  height: 1.9,
                  color: textColor,
                )
              : TextStyle(
                  fontSize: 15,
                  height: 1.65,
                  color: textColor,
                  letterSpacing: 0.15,
                ),
          customStylesBuilder: (element) {
            final tag = element.localName?.toLowerCase();
            switch (tag) {
              case 'h2':
                return {
                  'color': headerColor.toHex(),
                  'font-weight': 'bold',
                  'font-size': isUrdu ? '20px' : '18.5px',
                  'margin-top': '18px',
                  'margin-bottom': '8px',
                  'padding-bottom': '4px',
                  'border-bottom':
                      '1.5px solid ${headerColor.withValues(alpha: 0.3).toHex()}',
                };
              case 'h3':
                return {
                  'color': headerColor.toHex(),
                  'font-weight': 'bold',
                  'font-size': isUrdu ? '18px' : '16.5px',
                  'margin-top': '14px',
                  'margin-bottom': '6px',
                };
              case 'p':
                return {
                  'margin-bottom': '12px',
                  'line-height': isUrdu ? '1.9' : '1.65',
                };
              case 'a':
                return {
                  'color': linkColor.toHex(),
                  'text-decoration': 'underline',
                  'font-weight': '600',
                };
              case 'strong':
              case 'b':
                return {
                  'font-weight': 'bold',
                  'color': isDark ? '#FFFFFF' : '#0F172A',
                };
              case 'em':
              case 'i':
                return {'font-style': 'italic'};
              case 'li':
                return {
                  'margin-bottom': '8px',
                  'line-height': isUrdu ? '1.85' : '1.6',
                };
              case 'ol':
              case 'ul':
                return {
                  'margin-top': '6px',
                  'margin-bottom': '14px',
                  'padding-left': isUrdu ? '0px' : '20px',
                  'padding-right': isUrdu ? '20px' : '0px',
                };
              default:
                return null;
            }
          },
        ),
      ),
    );
  }
}

extension _ColorHex on Color {
  String toHex() {
    return '#${toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';
  }
}
