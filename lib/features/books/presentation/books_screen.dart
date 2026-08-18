import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/app_header_bar.dart';
import '../../../shared/widgets/app_floating_toast.dart';
import '../data/books_provider.dart';
import '../domain/book_model.dart';
import 'book_reader_screen.dart';
import 'widgets/add_book_modal.dart';
import 'widgets/book_filter_modal.dart';
import 'widgets/bookshelf_view.dart';

class BooksScreen extends ConsumerWidget {
  const BooksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(userBooksProvider);
    final searchQuery = ref.watch(bookSearchQueryProvider);
    final selectedCategory = ref.watch(selectedBookCategoryProvider);
    final sortOption = ref.watch(bookSortOptionProvider);

    final isFilterActive = selectedCategory != 'All' || sortOption != 'Default';

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF), // Studio light wall background
      appBar: AppHeaderBar(
        title: 'MY BOOKSHELF',
        showBackButton: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.add_circle_outline_rounded,
              color: Color(0xFF2A531D),
              size: 26,
            ),
            tooltip: 'Add Books to Shelf',
            onPressed: () => AddBookModal.show(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar & Preferences Filter Button Row (Minimal gap & compact height)
            Padding(
              padding: const EdgeInsets.only(
                left: 14,
                right: 14,
                top: 2,
                bottom: 6,
              ),
              child: Row(
                children: [
                  // Search TextField
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFD1D5DB).withValues(alpha: 0.7),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        textAlignVertical: TextAlignVertical.center,
                        onChanged: (val) {
                          ref.read(bookSearchQueryProvider.notifier).state =
                              val;
                        },
                        decoration: InputDecoration(
                          hintText: 'Search books by title or author...',
                          hintStyle: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade400,
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: Color(0xFF2A531D),
                            size: 19,
                          ),
                          suffixIcon: searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.clear_rounded,
                                    size: 16,
                                  ),
                                  onPressed: () {
                                    ref
                                            .read(
                                              bookSearchQueryProvider.notifier,
                                            )
                                            .state =
                                        '';
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                  ),

                  // Minimal space gap (6px) between Search and Filter
                  const SizedBox(width: 6),

                  // Filter & Sort Preferences Button
                  InkWell(
                    onTap: () => BookFilterModal.show(context),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: isFilterActive
                            ? const Color(0xFF2A531D)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isFilterActive
                              ? const Color(0xFF2A531D)
                              : const Color(0xFFD1D5DB).withValues(alpha: 0.7),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.tune_rounded,
                            size: 18,
                            color: isFilterActive
                                ? Colors.white
                                : const Color(0xFF2A531D),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            selectedCategory != 'All'
                                ? selectedCategory
                                : 'Filter',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: isFilterActive
                                  ? Colors.white
                                  : const Color(0xFF334155),
                            ),
                          ),
                          if (isFilterActive) ...[
                            const SizedBox(width: 4),
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFACC15),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 3D Bookshelf Cabinet Grid Area
            Expanded(
              child: booksAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: Color(0xFF2A531D)),
                ),
                error: (err, _) => Center(
                  child: Text(
                    'Error loading bookshelf: $err',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
                data: (allBooks) {
                  // 1. Filter by Category
                  List<BookModel> filtered = List.from(allBooks);

                  if (selectedCategory != 'All') {
                    if (selectedCategory == 'Custom') {
                      filtered = filtered.where((b) => b.isCustom).toList();
                    } else {
                      filtered = filtered
                          .where(
                            (b) =>
                                b.category.toLowerCase() ==
                                selectedCategory.toLowerCase(),
                          )
                          .toList();
                    }
                  }

                  // 2. Filter by Search Query
                  if (searchQuery.trim().isNotEmpty) {
                    final q = searchQuery.trim().toLowerCase();
                    filtered = filtered.where((b) {
                      return b.title.toLowerCase().contains(q) ||
                          b.author.toLowerCase().contains(q);
                    }).toList();
                  }

                  // 3. Sort Order
                  if (sortOption == 'Title (A - Z)') {
                    filtered.sort((a, b) => a.title.compareTo(b.title));
                  } else if (sortOption == 'Author (A - Z)') {
                    filtered.sort((a, b) => a.author.compareTo(b.author));
                  }

                  return BookshelfView(
                    books: filtered,
                    onBookTap: (book) {
                      _showBookDetailsModal(context, ref, book);
                    },
                    onBookLongPress: (book) {
                      _showBookDetailsModal(context, ref, book);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBookDetailsModal(
    BuildContext context,
    WidgetRef ref,
    BookModel book,
  ) {
    showModalBottomSheet(
      context: context,

      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // 3D Cover Thumbnail Preview
              ThreeDBookCoverWidget(
                book: book,
                width: 95,
                height: 132,
                fontSize: 11,
              ),
              const SizedBox(height: 16),

              // Category Tag Badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A531D).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  book.category.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2A531D),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Book Title
              Text(
                book.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),

              // Author Name
              Text(
                'By ${book.author}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 14),
              
              // Description
              Text(
                book.description.isNotEmpty
                    ? book.description
                    : 'Classic Islamic literature text available in your digital library bookshelf.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF475569),
                  height: 1.4,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 24),

              // Action Buttons Row (Read In App vs External App)
              Row(
                children: [
                  // Remove Button
                  IconButton(
                    onPressed: () {
                      ref.read(userBooksProvider.notifier).removeBook(book.id);
                      Navigator.pop(context);
                      AppFloatingToast.showRemoved(
                        context,
                        message: 'Removed "${book.title}" from bookshelf',
                      );
                    },
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.redAccent,
                    ),
                    tooltip: 'Remove from Bookshelf',
                  ),
                  const SizedBox(width: 8),

                  // Render Reading Action Buttons based on book.openMode ('in_app', 'external', 'both')
                  if (book.openMode == 'in_app') ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          BookReaderScreen.open(context, book);
                        },
                        icon: const Icon(
                          Icons.auto_stories_rounded, 
                          size: 18,
                        ),
                        label: const Text(
                          'Read In App',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2A531D),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ] else if (book.openMode == 'external') ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          BookReaderScreen.openExternal(context, book.fileUrl);
                        },
                        icon: const Icon(
                          Icons.open_in_new_rounded,
                          size: 18,
                        ),
                        label: const Text(
                          'Open External App',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2A531D),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    // 'both' mode: Show both External App and Read In App options
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          BookReaderScreen.openExternal(context, book.fileUrl);
                        },
                        icon: const Icon(
                          Icons.open_in_new_rounded,
                          size: 16,
                          color: Color(0xFF2A531D),
                        ),
                        label: const Text(
                          'External App',
                          style: TextStyle(
                            color: Color(0xFF2A531D),
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: const BorderSide(color: Color(0xFF2A531D)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          BookReaderScreen.open(context, book);
                        },
                        icon: const Icon(
                          Icons.auto_stories_rounded,
                          size: 18,
                        ),
                        label: const Text(
                          'Read In App',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2A531D),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),


              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}
