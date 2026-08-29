import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_typography.dart';
import '../../../widgets/app_header_bar.dart';
import '../../../shared/widgets/app_floating_toast.dart';
import '../domain/dua_item.dart';
import 'widgets/add_dua_modal.dart';

class DuaDetailScreen extends StatefulWidget {
  final DuaItem dua;
  final VoidCallback? onDelete;
  final Function(DuaItem updatedDua)? onSave;

  const DuaDetailScreen({
    super.key,
    required this.dua,
    this.onDelete,
    this.onSave,
  });

  @override
  State<DuaDetailScreen> createState() => _DuaDetailScreenState();
}

class _DuaDetailScreenState extends State<DuaDetailScreen> {
  late DuaItem _dua;

  @override
  void initState() {
    super.initState();
    _dua = widget.dua;
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
      case 'daily':
        return const Color(0xFF1B5E20);
      case 'sleep':
        return const Color(0xFF1E3A8A);
      case 'hygiene':
        return const Color(0xFFDB2777);
      case 'food':
        return const Color(0xFFB45309);
      case 'travel':
        return const Color(0xFF047857);
      case 'protection':
        return const Color(0xFF7E22CE); 
      default:
        return const Color(0xFFBE123C);
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
          title: _dua.title,
          showBackButton: true,
          backgroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(
                Icons.edit_outlined,
                color: Color(0xFF2A531D),
              ),
              tooltip: 'Edit Dua',
              onPressed: _openEditModal,
            ),
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
            // Fixed Decorative Image at Bottom-Right Corner of Screen Viewport
            Positioned(
              bottom: 40,
              right: 12,
              child: IgnorePointer(
                child: Opacity(  
                  opacity: 0.3,
                  child: Image.asset(
                    _dua.imagePath,
                    width: 160,
                    height: 160,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),

            // Main Single Scrollable Screen Content
            Positioned.fill(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Tags Row: Category Chip + Optional Recitation Count Badge (Only if > 1)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                        if (_dua.repeatCount > 1)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD97724),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Recite ${_dua.repeatCount} Times',
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.1,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Main Title
                    Text(
                      _dua.title,
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
                    SelectableText(
                      _dua.transliteration,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.45,
                        letterSpacing: 0,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 12),

                    SelectableText(
                      '"${_dua.translation}"',
                      style: GoogleFonts.lexend(
                        fontSize: 15,
                        height: 1.45,
                        letterSpacing: -0.6,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF1B5E20),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Origin & Reference Section
                    const Text(
                      'REFERENCE',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: Color(0xFFD97724),
                      ),
                    ),
                    const SizedBox(height: 6),
                    SelectableText(
                      _dua.reference,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.45,
                        letterSpacing: -0.1,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF4A3728),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Spiritual & Practical Benefits Section
                    const Text(
                      'SPIRITUAL & PRACTICAL BENEFITS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: Color(0xFF9333EA),
                      ),
                    ),
                    const SizedBox(height: 6),
                    SelectableText(
                      _dua.benefits,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.45,
                        letterSpacing: -0.1,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF3B0764),
                      ),
                    ),
                    const SizedBox(height: 36),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
