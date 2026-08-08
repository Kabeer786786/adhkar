import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../widgets/app_header_bar.dart';
import '../domain/models/sci_islam_item.dart';

class SciIslamDetailScreen extends StatelessWidget {
  final SciIslamItem item;

  const SciIslamDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF192520) : const Color(0xFFF9F9F9),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AppHeaderBar(
          title: item.category.toUpperCase(),
          showBackButton: true,
          backgroundColor: isDark ? const Color(0xFF192520) : const Color(0xFFF9F9F9),
          iconColor: isDark ? Colors.white : const Color(0xFF2A531D),
          titleWidget: Text(
            item.category.toUpperCase(),
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF2A531D),
              fontWeight: FontWeight.bold,
              fontSize: 17,
              letterSpacing: 0.6,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
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
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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

            // Remaining Content in Normal Text (No Boxes, Matching Dua Detail Screen)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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
                    style: GoogleFonts.amiri(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: isDark ? const Color(0xFFFDE047) : const Color(0xFF1A3512),
                      height: 1.8,
                    ),
                  ),
                  const SizedBox(height: 12),

                  const Divider(color: Color(0xFFE2E8F0), thickness: 1.0),
                  const SizedBox(height: 12),

                  // Verse Translation (Normal Text)
                  SelectableText(
                    item.verseTranslation,
                    style: GoogleFonts.lexend(
                      fontSize: 13.5,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white70 : const Color(0xFF1B5E20),
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
                      color: isDark ? Colors.white70 : const Color(0xFF334155),
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
                                color: isDark ? Colors.white70 : const Color(0xFF1F2937),
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
                              color: isDark ? Colors.white : const Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 2),
                          SelectableText(
                            ref.description,
                            style: GoogleFonts.lexend(
                              fontSize: 12,
                              color: isDark ? Colors.white60 : const Color(0xFF6B7280),
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
    );
  }
}
