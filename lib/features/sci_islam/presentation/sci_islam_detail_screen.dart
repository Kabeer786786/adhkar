import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../widgets/app_header_bar.dart';
import '../domain/models/sci_islam_item.dart';

class SciIslamDetailScreen extends ConsumerStatefulWidget {
  final SciIslamItem item;

  const SciIslamDetailScreen({super.key, required this.item});

  @override
  ConsumerState<SciIslamDetailScreen> createState() =>
      _SciIslamDetailScreenState();
}

class _SciIslamDetailScreenState extends ConsumerState<SciIslamDetailScreen> {
  // Reading theme matching BookReaderScreen
  // 0 = Light, 1 = Sepia, 2 = OLED Dark, 3 = Charcoal
  bool _isThemePanelOpen = false;

  static const List<Color> _bgColors = [
    Color(0xFFFFFFFF), // 0: Light
    Color(0xFFFBF0D9), // 1: Sepia
    Color(0xFF0F0F12), // 2: OLED Dark
    Color(0xFF1E293B), // 3: Charcoal
  ];

  static const List<Color> _textColors = [
    Color(0xFF1A3512), // Light
    Color(0xFF422006), // Sepia
    Color(0xFFF8FAFC), // OLED Dark
    Color(0xFFF8FAFC), // Charcoal
  ];

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final readingTheme = ref.watch(readingThemeProvider);
    final isDark = readingTheme == 2 || readingTheme == 3;
    final bgColor = _bgColors[readingTheme];
    final textColor = _textColors[readingTheme];

    // Status bar icon colors: white for dark mode (Brightness.light), dark for light mode (Brightness.dark)
    final overlayStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: AppHeaderBar(
            title: item.category.toUpperCase(),
            showBackButton: true,
            backgroundColor: bgColor,
            iconColor: isDark ? Colors.white : const Color(0xFF2A531D),
            systemOverlayStyle: overlayStyle,
            titleWidget: Text(
              item.category.toUpperCase(),
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF2A531D),
                fontWeight: FontWeight.bold,
                fontSize: 17,
                letterSpacing: 0.6,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _isThemePanelOpen
                      ? Icons.palette_rounded
                      : Icons.palette_outlined,
                  color: isDark ? Colors.white : const Color(0xFF2A531D),
                  size: 23,
                ),
                tooltip: 'Reading Theme',
                onPressed: () {
                  setState(() {
                    _isThemePanelOpen = !_isThemePanelOpen;
                  });
                },
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),
        body: Stack(
          children: [
            GestureDetector(
              onTap: () {
                if (_isThemePanelOpen) {
                  setState(() => _isThemePanelOpen = false);
                }
              },
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Hero Box (ONLY Box on the Screen)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            item.themeColor,
                            item.themeColor.withValues(alpha: 0.85),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(24),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  item.badgeText.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                item.icon,
                                color: Colors.white,
                                size: 28,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            item.title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item.shortDescription,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Colors.white.withValues(alpha: 0.9),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Content Section with Theme Adapting Text
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 18,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Surah Reference Header
                          Text(
                            item.surahReference.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              color: Color(0xFFD97724),
                              decoration: TextDecoration.underline,
                              decorationColor: Color(0xFFD97724),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Quranic Arabic Verse (Normal Text)
                          SelectableText(
                            item.arabicVerse,
                            textAlign: TextAlign.center,
                            textDirection: TextDirection.rtl,
                            style: AppTypography.arabicHeader(
                              fontSize: 25,
                              color: isDark
                                  ? const Color(0xFFFDE047)
                                  : (readingTheme == 1
                                      ? const Color(0xFF78350F)
                                      : const Color(0xFF1A3512)),
                              height: 1.8,
                            ),
                          ),
                          const SizedBox(height: 12),

                          Divider(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.12)
                                : const Color(0xFFE2E8F0),
                            thickness: 1.0,
                          ),
                          const SizedBox(height: 12),

                          // Verse Translation (Normal Text)
                          SelectableText(
                            item.verseTranslation,
                            style: GoogleFonts.lexend(
                              fontSize: 13.5,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? Colors.white70
                                  : (readingTheme == 1
                                      ? const Color(0xFF5C2D0C)
                                      : const Color(0xFF1B5E20)),
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Scientific Revelation & Insight Section Header
                          Text(
                            'SCIENTIFIC REVELATION & INSIGHT',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                              color: item.themeColor,
                              decoration: TextDecoration.underline,
                              decorationColor: item.themeColor,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Detailed Scientific Explanation (Normal Text)
                          SelectableText(
                            item.detailedExplanation,
                            style: GoogleFonts.lexend(
                              fontSize: 14,
                              color: isDark
                                  ? Colors.white70
                                  : (readingTheme == 1
                                      ? const Color(0xFF432818)
                                      : const Color(0xFF334155)),
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Key Scientific Takeaways Section Header
                          const Text(
                            'KEY SCIENTIFIC TAKEAWAYS',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                              color: Color(0xFF16A34A),
                              decoration: TextDecoration.underline,
                              decorationColor: Color(0xFF16A34A),
                            ),
                          ),
                          const SizedBox(height: 10),

                          ...item.keyFacts.map(
                            (fact) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    color: Color(0xFF16A34A),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: SelectableText(
                                      fact,
                                      style: GoogleFonts.lexend(
                                        fontSize: 13,
                                        color: isDark
                                            ? Colors.white70
                                            : (readingTheme == 1
                                                ? const Color(0xFF432818)
                                                : const Color(0xFF1F2937)),
                                        height: 1.45,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Academic & Scientific References Section Header
                          const Text(
                            'ACADEMIC & SCIENTIFIC REFERENCES',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                              color: Color(0xFF2563EB),
                              decoration: TextDecoration.underline,
                              decorationColor: Color(0xFF2563EB),
                            ),
                          ),
                          const SizedBox(height: 10),

                          ...item.references.map(
                            (ref) => Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ref.source.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2563EB),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  SelectableText(
                                    ref.title,
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? Colors.white
                                          : (readingTheme == 1
                                              ? const Color(0xFF2B170B)
                                              : const Color(0xFF1F2937)),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  SelectableText(
                                    ref.description,
                                    style: GoogleFonts.lexend(
                                      fontSize: 12,
                                      color: isDark
                                          ? Colors.white60
                                          : (readingTheme == 1
                                              ? const Color(0xFF5C3D2E)
                                              : const Color(0xFF6B7280)),
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 36),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Top Floating Theme Selection Dropdown (Same as Book Detail / Reader Screen)
            if (_isThemePanelOpen)
              Positioned(
                top: 8,
                right: 16,
                child: Container(
                  width: 250,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF18181C) : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.15)
                          : Colors.black.withValues(alpha: 0.1),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.18),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'READING THEME',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: textColor.withValues(alpha: 0.7),
                              letterSpacing: 0.8,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            color: textColor.withValues(alpha: 0.6),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => setState(() => _isThemePanelOpen = false),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // 1. Light Mode (White with visible subtle border)
                          _buildThemeCircle(
                            color: const Color(0xFFFFFFFF),
                            borderColor: const Color(0xFF2A531D),
                            checkColor: const Color(0xFF2A531D),
                            isSelected: readingTheme == 0,
                            onTap: () => ref
                                .read(readingThemeProvider.notifier)
                                .setTheme(0),
                          ),
                          // 2. Sepia Mode (Warm Cream)
                          _buildThemeCircle(
                            color: const Color(0xFFFBF0D9),
                            borderColor: const Color(0xFF8C4A14),
                            checkColor: const Color(0xFF422006),
                            isSelected: readingTheme == 1,
                            onTap: () => ref
                                .read(readingThemeProvider.notifier)
                                .setTheme(1),
                          ),
                          // 3. OLED Black Mode (Deep Black)
                          _buildThemeCircle(
                            color: const Color(0xFF0F0F12),
                            borderColor: const Color(0xFFA3E635),
                            checkColor: const Color(0xFFA3E635),
                            isSelected: readingTheme == 2,
                            onTap: () => ref
                                .read(readingThemeProvider.notifier)
                                .setTheme(2),
                          ),
                          // 4. Charcoal Slate Mode
                          _buildThemeCircle(
                            color: const Color(0xFF1E293B),
                            borderColor: const Color(0xFF38BDF8),
                            checkColor: const Color(0xFF38BDF8),
                            isSelected: readingTheme == 3,
                            onTap: () => ref
                                .read(readingThemeProvider.notifier)
                                .setTheme(3),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeCircle({
    required Color color,
    required Color borderColor,
    required Color checkColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected
                ? borderColor
                : const Color(0xFF64748B).withValues(alpha: 0.35),
            width: isSelected ? 2.5 : 1.5,
          ),
        ),
        child: isSelected
            ? Center(
                child: Icon(Icons.check_rounded, color: checkColor, size: 20),
              )
            : null,
      ),
    );
  }
}
