import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_islamic_icons/flutter_islamic_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/widgets/app_floating_toast.dart';
import '../data/books_provider.dart';
import '../domain/book_content_block.dart';
import '../domain/book_model.dart';
import 'widgets/book_content_renderer.dart';
import 'widgets/book_vertical_scrollbar.dart';

class BookReaderScreen extends ConsumerStatefulWidget {
  final BookModel book;

  const BookReaderScreen({super.key, required this.book});

  /// Opens the book either in-app or externally based on book.openMode
  static Future<void> open(
    BuildContext context,
    BookModel book, {
    bool forceExternal = false,
  }) async {
    final filePath = book.fileUrl?.trim() ?? '';

    if (forceExternal ||
        book.openMode == 'external' ||
        (book.isCustom && book.openMode != 'in_app')) {
      if (filePath.isNotEmpty) {
        await openExternal(context, filePath);
        return;
      }
    }

    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => BookReaderScreen(book: book)),
      );
    }
  }

  /// Explicitly opens the book file or URL in an external application / browser
  static Future<void> openExternal(BuildContext context, String? path) async {
    if (path == null || path.trim().isEmpty) {
      if (context.mounted) {
        AppFloatingToast.showInfo(
          context,
          message: 'No external document or link available for this book',
        );
      }
      return;
    }

    final trimmed = path.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      final uri = Uri.parse(trimmed);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else if (context.mounted) {
        AppFloatingToast.showError(
          context,
          message: 'Could not launch URL: $trimmed',
        );
      }
    } else if (File(trimmed).existsSync() || isDocumentFile(trimmed)) {
      final result = await OpenFilex.open(trimmed);
      if (result.type != ResultType.done && context.mounted) {
        AppFloatingToast.showInfo(
          context,
          message: result.message.isNotEmpty && result.message != 'done'
              ? 'Opening document: ${result.message}'
              : 'Opening document in external app...',
        );
      }
    } else if (context.mounted) {
      AppFloatingToast.showError(context, message: 'File not found: $trimmed');
    }
  }

  static bool isDocumentFile(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.pdf') ||
        lower.endsWith('.doc') ||
        lower.endsWith('.docx') ||
        lower.endsWith('.txt');
  }

  @override
  ConsumerState<BookReaderScreen> createState() => _BookReaderScreenState();
}

class _BookReaderScreenState extends ConsumerState<BookReaderScreen> {
  late final ScrollController _scrollController;
  final List<GlobalKey> _chapterKeys = [];

  // Reading controls state
  bool _isThemePanelOpen = false;
  int _selectedChapterIndex = 0;
  final double _fontSize = 16.0;

  static const List<Color> _bgColors = [
    Color(0xFFFFFFFF), // Light (default)
    Color(0xFFFBF0D9), // Sepia
    Color(0xFF0F0F12), // OLED Dark
    Color(0xFF1E293B), // Charcoal
  ];

  static const List<Color> _cardBgColors = [
    Color(0xFFF8FAFC),
    Color(0xFFF5EAD4),
    Color(0xFF18181B),
    Color(0xFF334155),
  ];

  static const List<Color> _textColors = [
    Color(0xFF1A3512), // Dark green text in light mode
    Color(0xFF422006), // Sepia text
    Color(0xFFF8FAFC), // OLED Dark text
    Color(0xFFF8FAFC), // Charcoal text
  ];

  static const List<Color> _accentColors = [
    Color(0xFF2A531D), // Dark green accent in light mode
    Color(0xFF8C4A14), // Dark brown/amber accent in sepia
    Color(0xFFA3E635), // Neon emerald in OLED dark
    Color(0xFF38BDF8), // Cyan/Sky in charcoal
  ];

  // Exact Theme Colors from Scientific Islam Detail Screen
  static const List<Color> _sciThemeColors = [
    Color(0xFF6366F1), // 1. Astrophysics / Indigo
    Color(0xFF0EA5E9), // 2. Cosmology / Sky Blue
    Color(0xFF0D9488), // 3. Oceanography / Deep Teal
    Color(0xFFEC4899), // 4. Embryology / Pink
    Color(0xFFD97706), // 5. Geology / Amber
    Color(0xFF0284C7), // 6. Meteorology / Ocean Blue
    Color(0xFF16A34A), // 7. Botany / Emerald Green
    Color(0xFF78350F), // 8. Iron & Core / Earth Brown
    Color(0xFF8B5CF6), // 9. Quantum / Royal Purple
    Color(0xFF334155), // 10. Human Biology / Deep Slate
  ];

  static const List<IconData> _chapterIcons = [
    Icons.auto_awesome_rounded,
    Icons.blur_on_rounded,
    Icons.water_rounded,
    Icons.favorite_rounded,
    Icons.terrain_rounded,
    Icons.air_rounded,
    Icons.eco_rounded,
    Icons.shield_rounded,
    FlutterIslamicIcons.quran2,
    FlutterIslamicIcons.solidQuran,
  ];

  Timer? _progressDebounceTimer;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    for (int i = 0; i < widget.book.chapters.length; i++) {
      _chapterKeys.add(GlobalKey());
    }
  }

  @override
  void dispose() {
    _progressDebounceTimer?.cancel();
    if (_scrollController.hasClients && widget.book.chapters.isNotEmpty) {
      final total = widget.book.chapters.length;
      final maxScroll = _scrollController.position.maxScrollExtent;
      if (maxScroll > 0) {
        final progress = (_scrollController.offset / maxScroll).clamp(0.0, 1.0);
        final estimatedChapter = (progress * total).floor().clamp(0, total - 1);
        ref
            .read(userBooksProvider.notifier)
            .updateProgress(
              bookId: widget.book.id,
              progress: progress,
              currentPage: estimatedChapter + 1,
            );
      }
    }
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_isThemePanelOpen) {
      setState(() {
        _isThemePanelOpen = false;
      });
    }

    final total = widget.book.chapters.length;
    if (total > 0 && _scrollController.position.maxScrollExtent > 0) {
      final progress =
          (_scrollController.offset /
                  _scrollController.position.maxScrollExtent)
              .clamp(0.0, 1.0);
      final estimatedChapter = (progress * total).floor().clamp(0, total - 1);
      if (estimatedChapter != _selectedChapterIndex) {
        _selectedChapterIndex = estimatedChapter;

        _progressDebounceTimer?.cancel();
        _progressDebounceTimer = Timer(const Duration(milliseconds: 600), () {
          if (mounted) {
            ref
                .read(userBooksProvider.notifier)
                .updateProgress(
                  bookId: widget.book.id,
                  progress: progress,
                  currentPage: estimatedChapter + 1,
                );
          }
        });
      }
    }
  }

  void _scrollToChapter(int chapterIndex) {
    if (chapterIndex < 0 || chapterIndex >= widget.book.chapters.length) return;

    setState(() {
      _selectedChapterIndex = chapterIndex;
      _isThemePanelOpen = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (chapterIndex < _chapterKeys.length && _scrollController.hasClients) {
        final keyContext = _chapterKeys[chapterIndex].currentContext;
        if (keyContext != null) {
          final renderBox = keyContext.findRenderObject() as RenderBox?;
          if (renderBox != null) {
            final scrollPosition = _scrollController.position;
            final scrollableBox =
                scrollPosition.context.notificationContext?.findRenderObject()
                    as RenderBox?;

            if (scrollableBox != null) {
              final offsetInViewport = renderBox.localToGlobal(
                Offset.zero,
                ancestor: scrollableBox,
              );
              // Direct mathematically exact top-0 scroll target below AppBar
              final targetOffset =
                  (_scrollController.offset + offsetInViewport.dy).clamp(
                    0.0,
                    scrollPosition.maxScrollExtent,
                  );

              _scrollController.animateTo(
                targetOffset,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
              );
              return;
            }
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chapters = widget.book.chapters;
    final readingTheme = ref.watch(readingThemeProvider);
    final isDark = readingTheme == 2 || readingTheme == 3;
    final bgColor = _bgColors[readingTheme];
    final cardBgColor = _cardBgColors[readingTheme];
    final textColor = _textColors[readingTheme];
    final accentColor = _accentColors[readingTheme];

    final double bottomInset = MediaQuery.of(context).padding.bottom;

    final overlayStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
    );
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: bgColor,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleSpacing: 0,
          systemOverlayStyle: overlayStyle,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, size: 24),
            color: textColor,
            tooltip: 'Back',
            onPressed: () => Navigator.pop(context),
          ),
          title: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(
              widget.book.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textColor,
                letterSpacing: 0.2,
              ),
            ),
          ),
          actions: [
            // Table of Contents Action
            if (chapters.length > 1)
              IconButton(
                icon: const Icon(Icons.format_list_bulleted_rounded, size: 22),
                color: textColor,
                tooltip: 'Table of Contents',
                onPressed: () => _showTableOfContentsModal(
                  context,
                  chapters: chapters,
                  isDark: isDark,
                  textColor: textColor,
                  accentColor: accentColor,
                  cardBgColor: cardBgColor,
                ),
              ),
            // Reading Theme Toggle Action
            IconButton(
              icon: Icon(
                _isThemePanelOpen
                    ? Icons.palette_rounded
                    : Icons.palette_outlined,
                color: textColor,
                size: 22,
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
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.06),
              height: 1,
            ),
          ),
        ),
        body: Stack(
          children: [
            // Continuous Reading View
            GestureDetector(
              onTap: () {
                if (_isThemePanelOpen) {
                  setState(() => _isThemePanelOpen = false);
                }
              },
              child: chapters.isEmpty
                  ? _buildEmptyState(textColor, cardBgColor)
                  : SingleChildScrollView(
                      controller: _scrollController,
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(0, 0, 0, bottomInset + 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: List.generate(chapters.length, (chapIdx) {
                          final chap = chapters[chapIdx];
                          final blocks = chap.effectiveBlocks;
                          final themeColor =
                              _sciThemeColors[chapIdx % _sciThemeColors.length];
                          final icon =
                              _chapterIcons[chapIdx % _chapterIcons.length];

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // 1. Edge-to-Edge Section Divider (Only between chapters; Chapter 1 has none)
                              if (chapIdx > 0) _buildSectionDivider(isDark),

                              // 2. Chapter Content starting with Hero Header Box (KeyedSubtree avoids raster cache blur)
                              KeyedSubtree(
                                key: chapIdx < _chapterKeys.length
                                    ? _chapterKeys[chapIdx]
                                    : null,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _buildChapterHeaderBox(
                                      chapIdx: chapIdx,
                                      title: chap.title,
                                      subtitle: chap.subtitle,
                                      themeColor: themeColor,
                                      icon: icon,
                                    ),

                                    // Chapter Content with tight horizontal & vertical padding
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        14,
                                        12,
                                        14,
                                        24,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: _buildChapterBlocks(
                                          blocks,
                                          fontSize: _fontSize,
                                          isDark: isDark,
                                          textColor: textColor,
                                          accentColor: accentColor,
                                          cardBgColor: cardBgColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }),
                      ),
                    ),
            ),

            // Right-docked Interactive Smooth Scrollbar
            Positioned(
              top: 10,
              right: 0,
              bottom: bottomInset + 10,
              child: BookVerticalScrollbar(
                scrollController: _scrollController,
                isDark: isDark,
              ),
            ),

            // Top Floating Theme Selection Dropdown (Matches SciIslamDetailScreen)
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
                        color: Colors.black
                            .withValues(alpha: isDark ? 0.45 : 0.18),
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
                            onPressed: () =>
                                setState(() => _isThemePanelOpen = false),
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

  /// Scientific Islam Detail Page Style Chapter Header Box
  Widget _buildChapterHeaderBox({
    required int chapIdx,
    required String title,
    String? subtitle,
    required Color themeColor,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [themeColor, themeColor.withValues(alpha: 0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: themeColor.withValues(alpha: 0.32),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
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
                  'CHAPTER ${chapIdx + 1}',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              const Spacer(),
              Icon(icon, color: Colors.white, size: 28),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.35,
            ),
          ),
          if (subtitle != null && subtitle.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 13.5,
                color: Colors.white.withValues(alpha: 0.9),
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Edge-to-Edge Section Divider (Full width, touching both edges, not rounded)
  Widget _buildSectionDivider(bool isDark) {
    return Container(
      height: 8,
      width: double.infinity,
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2822) : const Color(0xFFE2E8F0),
      ),
    );
  }

  /// Builds chapter content blocks, pairing consecutive image blocks into 2-in-a-row layout
  List<Widget> _buildChapterBlocks(
    List<BookContentBlock> blocks, {
    required double fontSize,
    required bool isDark,
    required Color textColor,
    required Color accentColor,
    required Color cardBgColor,
  }) {
    final widgets = <Widget>[];
    int i = 0;
    while (i < blocks.length) {
      if (i + 1 < blocks.length &&
          blocks[i].type == BookBlockType.image &&
          blocks[i + 1].type == BookBlockType.image) {
        final img1 = blocks[i];
        final img2 = blocks[i + 1];
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: BookContentRenderer(
                    block: img1,
                    fontSize: fontSize,
                    isDark: isDark,
                    textColor: textColor,
                    accentColor: accentColor,
                    cardBgColor: cardBgColor,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: BookContentRenderer(
                    block: img2,
                    fontSize: fontSize,
                    isDark: isDark,
                    textColor: textColor,
                    accentColor: accentColor,
                    cardBgColor: cardBgColor,
                  ),
                ),
              ],
            ),
          ),
        );
        i += 2;
      } else {
        widgets.add(
          BookContentRenderer(
            block: blocks[i],
            fontSize: fontSize,
            isDark: isDark,
            textColor: textColor,
            accentColor: accentColor,
            cardBgColor: cardBgColor,
          ),
        );
        i++;
      }
    }
    return widgets;
  }

  void _showTableOfContentsModal(
    BuildContext context, {
    required List<BookChapter> chapters,
    required bool isDark,
    required Color textColor,
    required Color accentColor,
    required Color cardBgColor,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.72,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF18181C) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.2),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 8),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: textColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TABLE OF CONTENTS',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        letterSpacing: 0.8,
                      ),
                    ),
                    Text(
                      '${chapters.length} Chapters',
                      style: TextStyle(
                        fontSize: 12,
                        color: textColor.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(
                color: isDark ? Colors.white12 : Colors.black12,
                height: 1,
              ),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: chapters.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, idx) {
                    final chap = chapters[idx];
                    final isSelected = idx == _selectedChapterIndex;
                    return InkWell(
                      onTap: () {
                        Navigator.pop(ctx);
                        _scrollToChapter(idx);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? accentColor.withValues(alpha: isDark ? 0.2 : 0.1)
                              : (isDark ? const Color(0xFF22242A) : const Color(0xFFF8FAFC)),
                          borderRadius: BorderRadius.circular(12),
                          border: isSelected
                              ? Border.all(color: accentColor, width: 1.5)
                              : null,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? accentColor
                                    : (isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.06)),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${idx + 1}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.white : textColor,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    chap.title,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                      color: textColor,
                                    ),
                                  ),
                                  if (chap.subtitle != null && chap.subtitle!.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      chap.subtitle!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: textColor.withValues(alpha: 0.6),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
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
        width: 44,
        height: 44,
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
                child: Icon(Icons.check_rounded, color: checkColor, size: 22),
              )
            : null,
      ),
    );
  }

  Widget _buildEmptyState(Color textColor, Color cardBgColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.menu_book_rounded,
              size: 48,
              color: textColor.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 14),
            Text(
              widget.book.title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              widget.book.description.isNotEmpty
                  ? widget.book.description
                  : 'Digital Islamic library book.',
              style: TextStyle(
                fontSize: 13.5,
                color: textColor.withValues(alpha: 0.7),
                height: 1.45,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
