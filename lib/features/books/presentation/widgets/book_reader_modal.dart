import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/books_provider.dart';
import '../../domain/book_model.dart';

class BookReaderModal extends ConsumerStatefulWidget {
  final BookModel book;

  const BookReaderModal({super.key, required this.book});

  static void show(BuildContext context, BookModel book) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BookReaderModal(book: book),
    );
  }

  @override
  ConsumerState<BookReaderModal> createState() => _BookReaderModalState();
}

class _BookReaderModalState extends ConsumerState<BookReaderModal> {
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

  @override
  void initState() {
    super.initState();
  }

  Future<void> _openExternalResource() async {
    final link = widget.book.fileUrl;
    if (link != null && link.isNotEmpty) {
      final uri = Uri.parse(link);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      // } else {
      //   if (mounted) {
      //     ScaffoldMessenger.of(context).showSnackBar(
      //       SnackBar(content: Text('Could not open link: $link')),
      //     );
      //   }
      // }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No external PDF or document link provided for this book.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.book;
    final chapters = book.chapters;

    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: BoxDecoration(
        color: _bgColors[_readingTheme],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Reader Toolbar Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    color: _textColors[_readingTheme],
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        book.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: _textColors[_readingTheme],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        book.author,
                        style: TextStyle(
                          fontSize: 11,
                          color: _textColors[_readingTheme].withValues(alpha: 0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Font Size Controls & Reading Theme Toggle
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.text_decrease_rounded,
                        size: 20,
                        color: _textColors[_readingTheme],
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
                        color: _textColors[_readingTheme],
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
                        color: _textColors[_readingTheme],
                      ),
                      tooltip: 'Toggle Reading Theme',
                      onPressed: () {
                        setState(() {
                          _readingTheme = (_readingTheme + 1) % 3;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Chapter Navigation Bar
          if (chapters.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: _textColors[_readingTheme].withValues(alpha: 0.05),
              child: Row(
                children: [
                  const Icon(Icons.list_alt_rounded, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _selectedChapterIndex,
                        isExpanded: true,
                        dropdownColor: _bgColors[_readingTheme],
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _textColors[_readingTheme],
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
                              ref.read(userBooksProvider.notifier).updateProgress(
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

          // Scrollable Chapter Reading Area
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
                        color: _textColors[_readingTheme],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      chapters[_selectedChapterIndex].content,
                      style: GoogleFonts.lexend(
                        fontSize: _fontSize,
                        height: 1.7,
                        color: _textColors[_readingTheme],
                      ),
                    ),
                  ] else ...[
                    // Default description or custom book info
                    Text(
                      book.title,
                      style: GoogleFonts.lexend(
                        fontSize: _fontSize + 6,
                        fontWeight: FontWeight.bold,
                        color: _textColors[_readingTheme],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Author: ${book.author}',
                      style: TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: _textColors[_readingTheme].withValues(alpha: 0.8),
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
                        color: _textColors[_readingTheme],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Bottom Bar (Progress & External PDF / Adobe Opener)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: _textColors[_readingTheme].withValues(alpha: 0.05),
              border: Border(
                top: BorderSide(
                  color: _textColors[_readingTheme].withValues(alpha: 0.1),
                ),
              ),
            ),
            child: Row(
              children: [
                // External App / Adobe Opener Button
                ElevatedButton.icon(
                  onPressed: _openExternalResource,
                  icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                  label: const Text(
                    'Open PDF / Adobe',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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

                // Chapter Page Progress
                if (chapters.isNotEmpty)
                  Text(
                    'Chapter ${_selectedChapterIndex + 1} of ${chapters.length}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _textColors[_readingTheme].withValues(alpha: 0.8),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
