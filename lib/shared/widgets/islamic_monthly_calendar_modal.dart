import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/extensions/context_extensions.dart';
import '../../core/services/hijri_service.dart';
import '../../core/theme/app_typography.dart';
import '../providers/app_providers.dart';

class IslamicMonthlyCalendarModal extends ConsumerStatefulWidget {
  final int initialMonthIndex;
  final int activeHijriYear;

  const IslamicMonthlyCalendarModal({
    super.key,
    this.initialMonthIndex =
        2, // Default to Rabi' al-Awwal (month 3, 0-based index 2)
    this.activeHijriYear = 1448,
  });

  static Future<void> show(
    BuildContext context, {
    int initialMonthIndex = 2,
    int activeHijriYear = 1448,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => IslamicMonthlyCalendarModal(
        initialMonthIndex: initialMonthIndex,
        activeHijriYear: activeHijriYear,
      ),
    );
  }

  @override
  ConsumerState<IslamicMonthlyCalendarModal> createState() =>
      _IslamicMonthlyCalendarModalState();
}

class _IslamicMonthlyCalendarModalState
    extends ConsumerState<IslamicMonthlyCalendarModal> {
  late int _currentMonthIndex;
  late int _activeHijriYear;
  HijriCalendarMonthData? _cachedMonthData;
  bool _isLoadingMonth = false;

  final List<Map<String, String>> _hijriMonths = const [
    {'number': '1', 'nameEn': 'Muharram', 'nameAr': 'المحَرَّم'},
    {'number': '2', 'nameEn': 'Safar', 'nameAr': 'صَفَر'},
    {'number': '3', 'nameEn': 'Rabi\' al-Awwal', 'nameAr': 'رَبِيع الأَوَّل'},
    {'number': '4', 'nameEn': 'Rabi\' al-Thani', 'nameAr': 'رَبِيع الآخِر'},
    {'number': '5', 'nameEn': 'Jumada al-Awwal', 'nameAr': 'جُمَادَى الأُولَى'},
    {'number': '6', 'nameEn': 'Jumada al-Thani', 'nameAr': 'جُمَادَى الآخِرَة'},
    {'number': '7', 'nameEn': 'Rajab', 'nameAr': 'رَجَب'},
    {'number': '8', 'nameEn': 'Sha\'ban', 'nameAr': 'شَعْبَان'},
    {'number': '9', 'nameEn': 'Ramadan', 'nameAr': 'رَمَضَان'},
    {'number': '10', 'nameEn': 'Shawwal', 'nameAr': 'شَوَّال'},
    {'number': '11', 'nameEn': 'Dhul-Qi\'dah', 'nameAr': 'ذُو القَعْدَة'},
    {'number': '12', 'nameEn': 'Dhul-Hijjah', 'nameAr': 'ذُو الحِجَّة'},
  ];

  @override
  void initState() {
    super.initState();
    _currentMonthIndex = widget.initialMonthIndex;
    _activeHijriYear = widget.activeHijriYear;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMonthCalendarData();
    });
  }

  Future<void> _loadMonthCalendarData() async {
    setState(() {
      _isLoadingMonth = true;
    });

    final hijriService = ref.read(hijriServiceProvider);
    final location = ref.read(currentLocationProvider).value;

    final targetMonthNumber = _currentMonthIndex + 1;
    final data = await hijriService.getCalendarMonth(
      _activeHijriYear,
      targetMonthNumber,
      country: location?.country,
      latitude: location?.latitude,
      longitude: location?.longitude,
    );

    if (mounted) {
      setState(() {
        _cachedMonthData = data;
        _isLoadingMonth = false;
      });
    }
  }

  void _changeMonth(int increment) {
    final newIndex = _currentMonthIndex + increment;
    if (newIndex >= 0 && newIndex <= 11) {
      setState(() {
        _currentMonthIndex = newIndex;
      });
      _loadMonthCalendarData();
    }
  }

  int _calculateGridTotalCount(HijriCalendarMonthData monthData) {
    if (monthData.days.isEmpty) return 0;
    final firstDayOfWeek = monthData.days.first.dayOfWeek;
    return firstDayOfWeek + monthData.days.length;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final primaryColor =
        isDark ? const Color(0xFF22C55E) : const Color(0xFF2A531D);
    final cardBg = isDark ? const Color(0xFF18181B) : Colors.white;
    final cardBorder =
        isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0);

    final todayAsync = ref.watch(todayHijriProvider);
    final todayData = todayAsync.value;
    final location = ref.watch(currentLocationProvider).value;
    final isSubcontinent = HijriService.isChandKiTarikhRegion(
      location?.country,
    );
    final currentHijriMonthMeta = _hijriMonths[_currentMonthIndex];

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: EdgeInsets.only(
        top: 18,
        left: 18,
        right: 18,
        bottom: MediaQuery.of(context).viewInsets.bottom + 18,
      ),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Drag handle bar
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF27272A) : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),

          // Month Navigation Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: _currentMonthIndex > 0
                    ? () => _changeMonth(-1)
                    : null,
                icon: Icon(
                  Icons.chevron_left_rounded,
                  color: _currentMonthIndex > 0
                      ? primaryColor
                      : Colors.grey.shade400,
                  size: 28,
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      currentHijriMonthMeta['nameEn']!.toUpperCase(),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF2A531D),
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      currentHijriMonthMeta['nameAr']!,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.center,
                      style: AppTypography.arabicHeader(
                        fontSize: 17,
                        color: isDark
                            ? const Color(0xFFFBBF24)
                            : const Color(0xFFD97724),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$_activeHijriYear AH  •  Month ${_currentMonthIndex + 1} of 12',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white60 : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _currentMonthIndex < 11
                    ? () => _changeMonth(1)
                    : null,
                icon: Icon(
                  Icons.chevron_right_rounded,
                  color: _currentMonthIndex < 11
                      ? primaryColor
                      : Colors.grey.shade400,
                  size: 28,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Days of Week Header (Sun to Sat)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'].map((
              day,
            ) {
              final isFriHeader = (day == 'Fri');
              return Expanded(
                child: Center(
                  child: Container(
                    padding: isFriHeader
                        ? const EdgeInsets.symmetric(horizontal: 8, vertical: 3)
                        : const EdgeInsets.symmetric(vertical: 3),
                    decoration: isFriHeader
                        ? BoxDecoration(
                            color: isDark
                                ? const Color(0xFF22C55E).withValues(alpha: 0.2)
                                : const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF22C55E).withValues(alpha: 0.4)
                                  : const Color(0xFF86EFAC),
                              width: 1,
                            ),
                          )
                        : null,
                    child: Text(
                      day,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: isFriHeader
                            ? (isDark
                                ? const Color(0xFF86EFAC)
                                : const Color(0xFF15803D))
                            : (isDark ? Colors.white60 : Colors.grey.shade600),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Divider(height: 1, color: cardBorder),
          const SizedBox(height: 10),

          // Scrollable Grid Area
          Expanded(
            child: _isLoadingMonth
                ? Center(
                    child: CircularProgressIndicator(color: primaryColor),
                  )
                : (_cachedMonthData != null &&
                        _cachedMonthData!.days.isNotEmpty)
                    ? GridView.builder(
                        physics: const BouncingScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          childAspectRatio: 0.85,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 6,
                        ),
                        itemCount: _calculateGridTotalCount(_cachedMonthData!),
                        itemBuilder: (context, index) {
                          final firstDayOffset =
                              _cachedMonthData!.days.first.dayOfWeek;
                          if (index < firstDayOffset) {
                            return const SizedBox.shrink();
                          }

                          final dayIndex = index - firstDayOffset;
                          if (dayIndex >= _cachedMonthData!.days.length) {
                            return const SizedBox.shrink();
                          }

                          final dayData = _cachedMonthData!.days[dayIndex];
                          final isToday = todayData != null &&
                              todayData.monthNumber ==
                                  (_currentMonthIndex + 1) &&
                              todayData.day == dayData.hijriDay;
                          final isFriday = (index % 7 == 5);

                          Color cellBgColor;
                          Color cellBorderColor;
                          Color hijriTextColor;
                          Color gregorianTextColor;

                          if (isToday) {
                            cellBgColor = isDark
                                ? const Color(0xFF22C55E)
                                : const Color(0xFF2A531D);
                            cellBorderColor = isFriday
                                ? (isDark
                                    ? const Color(0xFFFDE047)
                                    : const Color(0xFFFDE047))
                                : cellBgColor;
                            hijriTextColor = isDark
                                ? const Color(0xFF0F0F12)
                                : Colors.white;
                            gregorianTextColor = isDark
                                ? const Color(0xFF0F0F12)
                                    .withValues(alpha: 0.85)
                                : Colors.white.withValues(alpha: 0.9);
                          } else if (isFriday) {
                            cellBgColor = isDark
                                ? const Color(0xFF143820)
                                    .withValues(alpha: 0.5)
                                : const Color(0xFFECFDF5);
                            cellBorderColor = isDark
                                ? const Color(0xFF22C55E)
                                    .withValues(alpha: 0.4)
                                : const Color(0xFFA7F3D0);
                            hijriTextColor = isDark
                                ? const Color(0xFF86EFAC)
                                : const Color(0xFF047857);
                            gregorianTextColor = isDark
                                ? const Color(0xFF86EFAC)
                                    .withValues(alpha: 0.8)
                                : const Color(0xFF065F46);
                          } else {
                            cellBgColor = isDark
                                ? const Color(0xFF0F0F12)
                                : const Color(0xFFF8FAFC);
                            cellBorderColor = cardBorder;
                            hijriTextColor = isDark
                                ? Colors.white
                                : const Color(0xFF1F2937);
                            gregorianTextColor = isDark
                                ? Colors.white54
                                : Colors.grey.shade600;
                          }

                          return Container(
                            decoration: BoxDecoration(
                              color: cellBgColor,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: cellBorderColor,
                                width: isToday ? 2 : 1,
                              ),
                            ),
                            child: Stack(
                              children: [
                                if (isFriday && !isToday)
                                  Positioned(
                                    top: 4,
                                    right: 5,
                                    child: Container(
                                      width: 5,
                                      height: 5,
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? const Color(0xFF4ADE80)
                                            : const Color(0xFF10B981),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '${dayData.hijriDay}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: hijriTextColor,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${dayData.gregorianDay} ${dayData.gregorianMonth.substring(0, dayData.gregorianMonth.length >= 3 ? 3 : dayData.gregorianMonth.length)}',
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w600,
                                          color: gregorianTextColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      )
                    : Center(
                        child: Text(
                          'No calendar data available',
                          style: TextStyle(
                            color: isDark ? Colors.white60 : Colors.grey,
                          ),
                        ),
                      ),
          ),

          const SizedBox(height: 12),

          // Regional Moon Sighting Disclaimer Note at Bottom
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSubcontinent
                  ? (isDark
                      ? const Color(0xFFFBBF24).withValues(alpha: 0.1)
                      : const Color(0xFFD97724).withValues(alpha: 0.1))
                  : (isDark
                      ? const Color(0xFF60A5FA).withValues(alpha: 0.1)
                      : const Color(0xFF2563EB).withValues(alpha: 0.1)),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? cardBorder
                    : (isSubcontinent
                        ? const Color(0xFFD97724).withValues(alpha: 0.3)
                        : const Color(0xFF2563EB).withValues(alpha: 0.3)),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: isSubcontinent
                      ? (isDark
                          ? const Color(0xFFFBBF24)
                          : const Color(0xFFD97724))
                      : (isDark
                          ? const Color(0xFF60A5FA)
                          : const Color(0xFF2563EB)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isSubcontinent
                        ? 'Note: Adjusted for India, Pakistan, & Bangladesh based on local moon sighting. For consistency across prayer logs, dates advance at midnight (12:00 AM) instead of Maghrib.'
                        : 'Note: Follows astronomical calculation. For consistency across prayer logs, dates advance at midnight (12:00 AM) instead of Maghrib.',
                    style: GoogleFonts.lexend(
                      fontSize: 11,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white70 : const Color(0xFF334155),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Close Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark
                    ? const Color(0xFF22C55E)
                    : const Color(0xFFE8F4E5),
                foregroundColor: isDark
                    ? const Color(0xFF0F0F12)
                    : const Color(0xFF2A531D),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Close',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
