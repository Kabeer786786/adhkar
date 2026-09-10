import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_floating_toast.dart';
import '../../../widgets/app_header_bar.dart';
import '../domain/dua_item.dart';
import 'widgets/add_dua_modal.dart';

class DuaDetailScreen extends ConsumerStatefulWidget {
  final DuaItem dua;
  final String selectedLanguage;
  final VoidCallback? onDelete;
  final Function(DuaItem updatedDua)? onSave;

  const DuaDetailScreen({
    super.key,
    required this.dua,
    this.selectedLanguage = 'en',
    this.onDelete,
    this.onSave,
  });

  @override
  ConsumerState<DuaDetailScreen> createState() => _DuaDetailScreenState();
}

class _DuaDetailScreenState extends ConsumerState<DuaDetailScreen> {
  late DuaItem _dua;
  late String _currentLang;

  @override
  void initState() {
    super.initState();
    _dua = widget.dua;
    _currentLang = widget.selectedLanguage;
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
            const SizedBox(width: 8),
            Text(_dua.isCustom ? 'Delete Dua?' : 'Remove Dua?'),
          ],
        ),
        content: Text(
          _dua.isCustom
              ? 'Are you sure you want to delete "${_dua.title}" permanently?'
              : 'Are you sure you want to remove "${_dua.title}"? You can re-add it anytime from the Dua Library.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.pop(dialogCtx);
              widget.onDelete?.call();
              Navigator.pop(context);
              AppFloatingToast.showRemoved(context, message: 'Removed');
            },
            child: Text(_dua.isCustom ? 'Delete' : 'Remove'),
          ),
        ],
      ),
    );
  }

  void _openEditModal() {
    AddDuaModal.show(
      context,
      initialDua: _dua,
      onSave: (updatedDua) {
        setState(() {
          _dua = updatedDua;
        });
        widget.onSave?.call(updatedDua);
        AppFloatingToast.showAdded(context, message: 'Updated');
      },
    );
  }

  static Color _getCategoryTextColor(String category) {
    switch (category.trim().toLowerCase()) {
      case 'morning':
      case 'food':
        return const Color(0xFFB45309);
      case 'sleep':
        return const Color(0xFF1E3A8A);
      case 'hygiene':
        return const Color(0xFFDB2777);
      case 'travel':
        return const Color(0xFF047857);
      case 'protection':
        return const Color(0xFF7E22CE);
      case 'prayer':
      case 'adhan':
      case 'mosque':
        return const Color(0xFF1B5E20);
      case 'forgiveness':
        return const Color(0xFF0F766E);
      default:
        return const Color(0xFF1B5E20);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = _getCategoryTextColor(_dua.category);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AppHeaderBar(
          title: _dua.getTitle(_currentLang),
          showBackButton: true,
          centerTitle: false,
          titleSpacing: 12,
          backgroundColor: Colors.white,
          actions: [
            // Edit Dua
            IconButton(
              icon: const Icon(
                Icons.edit_outlined,
                color: Color(0xFF2A531D),
              ),
              tooltip: 'Edit Dua',
              onPressed: _openEditModal,
            ),

            // Delete / Remove Dua
            IconButton(
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: Colors.redAccent,
              ),
              tooltip: _dua.isCustom ? 'Delete Custom Dua' : 'Remove Dua',
              onPressed: () => _confirmDelete(context),
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
      body: SizedBox.expand(
        child: Stack(
          children: [
            // Decorative Image at Bottom-Right Corner
            Positioned(
              bottom: 40,
              right: 12,
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.2,
                  child: Image.asset(
                    _dua.imagePath,
                    width: 160,
                    height: 160,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox.shrink(),
                  ),
                ),
              ),
            ),

            // Main Content
            Positioned.fill(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Tags Row: Category Chip + Optional Repeat Count + Language Pills
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: themeColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _dua.category.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.2,
                                  color: themeColor,
                                ),
                              ),
                            ),
                            if (_dua.repeatCount > 1) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD97724),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Recite ${_dua.repeatCount}x',
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),

                        // Language Switcher Chips
                        Row(
                          children: [
                            _buildLangChip('en', 'EN'),
                            const SizedBox(width: 4),
                            _buildLangChip('ur', 'UR'),
                            const SizedBox(width: 4),
                            _buildLangChip('hi', 'HI'),
                            const SizedBox(width: 4),
                            _buildLangChip('te', 'TE'),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Main Title in Selected Language
                    Text(
                      _dua.getTitle(_currentLang),
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0,
                        color: themeColor,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Large Arabic Text
                    SelectableText(
                      _dua.arabic,
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.rtl,
                      style: AppTypography.arabicHeader(
                        fontSize: 27,
                        height: 1.8,
                        color: const Color(0xFF1A3512),
                      ),
                    ),
                    const SizedBox(height: 12),

                    const Divider(
                      color: Color(0xFFE2E8F0),
                      thickness: 1.0,
                    ),
                    const SizedBox(height: 12),

                    // Transliteration in Selected Language
                    if (_dua.getTransliteration(_currentLang).isNotEmpty) ...[
                      SelectableText(
                        _dua.getTransliteration(_currentLang),
                        style: const TextStyle(
                          fontSize: 15.5,
                          height: 1.45,
                          letterSpacing: 0,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Translation in Selected Language
                    SelectableText(
                      '"${_dua.getTranslation(_currentLang)}"',
                      style: GoogleFonts.lexend(
                        fontSize: 15,
                        height: 1.45,
                        letterSpacing: -0.4,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF1B5E20),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Reference Section
                    if (_dua.reference.isNotEmpty) ...[
                      const Text(
                        'REFERENCE',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          color: Color(0xFFD97724),
                        ),
                      ),
                      const SizedBox(height: 6),
                      SelectableText(
                        _dua.reference,
                        style: const TextStyle(
                          fontSize: 13.5,
                          height: 1.45,
                          letterSpacing: -0.1,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF4A3728),
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],

                    // Spiritual Benefits Section
                    if (_dua.getBenefits(_currentLang).isNotEmpty) ...[
                      const Text(
                        'SPIRITUAL & PRACTICAL BENEFITS',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          color: Color(0xFF9333EA),
                        ),
                      ),
                      const SizedBox(height: 6),
                      SelectableText(
                        _dua.getBenefits(_currentLang),
                        style: const TextStyle(
                          fontSize: 13.5,
                          height: 1.45,
                          letterSpacing: -0.1,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF3B0764),
                        ),
                      ),
                      const SizedBox(height: 36),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLangChip(String langCode, String label) {
    final isSelected = _currentLang == langCode;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        setState(() {
          _currentLang = langCode;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2A531D) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF2A531D) : const Color(0xFFE2E8F0),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF2A531D).withValues(alpha: 0.2),
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
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }
}
