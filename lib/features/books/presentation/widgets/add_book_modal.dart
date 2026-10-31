import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../shared/providers/app_providers.dart';
import '../../../../shared/widgets/app_floating_toast.dart';
import '../../../../widgets/app_dropdown.dart';
import '../../data/books_provider.dart';
import '../../data/books_repository.dart';
import '../../domain/book_model.dart';
import '../book_reader_screen.dart';
import 'bookshelf_view.dart';

class AddBookModal extends ConsumerStatefulWidget {
  const AddBookModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddBookModal(),
    );
  }

  @override
  ConsumerState<AddBookModal> createState() => _AddBookModalState();
}

class _AddBookModalState extends ConsumerState<AddBookModal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _librarySearchController =
      TextEditingController();

  // Custom Book Form Controllers
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Picked Document File State
  String? _selectedDocumentPath;
  String? _selectedDocumentName;
  int? _selectedDocumentSize;

  String _selectedCategory = 'Hadith';
  final List<String> _categories = [
    'Hadith',
    'Seerah',
    'Fiqh',
    'Aqeedah',
    'Tazkiyah',
    'General',
  ];
  String? _customCoverImagePath;
  int _selectedPresetGradientIndex = 0;

  static const List<List<Color>> _presetGradients = [
    [Color(0xFF1E3816), Color(0xFF2A531D)],
    [Color(0xFFC0392B), Color(0xFF8E44AD)],
    [Color(0xFFD97724), Color(0xFF92400E)],
    [Color(0xFF0F766E), Color(0xFF134E4A)],
    [Color(0xFF1E3A8A), Color(0xFF1D4ED8)],
    [Color(0xFF7C2D12), Color(0xFF451A03)],
  ];

  OverlayEntry? _activeToastOverlay;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final savedCats = ref.read(storageServiceProvider).getCustomCategories('books');
    for (final cat in savedCats) {
      if (!_categories.contains(cat)) {
        _categories.add(cat);
      }
    }
  }

  @override
  void dispose() {
    _activeToastOverlay?.remove();
    _tabController.dispose();
    _librarySearchController.dispose();
    _titleController.dispose();
    _authorController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDocumentFile() async {
    try {
      final FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
      );

      if (result != null && result.files.single.path != null) {
        final file = result.files.single;
        setState(() {
          _selectedDocumentPath = file.path;
          _selectedDocumentName = file.name;
          _selectedDocumentSize = file.size;

          if (_titleController.text.trim().isEmpty) {
            final cleanName =
                file.name.replaceAll(RegExp(r'\.[^.]+$'), '').replaceAll('_', ' ');
            _titleController.text = cleanName;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        AppFloatingToast.showError(
          context,
          message: 'Error picking document: $e',
        );
      }
    }
  }

  Future<void> _pickCoverImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _customCoverImagePath = image.path;
      });
    }
  }

  void _submitCustomBook() {
    if (_formKey.currentState?.validate() ?? false) {
      final newBook = BookModel(
        id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
        title: _titleController.text.trim(),
        author: _authorController.text.trim().isNotEmpty
            ? _authorController.text.trim()
            : 'Custom Author',
        category: _selectedCategory,
        description: _descriptionController.text.trim(),
        coverUrl: _customCoverImagePath ?? '',
        coverGradient: _presetGradients[_selectedPresetGradientIndex],
        fileUrl: _selectedDocumentPath,
        isCustom: true,
        isAdded: true,
      );

      ref.read(userBooksProvider.notifier).addBook(newBook);
      Navigator.pop(context);
      AppFloatingToast.showAdded(
        context,
        message: 'Added "${newBook.title}" to bookshelf',
      );
    }
  }

  void _toggleBook(BookModel book, bool isAdded) {
    if (isAdded) {
      ref.read(userBooksProvider.notifier).removeBook(book.id);
      AppFloatingToast.showRemoved(context, message: 'Removed "${book.title}" from bookshelf');
    } else {
      ref.read(userBooksProvider.notifier).addBook(book);
      AppFloatingToast.showAdded(context, message: 'Added "${book.title}" to bookshelf');
    }
  }

  void _showBookPreviewModal(BuildContext context, BookModel book, bool isAdded) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF18181B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Drag Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF3F3F46) : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // 3D Miniature Cover
              ThreeDBookCoverWidget(
                book: book,
                width: 95,
                height: 132,
                fontSize: 11,
              ),
              const SizedBox(height: 16),

              // Category Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF18A74C).withValues(alpha: 0.15)
                      : const Color(0xFF2A531D).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  book.category.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF2A531D),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Title
              Text(
                book.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),

              // Author
              Text(
                'By ${book.author}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: isDark ? Colors.white70 : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 14),

              // Description
              Text(
                book.description.isNotEmpty
                    ? book.description
                    : 'Classic Islamic literature text available in your digital library bookshelf.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                  height: 1.4,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 24),

              // Action Buttons Row
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _toggleBook(book, isAdded);
                      },
                      icon: Icon(
                        isAdded
                            ? Icons.check_circle_rounded
                            : Icons.add_circle_outline_rounded,
                        color: isAdded
                            ? const Color(0xFF16A34A)
                            : (isDark ? const Color(0xFF18A74C) : const Color(0xFF2A531D)),
                      ),
                      label: Text(
                        isAdded ? 'Added to Shelf' : 'Add to Shelf',
                        style: TextStyle(
                          color: isAdded
                              ? const Color(0xFF16A34A)
                              : (isDark ? const Color(0xFF18A74C) : const Color(0xFF2A531D)),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(
                          color: isAdded
                              ? const Color(0xFF16A34A)
                              : (isDark ? const Color(0xFF18A74C) : const Color(0xFF2A531D)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        BookReaderScreen.open(context, book);
                      },
                      icon: const Icon(Icons.auto_stories_rounded, size: 18),
                      label: const Text(
                        'Read Now',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? const Color(0xFF18A74C) : const Color(0xFF2A531D),
                        foregroundColor: isDark ? const Color(0xFF0F0F12) : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userBooksState = ref.watch(userBooksProvider);
    final userBooks = userBooksState.value ?? [];

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18181B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF3F3F46) : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),

          // Header Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Add Books to Shelf',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF2A531D),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    color: isDark ? Colors.white70 : Colors.grey.shade700,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Tab Bar
          TabBar(
            controller: _tabController,
            labelColor: isDark ? const Color(0xFF18A74C) : const Color(0xFF2A531D),
            unselectedLabelColor: isDark ? Colors.white38 : Colors.grey,
            indicatorColor: isDark ? const Color(0xFF18A74C) : const Color(0xFF2A531D),
            indicatorWeight: 3,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
            tabs: const [
              Tab(text: 'Islamic Library'),
              Tab(text: 'Upload Custom Book'),
            ],
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Pre-built Islamic Library
                _buildLibraryTab(userBooks, isDark),

                // Tab 2: Custom Book Upload Form
                _buildCustomUploadTab(isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLibraryTab(List<BookModel> userBooks, bool isDark) {
    final prebuiltList = BooksRepository.prebuiltLibrary;
    final query = _librarySearchController.text.trim().toLowerCase();

    final filteredList = prebuiltList.where((b) {
      if (query.isEmpty) return true;
      return b.title.toLowerCase().contains(query) ||
          b.author.toLowerCase().contains(query);
    }).toList();

    return Column(
      children: [
        // Search Input Bar inside library modal
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F0F12) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              border: isDark ? Border.all(color: const Color(0xFF27272A)) : null,
            ),
            child: TextField(
              controller: _librarySearchController,
              textAlignVertical: TextAlignVertical.center,
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                fontSize: 14,
              ),
              onChanged: (val) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search library books by title or author...',
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white60 : Colors.grey.shade500,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: isDark ? const Color(0xFF18A74C) : const Color(0xFF2A531D),
                  size: 18,
                ),
                suffixIcon: _librarySearchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear_rounded,
                          size: 16,
                          color: isDark ? Colors.white70 : Colors.grey,
                        ),
                        onPressed: () {
                          _librarySearchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ),

        // Library Items List
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).size.height * 0.1,
            ),
            itemCount: filteredList.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final book = filteredList[index];
              final isAdded = userBooks.any((b) => b.id == book.id);

              return Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F0F12) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isAdded
                        ? (isDark ? const Color(0xFF18A74C) : const Color(0xFF2A531D).withValues(alpha: 0.3))
                        : (isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0)),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.2)
                          : Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _showBookPreviewModal(context, book, isAdded),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          // 3D Cover Thumbnail
                          ThreeDBookCoverWidget(
                            book: book,
                            width: 90,
                            height: 115,
                            fontSize: 7,
                          ),
                          const SizedBox(width: 12),

                          // Book Name & Author (Clean layout matching Adhkar modal)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  book.title,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  book.author,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                    fontStyle: FontStyle.italic,
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),

                          // Circular Checkbox at Top-Right (matching Adhkar / Tasbeeh modal)
                          GestureDetector(
                            onTap: () => _toggleBook(book, isAdded),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                isAdded
                                    ? Icons.check_circle_rounded
                                    : Icons.circle_outlined,
                                size: 26,
                                color: isAdded
                                    ? (isDark ? const Color(0xFF18A74C) : const Color(0xFF2A531D))
                                    : (isDark ? Colors.white24 : Colors.grey.shade400),
                              ),
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildCustomUploadTab(bool isDark) {
    final hasDocument = _selectedDocumentPath != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(
        left: 20,
        right: 20,
        top:20, 
        bottom: 60
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Prominent Document Upload Picker Card
            Text(
              'Document / Book File *',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),

            InkWell(
              onTap: _pickDocumentFile,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: hasDocument
                      ? (isDark ? const Color(0xFF14532D).withValues(alpha: 0.3) : const Color(0xFFF0FDF4))
                      : (isDark ? const Color(0xFF0F0F12) : const Color(0xFFF8FAFC)),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: hasDocument
                        ? (isDark ? const Color(0xFF18A74C) : const Color(0xFF16A34A))
                        : (isDark ? const Color(0xFF27272A) : const Color(0xFFCBD5E1)),
                    width: hasDocument ? 1.8 : 1.2,
                  ),
                ),
                child: hasDocument
                    ? Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF166534).withValues(alpha: 0.4)
                                  : const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              _selectedDocumentName!.toLowerCase().endsWith('.pdf')
                                  ? Icons.picture_as_pdf_rounded
                                  : Icons.description_rounded,
                              color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF16A34A),
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedDocumentName ?? 'Selected Document',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _selectedDocumentSize != null
                                      ? '${(_selectedDocumentSize! / (1024 * 1024)).toStringAsFixed(2)} MB • Ready to upload'
                                      : 'Document Attached',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF16A34A),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.swap_horiz_rounded,
                              color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF16A34A),
                            ),
                            onPressed: _pickDocumentFile,
                            tooltip: 'Change Document',
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          Icon(
                            Icons.cloud_upload_rounded,
                            size: 38,
                            color: isDark ? const Color(0xFF18A74C) : const Color(0xFF2A531D),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Click to Upload PDF, Word, or Text File',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Supports PDF, DOC, DOCX, TXT formats from device',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white60 : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Title Input
            TextFormField(
              controller: _titleController,
              style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A)),
              decoration: InputDecoration(
                filled: true,
                fillColor: isDark ? const Color(0xFF0F0F12) : null,
                labelText: 'Book Title *',
                labelStyle: TextStyle(color: isDark ? Colors.white70 : null),
                hintText: 'e.g. Sahih Fiqh as-Sunnah',
                hintStyle: TextStyle(color: isDark ? Colors.white38 : null),
                prefixIcon: Icon(
                  Icons.book_rounded,
                  color: isDark ? const Color(0xFF18A74C) : null,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark ? const Color(0xFF27272A) : const Color(0xFFCBD5E1),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark ? const Color(0xFF18A74C) : const Color(0xFF2A531D),
                    width: 1.5,
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Please enter book title' : null,
            ),
            const SizedBox(height: 14),

            // Author Input
            TextFormField(
              controller: _authorController,
              style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A)),
              decoration: InputDecoration(
                filled: true,
                fillColor: isDark ? const Color(0xFF0F0F12) : null,
                labelText: 'Author Name (Optional)',
                labelStyle: TextStyle(color: isDark ? Colors.white70 : null),
                hintText: 'e.g. Scholar Name',
                hintStyle: TextStyle(color: isDark ? Colors.white38 : null),
                prefixIcon: Icon(
                  Icons.person_outline_rounded,
                  color: isDark ? const Color(0xFF18A74C) : null,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark ? const Color(0xFF27272A) : const Color(0xFFCBD5E1),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark ? const Color(0xFF18A74C) : const Color(0xFF2A531D),
                    width: 1.5,
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Category Selection Dropdown
            AppDropdown<String>(
              label: 'Category',
              value: _selectedCategory,
              prefixIcon: Icons.category_outlined,
              onAddCustomCategory: () async {
                final newCatName = await AppDropdown.showAddCustomCategoryDialog(
                  context,
                  title: 'Add Custom Category',
                  hintText: 'e.g. Tafseer & Commentary',
                  icon: Icons.menu_book_rounded,
                );
                if (newCatName != null && newCatName.isNotEmpty) {
                  ref.read(storageServiceProvider).saveCustomCategory('books', newCatName);
                  setState(() {
                    if (!_categories.contains(newCatName)) {
                      _categories.add(newCatName);
                    }
                    _selectedCategory = newCatName;
                  });
                }
                return newCatName;
              },
              items: _categories
                  .map(
                    (cat) => AppDropdownItem<String>(
                      value: cat,
                      label: cat,
                      icon: Icons.book_outlined,
                    ),
                  )
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedCategory = val;
                  });
                }
              },
            ),
            const SizedBox(height: 14),

            // Description Input
            TextFormField(
              controller: _descriptionController,
              maxLines: 2,
              style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A)),
              decoration: InputDecoration(
                filled: true,
                fillColor: isDark ? const Color(0xFF0F0F12) : null,
                labelText: 'Description / Notes (Optional)',
                labelStyle: TextStyle(color: isDark ? Colors.white70 : null),
                hintText: 'Brief summary of the book...',
                hintStyle: TextStyle(color: isDark ? Colors.white38 : null),
                prefixIcon: Icon(
                  Icons.notes_rounded,
                  color: isDark ? const Color(0xFF18A74C) : null,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark ? const Color(0xFF27272A) : const Color(0xFFCBD5E1),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark ? const Color(0xFF18A74C) : const Color(0xFF2A531D),
                    width: 1.5,
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Cover Image Selection
            Text(
              'Book Cover Styling',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _pickCoverImage,
                  icon: Icon(
                    Icons.image_search_rounded,
                    color: isDark ? const Color(0xFF18A74C) : null,
                  ),
                  label: Text(
                    _customCoverImagePath != null
                        ? 'Image Selected'
                        : 'Pick Cover Image',
                    style: TextStyle(color: isDark ? Colors.white : null),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: isDark ? const Color(0xFF27272A) : const Color(0xFFCBD5E1),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Gradient Palette Selection
            Text(
              'Or Pick Preset 3D Cover Color:',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white60 : Colors.grey,
              ),
            ),
            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(_presetGradients.length, (index) {
                final isSelected = _selectedPresetGradientIndex == index;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedPresetGradientIndex = index;
                      _customCoverImagePath = null;
                    });
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: _presetGradients[index],
                      ),
                      border: isSelected
                          ? Border.all(
                              color: isDark ? const Color(0xFF18A74C) : Colors.black,
                              width: 3,
                            )
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check_rounded,
                            color: Colors.white, size: 20)
                        : null,
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),

            // Submit Add Book Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _submitCustomBook,
                icon: const Icon(Icons.add_rounded),
                label: const Text(
                  'Add to My Bookshelf',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? const Color(0xFF18A74C) : const Color(0xFF2A531D),
                  foregroundColor: isDark ? const Color(0xFF0F0F12) : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
