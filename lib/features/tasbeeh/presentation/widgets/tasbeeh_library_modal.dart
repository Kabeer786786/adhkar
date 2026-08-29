import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/models/tasbeeh_item.dart';
import '../../../../shared/widgets/app_floating_toast.dart';

enum TasbeehModalView { library, details, form }

class TasbeehLibraryModal extends StatefulWidget {
  final List<TasbeehItem> currentItems;
  final Function(TasbeehItem item) onAddItem;
  final Function(String itemId) onRemoveItem;
  final Function(TasbeehItem newItem) onCreateCustom;

  const TasbeehLibraryModal({
    super.key,
    required this.currentItems,
    required this.onAddItem,
    required this.onRemoveItem,
    required this.onCreateCustom,
  });

  static void show(
    BuildContext context, {
    required List<TasbeehItem> currentItems,
    required Function(TasbeehItem item) onAddItem,
    required Function(String itemId) onRemoveItem,
    required Function(TasbeehItem newItem) onCreateCustom,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.90,
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: TasbeehLibraryModal(
          currentItems: currentItems,
          onAddItem: onAddItem,
          onRemoveItem: onRemoveItem,
          onCreateCustom: onCreateCustom,
        ),
      ),
    );
  }

  @override
  State<TasbeehLibraryModal> createState() => _TasbeehLibraryModalState();
}

class _TasbeehLibraryModalState extends State<TasbeehLibraryModal> {
  final TextEditingController _searchController = TextEditingController();
  late List<TasbeehItem> _activeItems;

  // View state: library, details, form
  TasbeehModalView _currentView = TasbeehModalView.library;
  TasbeehItem? _selectedItemForDetails;

  // Form Controllers
  late TextEditingController _formTextArController;
  late TextEditingController _formTextEnController;
  late TextEditingController _formTargetController;
  late TextEditingController _formDescController;
  late int _formSelectedColorValue;

  static const List<int> colorOptions = [
    0xFF0284C7, // Sky Blue
    0xFF16A34A, // Emerald Green
    0xFFEA580C, // Orange
    0xFF9333EA, // Purple
    0xFF059669, // Teal
    0xFFD97724, // Gold
    0xFFDC2626, // Crimson
    0xFF2563EB, // Royal Blue
  ];

  @override
  void initState() {
    super.initState();
    _activeItems = List.from(widget.currentItems);
    _formTextArController = TextEditingController();
    _formTextEnController = TextEditingController();
    _formTargetController = TextEditingController(text: '33');
    _formDescController = TextEditingController();
    _formSelectedColorValue = colorOptions.first;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _formTextArController.dispose();
    _formTextEnController.dispose();
    _formTargetController.dispose();
    _formDescController.dispose();
    super.dispose();
  }

  bool _isItemPinned(String itemId) {
    return _activeItems.any((i) => i.id == itemId);
  }

  void _toggleItem(TasbeehItem item) {
    final isPinned = _isItemPinned(item.id);
    if (isPinned) {
      widget.onRemoveItem(item.id);
      setState(() {
        _activeItems.removeWhere((i) => i.id == item.id);
      });
      AppFloatingToast.showRemoved(context, message: 'Removed');
    } else {
      widget.onAddItem(item);
      setState(() {
        _activeItems.add(item);
      });
      AppFloatingToast.showAdded(context, message: 'Added');
    }
  }

  void _openFormView() {
    _formTextArController.clear();
    _formTextEnController.clear();
    _formTargetController.text = '33';
    _formDescController.clear();
    _formSelectedColorValue = colorOptions.first;

    setState(() {
      _currentView = TasbeehModalView.form;
    });
  }

  void _openDetailsView(TasbeehItem item) {
    setState(() {
      _selectedItemForDetails = item;
      _currentView = TasbeehModalView.details;
    });
  }

  void _submitForm() {
    final ar = _formTextArController.text.trim();
    final en = _formTextEnController.text.trim();
    final target = int.tryParse(_formTargetController.text.trim()) ?? 33;
    final desc = _formDescController.text.trim();

    if (ar.isEmpty || en.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter Arabic text and English title.'),
        ),
      );
      return;
    }

    final newItem = TasbeehItem(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      textAr: ar,
      textEn: en,
      description: desc,
      targetGoal: target > 0 ? target : 33,
      colorValue: _formSelectedColorValue,
      isCustom: true,
    );

    HapticFeedback.lightImpact();
    widget.onCreateCustom(newItem);
    setState(() {
      _activeItems.add(newItem);
      _currentView = TasbeehModalView.library;
    });
  }

  InputDecoration _formInputDecoration(
    String label,
    String hint,
    IconData icon,
  ) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: const Color(0xFF2A531D)),
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF2A531D), width: 1.8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Content View Switcher
          Flexible(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _buildCurrentViewContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentViewContent() {
    switch (_currentView) {
      case TasbeehModalView.library:
        return _buildLibraryView();
      case TasbeehModalView.details:
        return _buildDetailsView();
      case TasbeehModalView.form:
        return _buildFormView();
    }
  }

  // --- 1. LIBRARY VIEW ---
  Widget _buildLibraryView() {
    final query = _searchController.text.trim().toLowerCase();
    final allLibraryItems = TasbeehItem.defaults;
    final filteredItems = allLibraryItems.where((item) {
      return query.isEmpty ||
          item.textEn.toLowerCase().contains(query) ||
          item.textAr.contains(query) ||
          item.description.toLowerCase().contains(query);
    }).toList();

    return Padding(
      key: const ValueKey('library_view'),
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tasbeeh Library',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2A531D),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _openFormView,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Create Tasbeeh'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2A531D),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Search Field
          TextField(
            controller: _searchController,
            onChanged: (val) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search Tasbeeh counters...',
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: Color(0xFF2A531D),
              ),
              filled: true,
              fillColor: const Color(0xFFF9F9F9),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 8,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Platform Tasbeeh Cards List (Simple Box Card Design with Right Top Checkbox & Right Bottom Target Count Badge)
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              itemCount: filteredItems.length,
              itemBuilder: (context, index) {
                final item = filteredItems[index];
                final isPinned = _isItemPinned(item.id);

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => _openDetailsView(item),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: item.color.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: item.color.withValues(alpha: 0.15),
                            width: 1.0,
                          ),
                        ),
                        child: Stack(
                          children: [
                            // Top Right Circle Checkbox
                            Positioned(
                              top: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () => _toggleItem(item),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.all(2),
                                  child: Icon(
                                    isPinned
                                        ? Icons.check_circle_rounded
                                        : Icons.circle_outlined,
                                    size: 24,
                                    color: isPinned
                                        ? item.color
                                        : item.color.withValues(alpha: 0.45),
                                  ),
                                ),
                              ),
                            ),

                            // Card Text Content
                            Padding(
                              padding: const EdgeInsets.only(
                                right: 66.0,
                                bottom: 14.0,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.textAr,
                                    textDirection: TextDirection.rtl,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.arabicBody(
                                      fontSize: 20,
                                      color: const Color(0xFF1B5E20),
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.textEn,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: item.color,
                                    ),
                                  ),
                                  if (item.effectiveTranslation.isNotEmpty) ...[
                                    const SizedBox(height: 3),
                                    Text(
                                      item.effectiveTranslation,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic,
                                        color: Colors.grey.shade700,
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                  if (item.description.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      item.description,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: Colors.grey.shade700,
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            // Right Bottom Corner Target Goal Badge
                            Positioned(
                              bottom: 12,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: item.color.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: item.color.withValues(alpha: 0.2),
                                    width: 1.0,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.flag_rounded,
                                      size: 13,
                                      color: item.color,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${item.targetGoal}x',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.bold,
                                        color: item.color,
                                      ),
                                    ),
                                  ],
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
      ),
    );
  }

  // --- 2. DETAILS VIEW ---
  Widget _buildDetailsView() {
    final item = _selectedItemForDetails!;
    final isPinned = _isItemPinned(item.id);

    return SingleChildScrollView(
      key: const ValueKey('details_view'),
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // Header with Back Button
            Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: Color(0xFF2A531D),
                  ),
                  onPressed: () {
                    setState(() {
                      _currentView = TasbeehModalView.library;
                    });
                  },
                ),
                Expanded(
                  child: Text(
                    item.textEn,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: item.color,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 1),
            const SizedBox(height: 14),

            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Large Arabic Text
                  Text(
                    item.textAr,
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: AppTypography.arabicBody(
                      fontSize: 26,
                      height: 1.7,
                      color: const Color(0xFF1B5E20),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Description / Virtues
                  Text(
                    item.description,
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.4,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Target Goal Badge
                  Row(
                    children: [
                      Chip(
                        avatar: const Icon(
                          Icons.flag_rounded,
                          size: 15,
                          color: Colors.white,
                        ),
                        label: Text('Target Goal: ${item.targetGoal}x'),
                        backgroundColor: item.color,
                        labelStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Selection Action Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _toggleItem(item);
                        setState(() {
                          _currentView = TasbeehModalView.library;
                        });
                      },
                      icon: Icon(
                        isPinned
                            ? Icons.check_circle_rounded
                            : Icons.add_circle_rounded,
                      ),
                      label: Text(
                        isPinned
                            ? 'Remove from Main Screen'
                            : 'Add to Main Screen',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isPinned
                            ? Colors.red.shade700
                            : const Color(0xFF2A531D),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // --- 3. FORM VIEW ---
  Widget _buildFormView() {
    return SingleChildScrollView(
      key: const ValueKey('form_view'),
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // Header with Back Button
            Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: Color(0xFF2A531D),
                  ),
                  onPressed: () {
                    setState(() {
                      _currentView = TasbeehModalView.library;
                    });
                  },
                ),
                const Text(
                  'Add Custom Tasbeeh',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2A531D),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Arabic Text Field
            TextField(
              controller: _formTextArController,
              textDirection: TextDirection.rtl,
              style: AppTypography.arabicBody(
                fontSize: 18,
              ),
              decoration: _formInputDecoration(
                'Arabic Text *',
                'سُبۡحَانَ اللَّهِ',
                Icons.auto_awesome_rounded,
              ),
            ),
            const SizedBox(height: 12),

            // English Transliteration Field
            TextField(
              controller: _formTextEnController,
              decoration: _formInputDecoration(
                'English Transliteration / Title *',
                'SubhanAllah',
                Icons.text_fields_rounded,
              ),
            ),
            const SizedBox(height: 12),

            // Target Goal Field
            TextField(
              controller: _formTargetController,
              keyboardType: TextInputType.number,
              decoration: _formInputDecoration(
                'Target Count (Goal)',
                '33',
                Icons.flag_rounded,
              ),
            ),
            const SizedBox(height: 12),

            // Description Field
            TextField(
              controller: _formDescController,
              maxLines: 3,
              decoration: _formInputDecoration(
                'Description / Benefits',
                'Enter virtues or why this Tasbeeh is recited...',
                Icons.info_outline_rounded,
              ),
            ),
            const SizedBox(height: 14),

            // Color Selection Row
            const Text(
              'Theme Color',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2A531D),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: colorOptions.map((cVal) {
                final isSelected = cVal == _formSelectedColorValue;
                return GestureDetector(
                  onTap: () => setState(() => _formSelectedColorValue = cVal),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Color(cVal),
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: Colors.white, width: 2.5)
                          : null,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Color(cVal).withValues(alpha: 0.5),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, size: 18, color: Colors.white)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Save Button
            ElevatedButton(
              onPressed: _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2A531D),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
              ),
              child: const Text(
                'Add Custom Tasbeeh',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
