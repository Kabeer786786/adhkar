import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../widgets/app_header_bar.dart';
import '../domain/dua_item.dart';

class DuaDetailScreen extends StatelessWidget {
  final DuaItem dua;

  const DuaDetailScreen({
    super.key,
    required this.dua,
  });

  static Color _getCategoryTextColor(String category) {
    switch (category.trim().toLowerCase()) {
      case 'daily':
        return const Color(0xFF1B5E20);
      case 'sleep':
        return const Color(0xFF1E3A8A);
      case 'hygiene':
        return const Color(0xFFDB2777);
      case 'food':
        return const Color(0xFFB45309);
      case 'travel':
        return const Color(0xFF047857);
      case 'protection':
        return const Color(0xFF7E22CE); 
      default:
        return const Color(0xFFBE123C);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = _getCategoryTextColor(dua.category);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppHeaderBar(
        title: dua.title,
        showBackButton: true,
        backgroundColor: Colors.white,
      ),
      body: SizedBox.expand(
        child: Stack( 
          children: [
            // Fixed Decorative Image at Bottom-Right Corner of Screen Viewport
            Positioned(
              bottom: 40,
              right: 12,
              child: IgnorePointer(
                child: Opacity(  
                  opacity: 0.3,
                  child: Image.asset(
                    dua.imagePath,
                    width: 160,
                    height: 160,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),

            // Main Single Scrollable Screen Content
            Positioned.fill(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Tags Row: Category Chip + Optional Recitation Count Badge (Only if > 1)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: themeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        dua.category.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                          color: themeColor,
                        ),
                      ),
                    ),
                    if (dua.repeatCount > 1)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD97724),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Recite ${dua.repeatCount} Times',
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.1,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 18),

                // Main Title
                Text(
                  dua.title,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0,
                    color: themeColor,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 22),

                // Large Arabic Text
                SelectableText(
                  dua.arabic,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  style: GoogleFonts.amiri(
                    fontSize: 27,
                    height: 1.8,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A3512),
                  ),
                ),
                const SizedBox(height: 12),

                const Divider(
                  color: Color(0xFFE2E8F0),
                  thickness: 1.0,
                ),
                const SizedBox(height: 12),
                SelectableText(
                  dua.transliteration,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.45,
                    letterSpacing: 0,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 12),

                SelectableText(
                  '"${dua.translation}"',
                  style: GoogleFonts.lexend(
                    fontSize: 15,
                    height: 1.45,
                    letterSpacing: -0.6,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1B5E20),
                  ),
                ),
                const SizedBox(height: 18),

                // Origin & Reference Section
                const Text(
                  'REFERENCE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: Color(0xFFD97724),
                  ),
                ),
                const SizedBox(height: 6),
                SelectableText(
                  dua.reference,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    letterSpacing: -0.1,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF4A3728),
                  ),
                ),
                const SizedBox(height: 18),

                // Spiritual & Practical Benefits Section
                const Text(
                  'SPIRITUAL & PRACTICAL BENEFITS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: Color(0xFF9333EA),
                  ),
                ),
                const SizedBox(height: 6),
                SelectableText(
                  dua.benefits,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    letterSpacing: -0.1,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF3B0764),
                  ),
                ),
                const SizedBox(height: 36),
              ],
            ),
          ),
        ),
      ],
    ),
  ),
);
  }
}
