import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_islamic_icons/flutter_islamic_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../shared/widgets/app_floating_toast.dart';
import '../data/books_provider.dart';
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

  // Bottom Floating Dock State
  bool _isControlsOpen = false;
  int _activeTab = 0; // 0 = Contents, 1 = Theme, 2 = Text Size

  int _selectedChapterIndex = 0;
  int _readingTheme =
      0; // 0 = Light (default), 1 = Sepia, 2 = OLED Dark, 3 = Charcoal
  double _fontSize = 16.0;

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
    if (_isControlsOpen) {
      setState(() {
        _isControlsOpen = false;
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
      _isControlsOpen = false;
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
    final isDark = _readingTheme == 2 || _readingTheme == 3;
    final bgColor = _bgColors[_readingTheme];
    final cardBgColor = _cardBgColors[_readingTheme];
    final textColor = _textColors[_readingTheme];
    final accentColor = _accentColors[_readingTheme];

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
            padding: const EdgeInsets.only(right: 16),
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
                if (_isControlsOpen) {
                  setState(() => _isControlsOpen = false);
                }
              },
              child: chapters.isEmpty
                  ? _buildEmptyState(textColor, cardBgColor)
                  : SingleChildScrollView(
                      controller: _scrollController,
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(0, 0, 0, bottomInset + 84),
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

                              // 2. Chapter Content starting with Hero Header Box (Key placed here so divider is above and hides on scroll)
                              RepaintBoundary(
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
                                        children: [
                                          // 3. Chapter Content Blocks (Justified text & minimal padding)
                                          ...blocks.map(
                                            (b) => BookContentRenderer(
                                              block: b,
                                              fontSize: _fontSize,
                                              isDark: isDark,
                                              textColor: textColor,
                                              accentColor: accentColor,
                                              cardBgColor: cardBgColor,
                                            ),
                                          ),
                                        ],
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

            // Backdrop dismissal layer when modal card is open
            if (_isControlsOpen)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _isControlsOpen = false),
                  child: Container(
                    color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.25),
                  ),
                ),
              ),

            // Floating Active Control Card (Animated with scale, slide, and fade)
            Positioned(
              left: 14,
              right: 14,
              bottom: bottomInset + 72,
              child: AnimatedScale(
                scale: _isControlsOpen ? 1.0 : 0.88,
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                alignment: Alignment.bottomRight,
                child: AnimatedOpacity(
                  opacity: _isControlsOpen ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: IgnorePointer(
                    ignoring: !_isControlsOpen,
                    child: _buildActiveControlPanel(
                      context,
                      isDark: isDark,
                      textColor: textColor,
                      accentColor: accentColor,
                      cardBgColor: cardBgColor,
                    ),
                  ),
                ),
              ),
            ),

            // Bottom Floating Preference / Settings Action Bar (Circular Buttons)
            Positioned(
              right: 16,
              bottom: bottomInset + 14,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 3 Expanded circular action buttons (Animated)
                  AnimatedOpacity(
                    opacity: _isControlsOpen ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: IgnorePointer(
                      ignoring: !_isControlsOpen,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 1. Contents Circular Button
                          _buildCircularDockButton(
                            icon: Icons.format_list_bulleted_rounded,
                            tooltip: 'Table of Contents',
                            isSelected: _activeTab == 0,
                            isDark: isDark,
                            accentColor: accentColor,
                            onTap: () => setState(() => _activeTab = 0),
                          ),
                          const SizedBox(width: 10),

                          // 2. Theme Circular Button
                          _buildCircularDockButton(
                            icon: Icons.palette_outlined,
                            tooltip: 'Reading Theme',
                            isSelected: _activeTab == 1,
                            isDark: isDark,
                            accentColor: accentColor,
                            onTap: () => setState(() => _activeTab = 1),
                          ),
                          const SizedBox(width: 10),

                          // 3. Text Size Circular Button
                          _buildCircularDockButton(
                            icon: Icons.format_size_rounded,
                            tooltip: 'Text Size',
                            isSelected: _activeTab == 2,
                            isDark: isDark,
                            accentColor: accentColor,
                            onTap: () => setState(() => _activeTab = 2),
                          ),
                          const SizedBox(width: 12),
                        ],
                      ),
                    ),
                  ),

                  // Main Toggle Circular FAB (Open / Close with smooth animation)
                  AnimatedOpacity(
                    opacity: 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: IgnorePointer(
                      ignoring: false,
                      child: _buildCircularDockButton(
                        icon: _isControlsOpen
                            ? Icons.close_rounded
                            : Icons.tune_rounded,
                        tooltip: _isControlsOpen
                            ? 'Close Controls'
                            : 'Reading Controls',
                        isSelected: _isControlsOpen,
                        isDark: isDark,
                        accentColor: accentColor,
                        turns: _isControlsOpen ? 0.25 : 0.0,
                        isMain: true,
                        onTap: () {
                          setState(() {
                            _isControlsOpen = !_isControlsOpen;
                            if (_isControlsOpen) {
                              _activeTab = 0; // Default to Contents
                            }
                          });
                        },
                      ),
                    ),
                  ),
                ],
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

  /// Circular Dock Action Button in the bottom right toolbar (No border)
  Widget _buildCircularDockButton({
    required IconData icon,
    required String tooltip,
    required bool isSelected,
    required bool isDark,
    required Color accentColor,
    required VoidCallback onTap,
    double? turns,
    bool isMain = false,
  }) {
    final bgColor = isMain
        ? (isDark ? const Color(0xFFA3E635) : const Color(0xFF2A531D))
        : isSelected
        ? (isDark ? const Color(0xFFA3E635) : const Color(0xFF2A531D))
        : (isDark ? const Color(0xFF1E1E24) : Colors.white);

    final fgColor = isMain
        ? (isDark ? Colors.black : Colors.white)
        : isSelected
        ? (isDark ? Colors.black : Colors.white)
        : (isDark ? Colors.white70 : const Color(0xFF1A3512));

    final size = isMain ? 50.0 : 44.0;
    final iconSize = isMain ? 24.0 : 20.0;

    Widget iconWidget = Icon(icon, color: fgColor, size: iconSize);

    if (turns != null) {
      iconWidget = AnimatedRotation(
        turns: turns,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        child: iconWidget,
      );
    }

    return Tooltip(
      message: tooltip,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Center(child: iconWidget),
          ),
        ),
      ),
    );
  }

  /// Floating Card Panel containing the active tool: Contents, Theme, or Text Size (No border, expanded height)
  Widget _buildActiveControlPanel(
    BuildContext context, {
    required bool isDark,
    required Color textColor,
    required Color accentColor,
    required Color cardBgColor,
  }) {
    final screenHeight = MediaQuery.of(context).size.height;
    final panelBg = isDark ? const Color(0xFF18181C) : Colors.white;

    return Container(
      constraints: BoxConstraints(maxHeight: screenHeight * 0.72),
      decoration: BoxDecoration(
        color: panelBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.2),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: _activeTab == 0
              ? _buildContentsTab(isDark, textColor, accentColor, cardBgColor)
              : (_activeTab == 1
                    ? _buildThemeTab(isDark, textColor, accentColor)
                    : _buildTextSizeTab(isDark, textColor, accentColor)),
        ),
      ),
    );
  }

  /// 1. Contents Tab (No borders, expanded box size, clean list)
  Widget _buildContentsTab(
    bool isDark,
    Color textColor,
    Color accentColor,
    Color cardBgColor,
  ) {
    final chapters = widget.book.chapters;

    return Column(
      key: const ValueKey('tab_contents'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Heading Banner: Chapter count & title
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF22242A) : const Color(0xFFF1F5F9),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TABLE OF CONTENTS',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? const Color(0xFFA3E635)
                            : const Color(0xFF1A3512),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${chapters.length} Chapters',
                      style: TextStyle(
                        fontSize: 12,
                        color: textColor.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                color: textColor.withValues(alpha: 0.6),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => setState(() => _isControlsOpen = false),
              ),
            ],
          ),
        ),

        // Chapter List (Clean chapter name + 1-line description, no borders)
        Flexible(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            itemCount: chapters.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, idx) {
              final chap = chapters[idx];
              final isSelected = idx == _selectedChapterIndex;

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _scrollToChapter(idx),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDark
                                ? const Color(0xFF282C34)
                                : const Color(0xFFE2E8F0))
                          : (isDark
                                ? const Color(0xFF1E2026)
                                : const Color(0xFFF8FAFC)),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        // Chapter Number Badge
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? accentColor
                                : textColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${idx + 1}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? (isDark ? Colors.black : Colors.white)
                                    : textColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Chapter Name & Description
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                chap.title,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w600,
                                  color: textColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (chap.subtitle != null &&
                                  chap.subtitle!.isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Text(
                                  chap.subtitle!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: textColor.withValues(alpha: 0.65),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),

                        if (isSelected)
                          Icon(
                            Icons.check_circle_rounded,
                            color: accentColor,
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// 2. Theme Tab (Beautiful balanced top padding, no borders)
  Widget _buildThemeTab(bool isDark, Color textColor, Color accentColor) {
    return Padding(
      key: const ValueKey('tab_theme'),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
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
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: textColor.withValues(alpha: 0.7),
                  letterSpacing: 0.8,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                color: textColor.withValues(alpha: 0.6),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => setState(() => _isControlsOpen = false),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Light Mode (White Circle with Dark Green Accent)
              _buildThemeCircle(
                color: const Color(0xFFFFFFFF),
                borderColor: const Color(0xFF2A531D),
                checkColor: const Color(0xFF2A531D),
                isSelected: _readingTheme == 0,
                onTap: () => setState(() => _readingTheme = 0),
              ),
              // Sepia Mode (Warm Cream)
              _buildThemeCircle(
                color: const Color(0xFFFBF0D9),
                borderColor: const Color(0xFF8C4A14),
                checkColor: const Color(0xFF422006),
                isSelected: _readingTheme == 1,
                onTap: () => setState(() => _readingTheme = 1),
              ),
              // OLED Black Mode (Deep Black)
              _buildThemeCircle(
                color: const Color(0xFF0F0F12),
                borderColor: const Color(0xFFA3E635),
                checkColor: const Color(0xFFA3E635),
                isSelected: _readingTheme == 2,
                onTap: () => setState(() => _readingTheme = 2),
              ),
              // Charcoal Slate Mode
              _buildThemeCircle(
                color: const Color(0xFF1E293B),
                borderColor: const Color(0xFF38BDF8),
                checkColor: const Color(0xFF38BDF8),
                isSelected: _readingTheme == 3,
                onTap: () => setState(() => _readingTheme = 3),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 3. Text Size Tab (Smooth slider & A- / A+ buttons)
  Widget _buildTextSizeTab(bool isDark, Color textColor, Color accentColor) {
    return Padding(
      key: const ValueKey('tab_text_size'),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TEXT SIZE',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: textColor.withValues(alpha: 0.7),
                  letterSpacing: 0.8,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_fontSize.toInt()} pt',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              IconButton(
                onPressed: _fontSize > 12.0
                    ? () {
                        setState(() {
                          _fontSize = (_fontSize - 2).clamp(12.0, 32.0);
                        });
                      }
                    : null,
                icon: const Text(
                  'A-',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                style: IconButton.styleFrom(
                  backgroundColor: isDark
                      ? const Color(0xFF222428)
                      : const Color(0xFFF1F5F9),
                  foregroundColor: textColor,
                  padding: const EdgeInsets.all(8),
                ),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 4,
                    activeTrackColor: accentColor,
                    inactiveTrackColor: isDark
                        ? Colors.white12
                        : Colors.grey.shade300,
                    thumbColor: accentColor,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 8,
                    ),
                  ),
                  child: Slider(
                    value: _fontSize,
                    min: 12.0,
                    max: 32.0,
                    divisions: 10,
                    onChanged: (val) {
                      setState(() {
                        _fontSize = val;
                      });
                    },
                  ),
                ),
              ),
              IconButton(
                onPressed: _fontSize < 32.0
                    ? () {
                        setState(() {
                          _fontSize = (_fontSize + 2).clamp(12.0, 32.0);
                        });
                      }
                    : null,
                icon: const Text(
                  'A+',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                style: IconButton.styleFrom(
                  backgroundColor: isDark
                      ? const Color(0xFF222428)
                      : const Color(0xFFF1F5F9),
                  foregroundColor: textColor,
                  padding: const EdgeInsets.all(8),
                ),
              ),
            ],
          ),
        ],
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
