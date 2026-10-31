import 'package:flutter/material.dart';
import '../../../../core/extensions/context_extensions.dart';

class MarbleStyleModal extends StatefulWidget {
  final String currentAsset;
  final Function(String selectedAsset, bool applyToAll) onSelect;

  const MarbleStyleModal({
    super.key,
    required this.currentAsset,
    required this.onSelect,
  });

  static void show(
    BuildContext context, {
    required String currentAsset,
    required Function(String selectedAsset, bool applyToAll) onSelect,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          MarbleStyleModal(currentAsset: currentAsset, onSelect: onSelect),
    );
  }

  @override
  State<MarbleStyleModal> createState() => _MarbleStyleModalState();
}

class _MarbleStyleModalState extends State<MarbleStyleModal> {
  late String _selected;

  static const List<Map<String, String>> marbles = [
    {'asset': 'assets/images/marble1.png', 'name': 'Marble 1'},
    {'asset': 'assets/images/marble2.png', 'name': 'Marble 2'},
    {'asset': 'assets/images/marble3.png', 'name': 'Marble 3'},
    {'asset': 'assets/images/marble4.png', 'name': 'Marble 4'},
    {'asset': 'assets/images/marble5.png', 'name': 'Marble 5'},
  ];

  @override
  void initState() {
    super.initState();
    _selected = widget.currentAsset;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final primaryColor = isDark
        ? const Color(0xFF18A74C)
        : const Color(0xFF2A531D);

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF18181B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Drag Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF3F3F46)
                      : Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF143820)
                        : const Color(0xFF2A531D).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.palette_outlined,
                    color: primaryColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Select Marble Bead Style',
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF2A531D),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Wrapped Marble Grid to Overcome Overflowing
            Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 16,
                children: marbles.map((m) {
                  final asset = m['asset']!;
                  final name = m['name']!;
                  final isSelected = _selected == asset;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selected = asset;
                      });
                    },
                    child: SizedBox(
                      width: 62,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? primaryColor
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Image.asset(
                              asset,
                              fit: BoxFit.contain,
                              cacheWidth: 160,
                              cacheHeight: 160,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: primaryColor,
                                    ),
                                  ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            name,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: isSelected
                                  ? primaryColor
                                  : (isDark
                                        ? Colors.white70
                                        : context.colorScheme.onSurfaceVariant),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons (Apply to This vs Apply to All)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      widget.onSelect(_selected, false);
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryColor,
                      side: BorderSide(color: primaryColor),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Apply to This Only',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onSelect(_selected, true);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: isDark
                          ? const Color(0xFF0F0F12)
                          : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Apply to All',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
