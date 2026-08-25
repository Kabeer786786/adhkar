import 'package:flutter/material.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../domain/prayer_models.dart';

class PrayerDetailModal extends StatefulWidget {
  final String prayerTitle;
  final String prayerSubtitle;
  final String dateKey;
  final List<SubPrayerItem> subPrayers;
  final ValueChanged<List<String>> onSave;
  final bool isFuture;

  const PrayerDetailModal({
    super.key,
    required this.prayerTitle,
    required this.prayerSubtitle,
    required this.dateKey,
    required this.subPrayers,
    required this.onSave,
    this.isFuture = false,
  });

  static Future<void> show({
    required BuildContext context,
    required String prayerTitle,
    required String prayerSubtitle,
    required String dateKey,
    required List<SubPrayerItem> subPrayers,
    required ValueChanged<List<String>> onSave,
    bool isFuture = false,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PrayerDetailModal(
        prayerTitle: prayerTitle,
        prayerSubtitle: prayerSubtitle,
        dateKey: dateKey,
        subPrayers: subPrayers,
        onSave: onSave,
        isFuture: isFuture,
      ),
    );
  }

  @override
  State<PrayerDetailModal> createState() => _PrayerDetailModalState();
}

class _PrayerDetailModalState extends State<PrayerDetailModal> {
  late Map<String, bool> _completedMap;

  @override
  void initState() {
    super.initState();
    _completedMap = {
      for (final item in widget.subPrayers) item.id: item.isCompleted,
    };
  }

  int get _completedCount => _completedMap.values.where((v) => v).length;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: context.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${widget.prayerTitle} Prayer Checklist',
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Mark completed Sunnat, Farz & Nafl rak\'ats',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colorScheme.onSurfaceVariant, 
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: context.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_completedCount / ${widget.subPrayers.length}',
                  style: context.textTheme.labelMedium?.copyWith(
                    color: context.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(height: 1,color: Color(0xFFE7E7E7),),
          const SizedBox(height: 12),

          if (widget.isFuture)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lock_clock_outlined, size: 18, color: Colors.amber),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This prayer is scheduled for the future and cannot be marked completed yet.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.amber,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Sub-Prayers Checklist
          ...widget.subPrayers.map((item) {
            final isChecked = _completedMap[item.id] ?? false;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: isChecked
                    ? context.colorScheme.primaryContainer.withValues(alpha: 0.25)
                    : context.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isChecked
                      ? context.colorScheme.primary.withValues(alpha: 0.5)
                      : const Color(0xFFE7E7E7),
                ),
              ),
              child: CheckboxListTile(
                value: isChecked,
                onChanged: widget.isFuture
                    ? null
                    : (val) {
                        setState(() {
                          _completedMap[item.id] = val ?? false;
                        });
                      },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                activeColor: context.colorScheme.primary,
                title: Row(
                  children: [
                    Text(
                      item.title,
                      style: context.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: context.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${item.rakats} Rak\'at',
                        style: context.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: context.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 20),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    widget.isFuture ? 'Close' : 'Cancel',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
              if (!widget.isFuture) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      final completedIds = _completedMap.entries
                          .where((e) => e.value)
                          .map((e) => e.key)
                          .toList();
                      widget.onSave(completedIds);
                      Navigator.of(context).pop();
                    },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Save', style: TextStyle(fontSize: 14)),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
