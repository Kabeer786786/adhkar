import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/utils/hijri_date_helper.dart';

class SalahHistoryDetailModal extends StatelessWidget {
  final DateTime date;
  final String? hijriDate;
  final StorageService storage;

  const SalahHistoryDetailModal({
    super.key,
    required this.date,
    this.hijriDate,
    required this.storage,
  });

  static Future<void> show({
    required BuildContext context,
    required DateTime date,
    String? hijriDate,
    required StorageService storage,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SalahHistoryDetailModal(
        date: date,
        hijriDate: hijriDate,
        storage: storage,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateKey =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final gregorianStr = _formatFullDate(date);
    final hijriStr = hijriDate ?? HijriDateHelper.formatHijri(date);

    final prayersData = _getPrayerDetails(dateKey);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
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

          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      gregorianStr,
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hijriStr,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: context.colorScheme.onSurfaceVariant,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Container(
              //   padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              //   decoration: BoxDecoration(
              //     color: context.colorScheme.primaryContainer,
              //     borderRadius: BorderRadius.circular(10),
              //   ),
              //   child: Text(
              //     'View Only',
              //     style: context.textTheme.labelSmall?.copyWith(
              //       color: context.colorScheme.onPrimaryContainer,
              //       fontWeight: FontWeight.w600,
              //     ),
              //   ),
              // ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFE7E7E7)),
          const SizedBox(height: 12),

          // Sequential Prayer Breakdown List
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: prayersData.length,
              itemBuilder: (context, index) {
                final group = prayersData[index];
                return _buildPrayerGroupCard(context, group);
              },
            ),
          ),

          const SizedBox(height: 16),

          // Close Button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Close', style: TextStyle(fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerGroupCard(BuildContext context, _PrayerGroup group) {
    final completedCount = group.items.where((item) => item.isCompleted).length;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: (context.isDarkMode
            ? const Color(0xFF1A2818)
            : const Color(0xFFF9F9F9)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Prayer Group Title
          Row(
            children: [
              Icon(group.icon, size: 22, color: group.iconColor),
              const SizedBox(width: 10),
              Text(
                group.title,
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '(${group.subtitle})',
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Text(
                '$completedCount / ${group.items.length}',
                style: context.textTheme.labelSmall?.copyWith(
                  color: completedCount == group.items.length
                      ? const Color(0xFF069B69)
                      : context.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Sub-Prayer Items List
          ...group.items.map((item) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(
                    item.isCompleted
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 18,
                    color: item.isCompleted
                        ? const Color(0xFF069B69)
                        : context.colorScheme.outlineVariant,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    item.name,
                    style: context.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: context.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: context.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${item.rakats} R',
                      style: context.textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    item.isCompleted ? 'Completed' : 'Pending',
                    style: context.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                      color: item.isCompleted
                          ? const Color(0xFF069B69)
                          : context.colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.6,
                            ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  List<_PrayerGroup> _getPrayerDetails(String dateKey) {
    List<_PrayerGroupItem> getSubItems(
      String prayerKey,
      List<_SubPrayerDef> defs,
    ) {
      final completedSubIds = storage.getSubPrayerRecords(dateKey, prayerKey);
      return defs.map((def) {
        return _PrayerGroupItem(
          name: def.name,
          rakats: def.rakats,
          isCompleted: completedSubIds.contains(def.id),
        );
      }).toList();
    }

    return [
      _PrayerGroup(
        title: 'Fajr',
        subtitle: 'Before Sunrise',
        icon: CupertinoIcons.cloud_sun_fill,
        iconColor: const Color(0xFF0284C7),
        items: getSubItems('Fajr', const [
          _SubPrayerDef('fajr_sunnat', 'Sunnat', 2),
          _SubPrayerDef('fajr_farz', 'Farz', 2),
        ]),
      ),
      _PrayerGroup(
        title: 'Shuruq',
        subtitle: 'Sunrise',
        icon: CupertinoIcons.sunrise_fill,
        iconColor: const Color(0xFFF59E0B),
        items: getSubItems('Shuruq', const [
          _SubPrayerDef('shuruq_ishraq', 'Ishraq Nafeel', 2),
          _SubPrayerDef('shuruq_chast', 'Chast Nafeel', 2),
        ]),
      ),
      _PrayerGroup(
        title: 'Dhuhr',
        subtitle: 'Noon',
        icon: CupertinoIcons.sun_max_fill,
        iconColor: const Color(0xFFD97706),
        items: getSubItems('Dhuhr', const [
          _SubPrayerDef('dhuhr_sunnat_1', 'Sunnat (Before)', 4),
          _SubPrayerDef('dhuhr_farz', 'Farz', 4),
          _SubPrayerDef('dhuhr_sunnat_2', 'Sunnat (After)', 2),
          _SubPrayerDef('dhuhr_nafeel', 'Nafeel', 2),
        ]),
      ),
      _PrayerGroup(
        title: 'Asr',
        subtitle: 'Afternoon',
        icon: CupertinoIcons.cloud_sun_fill,
        iconColor: const Color(0xFFEAB308),
        items: getSubItems('Asr', const [
          _SubPrayerDef('asr_sunnat', 'Sunnat', 4),
          _SubPrayerDef('asr_farz', 'Farz', 4),
        ]),
      ),
      _PrayerGroup(
        title: 'Maghrib',
        subtitle: 'Sunset',
        icon: CupertinoIcons.sunset_fill,
        iconColor: const Color(0xFFF97316),
        items: getSubItems('Maghrib', const [
          _SubPrayerDef('maghrib_farz', 'Farz', 3),
          _SubPrayerDef('maghrib_sunnat', 'Sunnat', 2),
          _SubPrayerDef('maghrib_nafeel', 'Nafeel', 2),
          _SubPrayerDef('maghrib_awabeen', 'Awabeen Nafeel', 6),
        ]),
      ),
      _PrayerGroup(
        title: 'Isha',
        subtitle: 'Night',
        icon: CupertinoIcons.moon_stars_fill,
        iconColor: const Color(0xFF3730A3),
        items: getSubItems('Isha', const [
          _SubPrayerDef('isha_sunnat_1', 'Sunnat (Before)', 4),
          _SubPrayerDef('isha_farz', 'Farz', 4),
          _SubPrayerDef('isha_sunnat_2', 'Sunnat (After)', 2),
          _SubPrayerDef('isha_nafeel', 'Nafeel', 2),
          _SubPrayerDef('isha_wajib', 'Wajib (Witr)', 3),
        ]),
      ),
      _PrayerGroup(
        title: 'Tahajjud',
        subtitle: 'Late Night',
        icon: CupertinoIcons.moon_stars_fill,
        iconColor: const Color(0xFF6B21A8),
        items: getSubItems('Tahajjud', const [
          _SubPrayerDef('tahajjud_nafeel', 'Nafeel', 4),
        ]),
      ),
    ];
  }

  String _formatFullDate(DateTime d) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${days[d.weekday - 1]}, ${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

class _PrayerGroup {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final List<_PrayerGroupItem> items;

  const _PrayerGroup({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.items,
  });
}

class _PrayerGroupItem {
  final String name;
  final int rakats;
  final bool isCompleted;

  const _PrayerGroupItem({
    required this.name,
    required this.rakats,
    required this.isCompleted,
  });
}

class _SubPrayerDef {
  final String id;
  final String name;
  final int rakats;

  const _SubPrayerDef(this.id, this.name, this.rakats);
}
