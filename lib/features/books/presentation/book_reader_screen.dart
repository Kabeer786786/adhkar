import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/books_provider.dart';
import '../domain/book_model.dart';

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

    // If forceExternal or if book openMode is strictly 'external' -> Open via external viewer
    if (forceExternal ||
        book.openMode == 'external' ||
        (book.isCustom && book.openMode != 'in_app')) {
      if (filePath.isNotEmpty) {
        await openExternal(context, filePath);
        return;
      }
    }

    // Default for 'in_app' or 'both' -> Open In-App Reader Screen
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No external document or link available for this book.',
            ),
          ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch URL: $trimmed')),
        );
      }
    } else if (File(trimmed).existsSync() || isDocumentFile(trimmed)) {
      final result = await OpenFilex.open(trimmed);
      if (result.type != ResultType.done && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.message.isNotEmpty && result.message != 'done'
                  ? 'Opening document: ${result.message}'
                  : 'Opening document in external app...',
            ),
          ),
        );
      }
    } else if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('File not found: $trimmed')));
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
  int _selectedChapterIndex = 0;
  double _fontSize = 16.0;
  int _readingTheme = 0; // 0 = Light, 1 = Sepia, 2 = Night Dark

  static const List<Color> _bgColors = [
    Color(0xFFF8FAFC), // Light
    Color(0xFFFBF0D9), // Sepia
    Color(0xFF1E293B), // Night Dark
  ];

  static const List<Color> _textColors = [
    Color(0xFF0F172A), // Light text
    Color(0xFF422006), // Sepia text
    Color(0xFFF8FAFC), // Night text
  ];

  void _openExternalResource() {
    BookReaderScreen.openExternal(context, widget.book.fileUrl);
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.book;
    final chapters = book.chapters;
    final bgColor = _bgColors[_readingTheme];
    final textColor = _textColors[_readingTheme];
    final allowExternal =
        book.openMode != 'in_app' && (book.fileUrl?.isNotEmpty ?? false);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: textColor),
        title: Column(
          children: [
            Text(
              book.title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              book.author,
              style: TextStyle(
                fontSize: 11,
                color: textColor.withValues(alpha: 0.7),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          if (allowExternal)
            IconButton(
              icon: Icon(Icons.open_in_new_rounded, size: 20, color: textColor),
              tooltip: 'Open in External App',
              onPressed: _openExternalResource,
            ),
          IconButton(
            icon: Icon(Icons.text_decrease_rounded, size: 20, color: textColor),
            tooltip: 'Smaller Text',
            onPressed: () {
              if (_fontSize > 12) {
                setState(() => _fontSize -= 2);
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.text_increase_rounded, size: 20, color: textColor),
            tooltip: 'Larger Text',
            onPressed: () {
              if (_fontSize < 28) {
                setState(() => _fontSize += 2);
              }
            },
          ),
          IconButton(
            icon: Icon(
              _readingTheme == 0
                  ? Icons.wb_sunny_outlined
                  : (_readingTheme == 1
                        ? Icons.auto_stories_rounded
                        : Icons.nightlight_round),
              size: 20,
              color: textColor,
            ),
            tooltip: 'Toggle Reading Theme',
            onPressed: () {
              setState(() {
                _readingTheme = (_readingTheme + 1) % 3;
              });
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Divider(
              height: 1,
              color:  Colors.grey.shade300,
            ),

            // Chapter Navigation Selector
            if (chapters.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                color: textColor.withValues(alpha: 0.05),
                child: Row(
                  children: [
                    Icon(Icons.list_alt_rounded, size: 18, color: textColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _selectedChapterIndex,
                          isExpanded: true,
                          dropdownColor: bgColor,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                          items: List.generate(chapters.length, (index) {
                            return DropdownMenuItem(
                              value: index,
                              child: Text(
                                chapters[index].title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedChapterIndex = val;
                                final progress =
                                    (val + 1) / chapters.length.toDouble();
                                ref
                                    .read(userBooksProvider.notifier)
                                    .updateProgress(
                                      bookId: book.id,
                                      progress: progress,
                                      currentPage: val + 1,
                                    );
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Scrollable Book Reading Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (chapters.isNotEmpty) ...[
                      Text(
                        chapters[_selectedChapterIndex].title,
                        style: GoogleFonts.lexend(
                          fontSize: _fontSize + 4,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        chapters[_selectedChapterIndex].content,
                        style: GoogleFonts.lexend(
                          fontSize: _fontSize,
                          height: 1.7,
                          color: textColor,
                        ),
                      ),
                    ] else ...[
                      Text(
                        book.title,
                        style: GoogleFonts.lexend(
                          fontSize: _fontSize + 6,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Author: ${book.author}',
                        style: TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: textColor.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        book.description.isNotEmpty
                            ? book.description
                            : 'Predefined Islamic library book available for digital reading.',
                        style: GoogleFonts.lexend(
                          fontSize: _fontSize,
                          height: 1.7,
                          color: textColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Bottom Control Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: textColor.withValues(alpha: 0.05),
                border: Border(
                  top: BorderSide(color: textColor.withValues(alpha: 0.1)),
                ),
              ),
              child: Row(
                children: [
                  if (allowExternal)
                    ElevatedButton.icon(
                      onPressed: _openExternalResource,
                      icon: const Icon(Icons.open_in_new_rounded, size: 17),
                      label: const Text(
                        'Open External App',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2A531D),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                      ),
                    ),

                  const Spacer(),

                  if (chapters.isNotEmpty)
                    Text(
                      'Chapter ${_selectedChapterIndex + 1} of ${chapters.length}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: textColor.withValues(alpha: 0.8),
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
}
