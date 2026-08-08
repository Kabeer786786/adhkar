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

  static Future<void> open(BuildContext context, BookModel book) async {
    // 1. Check if the book has a document / PDF / file URL
    final filePath = book.fileUrl;
    if (filePath != null && filePath.trim().isNotEmpty) {
      final path = filePath.trim();

      // If it's a web URL (http / https)
      if (path.startsWith('http://') || path.startsWith('https://')) {
        final uri = Uri.parse(path);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return;
        }
      }
      // If it's a local file on device (PDF, DOC, DOCX, TXT, etc.)
      else if (File(path).existsSync() || isDocumentFile(path)) {
        final result = await OpenFilex.open(path);
        if (result.type == ResultType.done) {
          return;
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  result.message.isNotEmpty && result.message != 'done'
                      ? 'Opening document: ${result.message}'
                      : 'Opening PDF / Document viewer...',
                ),
              ),
            );
          }
          return;
        }
      }
    }

    // 2. Default: Open in new full-screen reader screen
    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BookReaderScreen(book: book),
        ),
      );
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

  Future<void> _openExternalResource() async {
    final link = widget.book.fileUrl;
    if (link != null && link.trim().isNotEmpty) {
      final path = link.trim();
      if (path.startsWith('http://') || path.startsWith('https://')) {
        final uri = Uri.parse(path);
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else if (File(path).existsSync() || BookReaderScreen.isDocumentFile(path)) {
        final result = await OpenFilex.open(path);
        if (result.type != ResultType.done && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Document viewer result: ${result.message}')),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No external PDF or document file attached to this book.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.book;
    final chapters = book.chapters;
    final bgColor = _bgColors[_readingTheme];
    final textColor = _textColors[_readingTheme];

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
          IconButton(
            icon: Icon(
              Icons.text_decrease_rounded,
              size: 20,
              color: textColor,
            ),
            tooltip: 'Smaller Text',
            onPressed: () {
              if (_fontSize > 12) {
                setState(() => _fontSize -= 2);
              }
            },
          ),
          IconButton(
            icon: Icon(
              Icons.text_increase_rounded,
              size: 20,
              color: textColor,
            ),
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
            const Divider(height: 1),

            // Chapter Navigation Selector
            if (chapters.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                            : 'No chapter text uploaded for this book. Use the button below to open the external document, Adobe Acrobat, or web PDF link.',
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

            // Bottom Control Bar (PDF / Adobe Opener & Progress)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: textColor.withValues(alpha: 0.05),
                border: Border(
                  top: BorderSide(
                    color: textColor.withValues(alpha: 0.1),
                  ),
                ),
              ),
              child: Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _openExternalResource,
                    icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                    label: const Text(
                      'Open PDF / Adobe',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2A531D),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
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
