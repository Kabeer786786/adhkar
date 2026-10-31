import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/providers/app_providers.dart';
import '../../domain/dua_item.dart';
import '../../../../shared/widgets/app_floating_toast.dart';
import 'add_dua_modal.dart';

enum DuaModalView { library, details, form }

class DuaLibraryModal extends ConsumerStatefulWidget {
  final List<DuaItem> currentDuas;
  final List<DuaItem> defaultDuas;
  final Function(DuaItem dua) onAddDua;
  final Function(String duaId) onRemoveDua;
  final Function(DuaItem customDua) onCreateCustom;

  const DuaLibraryModal({
    super.key,
    required this.currentDuas,
    required this.defaultDuas,
    required this.onAddDua,
    required this.onRemoveDua,
    required this.onCreateCustom,
  });

  static Future<void> show(
    BuildContext context, {
    required List<DuaItem> currentDuas,
    required List<DuaItem> defaultDuas,
    required Function(DuaItem dua) onAddDua,
    required Function(String duaId) onRemoveDua,
    required Function(DuaItem customDua) onCreateCustom,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF18181B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.88,
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF18181B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: DuaLibraryModal(
          currentDuas: currentDuas,
          defaultDuas: defaultDuas,
          onAddDua: onAddDua,
          onRemoveDua: onRemoveDua,
          onCreateCustom: onCreateCustom,
        ),
      ),
    );
  }

  @override
  ConsumerState<DuaLibraryModal> createState() => _DuaLibraryModalState();
}

class _DuaLibraryModalState extends ConsumerState<DuaLibraryModal> {
  final TextEditingController _searchController = TextEditingController();
  late List<DuaItem> _activeDuas;

  // View switcher state
  DuaModalView _currentView = DuaModalView.library;
  DuaItem? _selectedDuaForDetails;

  String _detailLang = 'en';

  static ({List<Color> colors, Color textColor}) _getCategoryPreset(
    String category, [
    bool isDark = false,
  ]) {
    switch (category.trim().toLowerCase()) {
      case 'food':
      case 'morning':
        return (
          colors: isDark
              ? const [Color(0xFF261E0E), Color(0xFF382C15)]
              : const [Color(0xFFFFFDF2), Color(0xFFFFF8DE)],
          textColor: isDark ? const Color(0xFFFDE68A) : const Color(0xFFB45309),
        );
      case 'sleep':
        return (
          colors: isDark
              ? const [Color(0xFF0F1E2E), Color(0xFF172D45)]
              : const [Color(0xFFF3F6FF), Color(0xFFE8EEFF)],
          textColor: isDark ? const Color(0xFFBAE6FD) : const Color(0xFF1E3A8A),
        );
      case 'daily':
        return (
          colors: isDark
              ? const [Color(0xFF142E18), Color(0xFF1B3D20)]
              : const [Color(0xFFF4FAF3), Color(0xFFEAF5E8)],
          textColor: isDark ? const Color(0xFF86EFAC) : const Color(0xFF1B5E20),
        );
      case 'hygiene':
        return (
          colors: isDark
              ? const [Color(0xFF2C1320), Color(0xFF3D1B2D)]
              : const [Color(0xFFFFF0F5), Color(0xFFFFE4EC)],
          textColor: isDark ? const Color(0xFFFBCFE8) : const Color(0xFFDB2777),
        );
      case 'travel':
        return (
          colors: isDark
              ? const [Color(0xFF0E2820), Color(0xFF153B2F)]
              : const [Color(0xFFF3FBF7), Color(0xFFE2F6EC)],
          textColor: isDark ? const Color(0xFF86EFAC) : const Color(0xFF047857),
        );
      case 'protection':
        return (
          colors: isDark
              ? const [Color(0xFF241433), Color(0xFF351E4B)]
              : const [Color(0xFFFAF5FF), Color(0xFFF3E8FF)],
          textColor: isDark ? const Color(0xFFE9D5FF) : const Color(0xFF7E22CE),
        );
      case 'prayer':
      case 'adhan':
      case 'mosque':
        return (
          colors: isDark
              ? const [Color(0xFF142E18), Color(0xFF1B3D20)]
              : const [Color(0xFFF0FDF4), Color(0xFFDCFCE7)],
          textColor: isDark ? const Color(0xFF86EFAC) : const Color(0xFF1B5E20),
        );
      case 'forgiveness':
        return (
          colors: isDark
              ? const [Color(0xFF0C2424), Color(0xFF133636)]
              : const [Color(0xFFF0FDFA), Color(0xFFCCFBF1)],
          textColor: isDark ? const Color(0xFF99F6E4) : const Color(0xFF0F766E),
        );
      default:
        return (
          colors: isDark
              ? const [Color(0xFF2B1417), Color(0xFF3D1C20)]
              : const [Color(0xFFFFF5F5), Color(0xFFFFECEC)],
          textColor: isDark ? const Color(0xFFFECDD3) : const Color(0xFFBE123C),
        );
    }
  }

  @override
  void initState() {
    super.initState();
    _activeDuas = List.from(widget.currentDuas);
    try {
      final storage = ref.read(storageServiceProvider);
      final savedLangs = storage.getGenericData('dua_selected_languages');
      if (savedLangs is List && savedLangs.isNotEmpty) {
        _detailLang = savedLangs.first.toString();
      } else {
        final savedPrimary = storage.getGenericData('dua_primary_language');
        if (savedPrimary is String && savedPrimary.isNotEmpty) {
          _detailLang = savedPrimary;
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _isDuaSelected(String duaId) {
    return _activeDuas.any((d) => d.id == duaId);
  }

  void _toggleDua(DuaItem dua) {
    final isSelected = _isDuaSelected(dua.id);
    if (isSelected) {
      widget.onRemoveDua(dua.id);
      setState(() {
        _activeDuas.removeWhere((d) => d.id == dua.id);
      });
      AppFloatingToast.showRemoved(context, message: 'Removed');
    } else {
      widget.onAddDua(dua);
      setState(() {
        _activeDuas.add(dua);
      });
      AppFloatingToast.showAdded(context, message: 'Added');
    }
  }

  void _openFormView() {
    setState(() {
      _currentView = DuaModalView.form;
    });
  }

  void _openDetailsView(DuaItem dua) {
    setState(() {
      _selectedDuaForDetails = dua;
      _currentView = DuaModalView.details;
    });
  }

  Widget _buildDetailLangChip(String langCode, String label, bool isDark) {
    final isSelected = _detailLang == langCode;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        setState(() {
          _detailLang = langCode;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF18A74C) : const Color(0xFF2A531D))
              : (isDark ? const Color(0xFF18181B) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? (isDark ? const Color(0xFF18A74C) : const Color(0xFF2A531D))
                : (isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0)),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color:
                        (isDark
                                ? const Color(0xFF18A74C)
                                : const Color(0xFF2A531D))
                            .withValues(alpha: isDark ? 0.3 : 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.2,
            color: isSelected
                ? (isDark ? const Color(0xFF0F0F12) : Colors.white)
                : (isDark ? Colors.white70 : const Color(0xFF475569)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    return Column(
      children: [
        const SizedBox(height: 12),
        // Drag Handle
        Center(
          child: Container(
            width: 60,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF3F3F46) : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Content View Switcher
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            layoutBuilder:
                (Widget? currentChild, List<Widget> previousChildren) {
                  return Stack(
                    fit: StackFit.expand,
                    alignment: Alignment.topCenter,
                    children: <Widget>[...previousChildren, ?currentChild],
                  );
                },
            child: _buildCurrentViewContent(),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentViewContent() {
    switch (_currentView) {
      case DuaModalView.library:
        return _buildLibraryView();
      case DuaModalView.details:
        return _buildDetailsView();
      case DuaModalView.form:
        return AddDuaModal(
          isEmbedded: true,
          onBack: () {
            setState(() {
              _currentView = DuaModalView.library;
            });
          },
          onSave: (newDua) {
            widget.onCreateCustom(newDua);
            setState(() {
              if (!_activeDuas.any((d) => d.id == newDua.id)) {
                _activeDuas.add(newDua);
              }
              _currentView = DuaModalView.library;
            });
            AppFloatingToast.showAdded(
              context,
              message: 'Custom Dua created successfully',
            );
          },
        );
    }
  }

  // --- 1. LIBRARY VIEW ---
  Widget _buildLibraryView() {
    final isDark = context.isDarkMode;
    final query = _searchController.text.trim().toLowerCase();
    final filteredLibrary = widget.defaultDuas.where((dua) {
      return query.isEmpty ||
          dua.title.toLowerCase().contains(query) ||
          dua.arabic.contains(query) ||
          dua.translation.toLowerCase().contains(query) ||
          dua.category.toLowerCase().contains(query);
    }).toList();

    return Padding(
      key: const ValueKey('library_view'),
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Dua Library',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF2A531D),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _openFormView,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Create Dua'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark
                      ? const Color(0xFF18A74C)
                      : const Color(0xFF2A531D),
                  foregroundColor: isDark
                      ? const Color(0xFF0F0F12)
                      : Colors.white,
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
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
            decoration: InputDecoration(
              hintText: 'Search Dua library...',
              hintStyle: TextStyle(
                color: isDark ? Colors.white38 : Colors.grey.shade500,
                fontSize: 14,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: isDark
                    ? const Color(0xFF18A74C)
                    : const Color(0xFF2A531D),
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      color: isDark ? Colors.white60 : Colors.grey.shade600,
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    )
                  : null,
              filled: true,
              fillColor: isDark
                  ? const Color(0xFF0F0F12)
                  : const Color(0xFFF9F9F9),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: isDark
                      ? const Color(0xFF27272A)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: isDark
                      ? const Color(0xFF27272A)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: isDark
                      ? const Color(0xFF18A74C)
                      : const Color(0xFF2A531D),
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Platform Duas List (or Not Found state)
          Expanded(
            child: filteredLibrary.isEmpty
                ? _buildEmptySearchState(query, isDark)
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: filteredLibrary.length,
                    itemBuilder: (context, index) {
                      final dua = filteredLibrary[index];
                      final isSelected = _isDuaSelected(dua.id);
                      final gradientPreset = _getCategoryPreset(
                        dua.category,
                        isDark,
                      );

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => _openDetailsView(dua),
                            child: Container(
                              clipBehavior: Clip.antiAlias,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: LinearGradient(
                                  colors: gradientPreset.colors,
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF27272A)
                                      : gradientPreset.textColor.withValues(
                                          alpha: 0.15,
                                        ),
                                  width: 1.0,
                                ),
                              ),
                              child: Stack(
                                children: [
                                  // Radio button positioned at the right center
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Center(
                                      child: GestureDetector(
                                        onTap: () => _toggleDua(dua),
                                        behavior: HitTestBehavior.opaque,
                                        child: AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 200,
                                          ),
                                          padding: const EdgeInsets.all(4),
                                          child: Icon(
                                            isSelected
                                                ? Icons
                                                      .radio_button_checked_rounded
                                                : Icons
                                                      .radio_button_unchecked_rounded,
                                            size: 24,
                                            color: isSelected
                                                ? gradientPreset.textColor
                                                : gradientPreset.textColor
                                                      .withValues(alpha: 0.45),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Minimized Background Illustration Image
                                  Positioned(
                                    bottom: 4,
                                    right: 4,
                                    child: IgnorePointer(
                                      child: Container(
                                        width: 60,
                                        height: 60,
                                        padding: const EdgeInsets.all(2),
                                        child: Opacity(
                                          opacity: 0.85,
                                          child: Image.asset(
                                            dua.imagePath,
                                            fit: BoxFit.contain,
                                            cacheWidth: 200,
                                            cacheHeight: 200,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    const SizedBox.shrink(),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Card Content with right padding leaving space for the center-right radio button
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      14,
                                      14,
                                      68,
                                      14,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        // Top Row: Title on the left (max 1 line, stops before category badge), Category at the top right corner
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                dua.title,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 14.5,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: -0.2,
                                                  color:
                                                      gradientPreset.textColor,
                                                  height: 1.2,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 7,
                                                    vertical: 2.5,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: gradientPreset.textColor
                                                    .withValues(alpha: 0.12),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                dua.category.toUpperCase(),
                                                style: TextStyle(
                                                  fontSize: 9.5,
                                                  fontWeight: FontWeight.w800,
                                                  letterSpacing: 0.4,
                                                  color:
                                                      gradientPreset.textColor,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),

                                        Text(
                                          dua.arabic,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.right,
                                          textDirection: TextDirection.rtl,
                                          style: AppTypography.arabicHeader(
                                            fontSize: 16.5,
                                            color: isDark
                                                ? Colors.white
                                                : const Color(0xFF1B3512),
                                            height: 1.6,
                                          ),
                                        ),
                                        const SizedBox(height: 5),

                                        Text(
                                          dua.translation,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.lexend(
                                            fontSize: 13,
                                            letterSpacing: -0.1,
                                            color: isDark
                                                ? Colors.white70
                                                : Colors.black87,
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
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

  Widget _buildEmptySearchState(String query, bool isDark) {
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color:
                    (isDark ? const Color(0xFF18A74C) : const Color(0xFF2A531D))
                        .withValues(alpha: isDark ? 0.15 : 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 40,
                color: isDark
                    ? const Color(0xFF18A74C)
                    : const Color(0xFF2A531D),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No Duas Found',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF2A531D),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              query.isNotEmpty
                  ? 'We couldn\'t find any Dua matching "$query".\nTry checking the spelling or create your own custom Dua.'
                  : 'No supplications available in the library.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: isDark ? Colors.white70 : const Color(0xFF64748B),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _openFormView,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Create Custom Dua'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark
                    ? const Color(0xFF18A74C)
                    : const Color(0xFF2A531D),
                foregroundColor: isDark
                    ? const Color(0xFF0F0F12)
                    : Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 11,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 2. DETAILS VIEW ---
  Widget _buildDetailsView() {
    final dua = _selectedDuaForDetails!;
    final isSelected = _isDuaSelected(dua.id);
    final isDark = context.isDarkMode;

    return Column(
      key: const ValueKey('details_view'),
      children: [
        // Fixed Header with Back Button and Dynamic Title (Max 2 lines)
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 12, 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(
                  Icons.arrow_back_rounded,
                  color: isDark
                      ? const Color(0xFF18A74C)
                      : const Color(0xFF2A531D),
                  size: 22,
                ),
                onPressed: () {
                  setState(() {
                    _currentView = DuaModalView.library;
                  });
                },
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  dua.getTitle(_detailLang),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF2A531D),
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF18A74C).withValues(alpha: 0.15)
                      : const Color(0xFF2A531D).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  dua.category.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? const Color(0xFF86EFAC)
                        : const Color(0xFF2A531D),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Language Switcher Chips Row (Enables preview & adds proper spacing below 2-line title)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Translation Preview',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white60 : Colors.grey.shade600,
                  letterSpacing: 0.3,
                ),
              ),
              Row(
                children: [
                  _buildDetailLangChip('en', 'EN', isDark),
                  const SizedBox(width: 5),
                  _buildDetailLangChip('ur', 'UR', isDark),
                  const SizedBox(width: 5),
                  _buildDetailLangChip('hi', 'HI', isDark),
                  const SizedBox(width: 5),
                  _buildDetailLangChip('te', 'TE', isDark),
                ],
              ),
            ],
          ),
        ),

        Divider(
          height: 1,
          color: isDark ? const Color(0xFF27272A) : Colors.grey.shade300,
        ),

        // Scrollable Content
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Arabic Text
                Text(
                  dua.arabic,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  style: AppTypography.arabicBody(
                    fontSize: 24,
                    height: 1.8,
                    color: isDark ? Colors.white : const Color(0xFF1B5E20),
                  ),
                ),
                const SizedBox(height: 14),

                // Transliteration
                if (dua.getTransliteration(_detailLang).isNotEmpty) ...[
                  Text(
                    dua.getTransliteration(_detailLang),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lexend(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: isDark
                          ? const Color(0xFF86EFAC)
                          : Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Translation
                Text(
                  dua.getTranslation(_detailLang),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lexend(
                    fontSize: 13.5,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white70 : const Color(0xFF1B5E20),
                  ),
                ),
                const SizedBox(height: 16),

                // Reference & Benefits Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0F0F12)
                        : const Color(0xFFF4FAF3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF27272A)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (dua.reference.isNotEmpty) ...[
                        Text(
                          'Reference',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? const Color(0xFFFDE68A)
                                : const Color(0xFFD97724),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          dua.reference,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? const Color(0xFFFEF3C7)
                                : Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                      if (dua.getBenefits(_detailLang).isNotEmpty) ...[
                        Text(
                          'Virtues & Benefits',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? const Color(0xFFE9D5FF)
                                : const Color(0xFF7E22CE),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          dua.getBenefits(_detailLang),
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? const Color(0xFFF3E8FF)
                                : Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),

        // Fixed Footer Button
        Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF18181B) : Colors.white,
            border: Border(
              top: BorderSide(
                color: isDark
                    ? const Color(0xFF27272A)
                    : const Color(0xFFE2E8F0),
                width: 1.0,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  _toggleDua(dua);
                  setState(() {
                    _currentView = DuaModalView.library;
                  });
                },
                icon: Icon(
                  isSelected
                      ? Icons.check_circle_rounded
                      : Icons.add_circle_rounded,
                  size: 20,
                ),
                label: Text(
                  isSelected ? 'Remove from My Duas' : 'Add to My Duas',
                  style: GoogleFonts.lexend(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSelected
                      ? Colors.red.shade700
                      : (isDark
                            ? const Color(0xFF18A74C)
                            : const Color(0xFF2A531D)),
                  foregroundColor: isSelected
                      ? Colors.white
                      : (isDark ? const Color(0xFF0F0F12) : Colors.white),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
