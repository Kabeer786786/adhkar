import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/books/data/books_repository.dart';
import '../../features/books/domain/book_model.dart';
import '../../features/books/presentation/book_reader_screen.dart';
import '../../features/books/presentation/widgets/bookshelf_view.dart';

enum FeatureIntroType { namaz, roza, sadqa }

class FeatureIntroModal extends StatelessWidget {
  final FeatureIntroType type;
  final VoidCallback? onDismiss;

  const FeatureIntroModal({super.key, required this.type, this.onDismiss});

  static Future<bool> shouldShow(FeatureIntroType type) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getStorageKey(type);
    return !(prefs.getBool(key) ?? false);
  }

  static Future<void> markAsSeen(FeatureIntroType type) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getStorageKey(type);
    await prefs.setBool(key, true);
  }

  static String _getStorageKey(FeatureIntroType type) {
    switch (type) {
      case FeatureIntroType.namaz:
        return 'has_seen_namaz_intro';
      case FeatureIntroType.roza:
        return 'has_seen_roza_intro';
      case FeatureIntroType.sadqa:
        return 'has_seen_sadqa_intro';
    }
  }

  static Future<void> show(
    BuildContext context,
    FeatureIntroType type, {
    VoidCallback? onDismiss,
  }) async {
    final should = await shouldShow(type);
    if (!should || !context.mounted) return;

    await Future.delayed(const Duration(milliseconds: 350));
    if (!context.mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FeatureIntroModal(type: type, onDismiss: onDismiss),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryGreen = Color(0xFF2A531D);
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subTextColor = isDark ? Colors.white70 : const Color(0xFF475569);

    final config = _getConfig(type);
    final book = BooksRepository.prebuiltLibrary.firstWhere(
      (b) => b.id == config.bookId,
      orElse: () => BooksRepository.prebuiltLibrary.first,
    );

    return Container(
      margin: EdgeInsets.only(
        left: 12,
        right: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2D24) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF2B3F33) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Row: [Bookshelf Book Cover] on Left, [Title & Description] on Right
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Left Side: Exact Bookshelf Book Cover Card
              GestureDetector(
                onTap: () {
                  markAsSeen(type);
                  Navigator.pop(context);
                  onDismiss?.call();
                  _openGuideBook(context, book);
                },
                child: BookshelfView.buildBookCoverCard(
                  book,
                  width: 100,
                  height: 130,
                ),
              ),

              const SizedBox(width: 14),

              // 2. Right Side Column: Title & Description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 2),
                    Text(
                      config.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 17.5,
                        height: 1.3,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      config.description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.lexend(
                        fontSize: 13,
                        height: 1.35,
                        color: subTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // Bottom Action Row: 2 Buttons aligned to Right (Skip & Read Guide)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Skip Button
              TextButton(
                onPressed: () {
                  markAsSeen(type);
                  Navigator.pop(context);
                  onDismiss?.call();
                },
                style: TextButton.styleFrom(
                  foregroundColor: subTextColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Skip',
                  style: GoogleFonts.lexend(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Read Guide Primary Button
              ElevatedButton.icon(
                onPressed: () {
                  markAsSeen(type);
                  Navigator.pop(context);
                  onDismiss?.call();
                  _openGuideBook(context, book);
                },
                icon: const Icon(Icons.menu_book_rounded, size: 15),
                label: Text(
                  'Read Guide',
                  style: GoogleFonts.lexend(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 11,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openGuideBook(BuildContext context, BookModel book) {
    BookReaderScreen.open(context, book);
  }

  _IntroConfig _getConfig(FeatureIntroType type) {
    switch (type) {
      case FeatureIntroType.namaz:
        return const _IntroConfig(
          title: 'Namaz & Prayer Times Guide',
          description:
              'Learn the spiritual virtues of Salah, step-by-step prayer guidance, and how to track daily Namaz in the app.',
          bookId: 'namaz_guide_book',
        );
      case FeatureIntroType.roza:
        return const _IntroConfig(
          title: 'The Complete Roza & Fasting Guide',
          description:
              'Understand the blessings of Sawm, rules, intentions, and how to track Ramadan & voluntary fasts in the app.',
          bookId: 'roza_guide_book',
        );
      case FeatureIntroType.sadqa:
        return const _IntroConfig( 
          title: 'The Sadaqah & Zakat Guide',
          description:
              'Discover Zakat Nisab calculations, the virtues of ongoing charity, and managing Sadaqah logs in the app.',
          bookId: 'sadqa_zakat_guide_book',
        );
    }
  }
}

class _IntroConfig {
  final String title;
  final String description;
  final String bookId;

  const _IntroConfig({
    required this.title,
    required this.description,
    required this.bookId,
  });
}
