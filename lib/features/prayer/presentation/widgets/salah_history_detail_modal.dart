import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_islamic_icons/flutter_islamic_icons.dart';
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
        color: context.isDarkMode
            ? const Color(0xFF18181B)
            : context.colorScheme.surface,
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
                color: context.isDarkMode
                    ? const Color(0xFF3F3F46)
                    : context.colorScheme.outlineVariant,
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
                        color: context.isDarkMode ? Colors.white : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hijriStr,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: context.isDarkMode
                            ? Colors.white60
                            : context.colorScheme.onSurfaceVariant,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          Divider(
            height: 1,
            color: context.isDarkMode
                ? const Color(0xFF27272A)
                : const Color(0xFFE7E7E7),
          ),
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
                backgroundColor: context.isDarkMode
                    ? const Color(0xFF18A74C)
                    : null,
                foregroundColor: context.isDarkMode
                    ? const Color(0xFF0F0F12)
                    : null,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Close',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
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
            ? const Color(0xFF0F0F12)
            : const Color(0xFFF9F9F9)),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.isDarkMode
              ? const Color(0xFF27272A)
              : const Color(0xFFE5E7EB),
        ),
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
                  color: context.isDarkMode ? Colors.white : null,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '(${group.subtitle})',
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.isDarkMode
                      ? Colors.white60
                      : context.colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Text(
                '$completedCount / ${group.items.length}',
                style: context.textTheme.labelSmall?.copyWith(
                  color: completedCount == group.items.length
                      ? (context.isDarkMode
                            ? const Color(0xFF18A74C)
                            : const Color(0xFF069B69))
                      : (context.isDarkMode
                            ? Colors.white60
                            : context.colorScheme.onSurfaceVariant),
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
                        ? (context.isDarkMode
                              ? const Color(0xFF18A74C)
                              : const Color(0xFF069B69))
                        : (context.isDarkMode
                              ? const Color(0xFF3F3F46)
                              : context.colorScheme.outlineVariant),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    item.name,
                    style: context.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: context.isDarkMode
                          ? Colors.white
                          : context.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: context.isDarkMode
                          ? const Color(0xFF27272A)
                          : context.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${item.rakats} R',
                      style: context.textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        color: context.isDarkMode
                            ? Colors.white70
                            : context.colorScheme.onSurfaceVariant,
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
                          ? (context.isDarkMode
                                ? const Color(0xFF18A74C)
                                : const Color(0xFF069B69))
                          : (context.isDarkMode
                                ? Colors.white38
                                : context.colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.6)),
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
      final completedSubIds = [
        ...storage.getSubPrayerRecords(dateKey, prayerKey),
        if (prayerKey == 'Ishraq')
          ...storage.getSubPrayerRecords(dateKey, 'Shuruq'),
      ];
      return defs.map((def) {
        return _PrayerGroupItem(
          name: def.name,
          rakats: def.rakats,
          isCompleted: completedSubIds.contains(def.id),
        );
      }).toList();
    }

    final isFriday = date.weekday == DateTime.friday;

    return [
      _PrayerGroup(
        title: 'Tahajjud',
        subtitle: 'Late Night',
        icon: CupertinoIcons.moon_stars_fill,
        iconColor: const Color(0xFF6B21A8),
        items: getSubItems('Tahajjud', const [
          _SubPrayerDef('tahajjud_nafeel', 'Nafeel', 4),
        ]),
      ),
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
        title: 'Ishraq',
        subtitle: 'Post-Sunrise',
        icon: CupertinoIcons.sun_min_fill,
        iconColor: const Color(0xFFF59E0B),
        items: getSubItems('Ishraq', const [
          _SubPrayerDef('shuruq_ishraq', 'Ishraq Nafeel', 2),
          _SubPrayerDef('shuruq_chast', 'Chast Nafeel', 2),
        ]),
      ),
      _PrayerGroup(
        title: isFriday ? 'Jumma' : 'Dhuhr',
        subtitle: isFriday ? 'Friday Prayer' : 'Noon',
        icon: isFriday
            ? FlutterIslamicIcons.solidKaaba
            : CupertinoIcons.sun_max_fill,
        iconColor: isFriday ? const Color(0xFF047857) : const Color(0xFFD97706),
        items: isFriday
            ? getSubItems('Dhuhr', const [
                _SubPrayerDef('jumma_sunnat_1', 'Sunnat (Before Farz)', 4),
                _SubPrayerDef('jumma_farz', 'Jummah Farz', 2),
                _SubPrayerDef('jumma_sunnat_2', 'Sunnat (After Farz)', 2),
                _SubPrayerDef('jumma_sunnat_3', 'Sunnat (Additional)', 4),
                _SubPrayerDef('jumma_nafeel', 'Nafeel', 2),
              ])
            : getSubItems('Dhuhr', const [
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
