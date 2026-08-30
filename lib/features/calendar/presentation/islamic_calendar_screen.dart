import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../core/extensions/context_extensions.dart';
import '../../../core/services/hijri_service.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/widgets/hijri_disclaimer_chip.dart';
import '../../../shared/widgets/islamic_monthly_calendar_modal.dart';
import '../../../widgets/app_header_bar.dart';

class IslamicCalendarScreen extends ConsumerStatefulWidget {
  const IslamicCalendarScreen({super.key});

  @override
  ConsumerState<IslamicCalendarScreen> createState() =>
      _IslamicCalendarScreenState();
}

class _IslamicCalendarScreenState extends ConsumerState<IslamicCalendarScreen> {
  int _currentMonthIndex = 2; // 0-based index for Rabi' al-Awwal (Month 3)
  int _activeHijriYear = 1448;

  final List<Map<String, String>> _hijriMonths = const [
    {
      'number': '1',
      'nameEn': 'Muharram',
      'nameAr': 'المحَرَّم',
      'tag': '1st Month in Islam (Sacred)',
      'desc':
          'The sacred month of Allah and the official beginning of the Islamic lunar calendar year.',
      'color': '0xFFD97724',
    },
    {
      'number': '2',
      'nameEn': 'Safar',
      'nameAr': 'صَفَر',
      'tag': '2nd Month',
      'desc': 'The second month of the Hijri calendar.',
      'color': '0xFF16A34A',
    },
    {
      'number': '3',
      'nameEn': 'Rabi\' al-Awwal',
      'nameAr': 'رَبِيع الأَوَّل',
      'tag': '3rd Month',
      'desc':
          'The month in which Prophet Muhammad (peace be upon him) was born.',
      'color': '0xFF2563EB',
    },
    {
      'number': '4',
      'nameEn': 'Rabi\' al-Thani',
      'nameAr': 'رَبِيع الآخِر',
      'tag': '4th Month',
      'desc': 'The fourth month of the Hijri calendar.',
      'color': '0xFF0D9488',
    },
    {
      'number': '5',
      'nameEn': 'Jumada al-Awwal',
      'nameAr': 'جُمَادَى الأُولَى',
      'tag': '5th Month',
      'desc': 'The fifth month of the Islamic calendar.',
      'color': '0xFF6366F1',
    },
    {
      'number': '6',
      'nameEn': 'Jumada al-Thani',
      'nameAr': 'جُمَادَى الآخِرَة',
      'tag': '6th Month',
      'desc': 'The sixth month of the Islamic calendar.',
      'color': '0xFF8B5CF6',
    },
    {
      'number': '7',
      'nameEn': 'Rajab',
      'nameAr': 'رَجَب',
      'tag': '7th Month (Sacred)',
      'desc': 'One of the four sacred months in Islam leading up to Ramadan.',
      'color': '0xFF9333EA',
    },
    {
      'number': '8',
      'nameEn': 'Sha\'ban',
      'nameAr': 'شَعْبَان',
      'tag': '8th Month',
      'desc':
          'The month of preparation before Ramadan, recommended for voluntary fasting.',
      'color': '0xFFEC4899',
    },
    {
      'number': '9',
      'nameEn': 'Ramadan',
      'nameAr': 'رَمَضَان',
      'tag': '9th Month (Holy Fasting)',
      'desc':
          'The holiest month of obligatory fasting, night prayers, and revelation of the Quran.',
      'color': '0xFF15803D',
    },
    {
      'number': '10',
      'nameEn': 'Shawwal',
      'nameAr': 'شَوَّال',
      'tag': '10th Month (Eid al-Fitr)',
      'desc':
          'The month starting with Eid al-Fitr and the recommended 6 days of Sunnah fasting.',
      'color': '0xFFD97724',
    },
    {
      'number': '11',
      'nameEn': 'Dhul-Qi\'dah',
      'nameAr': 'ذُو القَعْدَة',
      'tag': '11th Month (Sacred)',
      'desc': 'The 11th sacred month during which fighting is prohibited.',
      'color': '0xFF0284C7',
    },
    {
      'number': '12',
      'nameEn': 'Dhul-Hijjah',
      'nameAr': 'ذُو الحِجَّة',
      'tag': '12th Month (Sacred & Hajj)',
      'desc':
          'The month of the Hajj pilgrimage, the Day of Arafah, and Eid al-Adha.',
      'color': '0xFFB45309',
    },
  ];

  final List<Map<String, String>> _islamicEvents = const [
    {
      'hijri': '1 Ramadan',
      'title': 'Start of Ramadan Fasting',
      'description':
          'First day of the holy month of fasting, prayer, and Quran recitation.',
      'type': 'fasting',
    },
    {
      'hijri': '27 Ramadan',
      'title': 'Laylat al-Qadr (Night of Power)',
      'description':
          'The night in which the Quran was first revealed to Prophet Muhammad (ﷺ). Better than 1,000 months.',
      'type': 'holy',
    },
    {
      'hijri': '1 Shawwal',
      'title': 'Eid al-Fitr',
      'description':
          'Blessed Islamic festival celebrating the successful completion of Ramadan.',
      'type': 'eid',
    },
    {
      'hijri': '9 Dhul-Hijjah',
      'title': 'Day of Arafah',
      'description':
          'The pinnacle day of Hajj pilgrimage. Fasting on this day expiates sins of two years.',
      'type': 'hajj',
    },
    {
      'hijri': '10 Dhul-Hijjah',
      'title': 'Eid al-Adha',
      'description':
          'Feast of Sacrifice honoring Prophet Ibrahim\'s obedience to Allah.',
      'type': 'eid',
    },
    {
      'hijri': '1 Muharram',
      'title': 'Islamic New Year',
      'description':
          'First day of the Hijri year commemorating Prophet Muhammad\'s (ﷺ) migration to Madinah.',
      'type': 'newyear',
    },
    {
      'hijri': '10 Muharram',
      'title': 'Day of Ashura',
      'description':
          'Day Prophet Musa (AS) was saved from Pharaoh. Recommended Sunnah fast.',
      'type': 'fasting',
    },
    {
      'hijri': '12 Rabi\' al-Awwal',
      'title': 'Mawlid an-Nabi',
      'description':
          'Commemorating the birth of Prophet Muhammad (peace be upon him).',
      'type': 'prophet',
    },
    {
      'hijri': '27 Rajab',
      'title': 'Isra and Mi\'raj',
      'description':
          'The miraculous Night Journey and Ascension of Prophet Muhammad (ﷺ).',
      'type': 'miracle',
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initCurrentHijriMonth();
    });
  }

  void _initCurrentHijriMonth() async {
    final todayAsync = ref.read(todayHijriProvider);
    final todayData = todayAsync.value;
    if (todayData != null) {
      setState(() {
        _activeHijriYear = todayData.year;
        _currentMonthIndex = (todayData.monthNumber - 1).clamp(0, 11);
      });
    }
  }

  void _openGregorianToHijriModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _GregorianToHijriModal(),
    );
  }

  Color _getEventColor(String type) {
    switch (type) {
      case 'fasting':
        return const Color(0xFF16A34A);
      case 'holy':
        return const Color(0xFF9333EA);
      case 'eid':
        return const Color(0xFFD97724);
      case 'hajj':
        return const Color(0xFFB45309);
      case 'newyear':
        return const Color(0xFF2563EB);
      case 'prophet':
        return const Color(0xFF0D9488);
      case 'miracle':
        return const Color(0xFF6366F1);
      default:
        return const Color(0xFF2A531D);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final todayAsync = ref.watch(todayHijriProvider);
    final todayData = todayAsync.value;
    final currentHijriMonthMeta = _hijriMonths[_currentMonthIndex];
    final isAladhan = todayData?.isAladhan ?? false;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF17241E)
          : const Color(0xFFF9F9F9),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AppHeaderBar(
          title: 'ISLAMIC CALENDAR',
          showBackButton: true,
          backgroundColor: isDark ? const Color(0xFF192520) : Colors.white,
          iconColor: isDark ? Colors.white : const Color(0xFF2A531D),
          titleWidget: Text(
            'ISLAMIC CALENDAR',
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF2A531D),
              fontWeight: FontWeight.bold,
              fontSize: 18,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(),
        children: [
          // Aladhan Disclaimer Chip if applicable
          if (isAladhan) HijriDisclaimerChip(isAladhan: true),

          // Today's Hijri Hero Card
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2A531D), Color(0xFF15803D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2A531D).withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'TODAY\'S HIJRI DATE',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    Text(
                      todayData?.monthAr ?? currentHijriMonthMeta['nameAr']!,
                      textDirection: TextDirection.rtl,
                      style: AppTypography.arabicHeader(
                        fontSize: 22,
                        color: Colors.amber.shade200,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  todayData != null
                      ? '${todayData.day} ${todayData.monthEn} ${todayData.year} AH'
                      : '${currentHijriMonthMeta['nameEn']} $_activeHijriYear AH',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('EEEE, d MMMM yyyy').format(DateTime.now()),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Action Buttons Row (Convert Date & View Monthly Calendar)
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _openGregorianToHijriModal(context),
                  icon: const Icon(Icons.sync_alt_rounded, size: 18),
                  label: const Text(
                    'Convert Date',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2A531D),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 1,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => IslamicMonthlyCalendarModal.show(
                    context,
                    initialMonthIndex: _currentMonthIndex,
                    activeHijriYear: _activeHijriYear,
                  ),
                  icon: const Icon(Icons.calendar_month_rounded, size: 18),
                  label: const Text(
                    'View Calendar',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2A531D),
                    side: const BorderSide(
                      color: Color(0xFF2A531D),
                      width: 1.5,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 12 Hijri Months Directory Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ISLAMIC MONTHS DIRECTORY',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: isDark ? Colors.white70 : const Color(0xFF2A531D),
                  decoration: TextDecoration.underline,
                  decorationColor: const Color(0xFF2A531D),
                ),
              ),
              Text(
                'Year $_activeHijriYear AH',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFD97724),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _hijriMonths.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final month = _hijriMonths[index];
              final isCurrent = index == _currentMonthIndex;
              final accentColor = Color(int.parse(month['color']!));

              return InkWell(
                onTap: () {
                  IslamicMonthlyCalendarModal.show(
                    context,
                    initialMonthIndex: index,
                    activeHijriYear: _activeHijriYear,
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF192520) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isCurrent
                          ? const Color(0xFF2A531D)
                          : (isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                      width: isCurrent ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            month['number']!,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: accentColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  month['nameEn']!,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF1F2937),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '(${month['nameAr']!})',
                                  textDirection: TextDirection.rtl,
                                  style: AppTypography.arabicHeader(
                                    fontSize: 14,
                                    color: accentColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              month['tag']!,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: accentColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.calendar_month_rounded,
                        size: 20,
                        color: Color(0xFF2A531D),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // Significant Islamic Events List
          Text(
            'KEY ISLAMIC EVENTS & HOLIDAYS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: isDark ? Colors.white70 : const Color(0xFF2A531D),
              decoration: TextDecoration.underline,
              decorationColor: const Color(0xFF2A531D),
            ),
          ),
          const SizedBox(height: 12),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _islamicEvents.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final event = _islamicEvents[index];
              final eventColor = _getEventColor(event['type']!);

              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF192520) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: eventColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        event['hijri']!,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: eventColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event['title']!,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            event['description']!,
                            style: GoogleFonts.lexend(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.white60
                                  : const Color(0xFF4B5563),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _GregorianToHijriModal extends ConsumerStatefulWidget {
  const _GregorianToHijriModal();

  @override
  ConsumerState<_GregorianToHijriModal> createState() =>
      _GregorianToHijriModalState();
}

class _GregorianToHijriModalState
    extends ConsumerState<_GregorianToHijriModal> {
  late DateTime _selectedDate;
  HijriDateData? _convertedResult;
  bool _isConverting = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _convertDate();
  }

  Future<void> _convertDate() async {
    setState(() {
      _isConverting = true;
    });

    final hijriService = ref.read(hijriServiceProvider);
    final location = ref.read(currentLocationProvider).value;

    final result = await hijriService.convertGregorianToHijri(
      _selectedDate,
      country: location?.country,
    );

    if (mounted) {
      setState(() {
        _convertedResult = result;
        _isConverting = false;
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2A531D),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1F2937),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      await _convertDate();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final location = ref.watch(currentLocationProvider).value;
    final isSubcontinent = HijriService.isChandKiTarikhRegion(
      location?.country,
    );

    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF192520) : Colors.white,
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
              color: isDark ? Colors.white24 : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 18),

          Text(
            'GREGORIAN TO HIJRI CONVERTER',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: isDark ? Colors.white : const Color(0xFF2A531D),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Select any Gregorian date to get exact Islamic Hijri date',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white60 : Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 20),

          // Date Selector Button
          InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF23322B)
                    : const Color(0xFFF4FAF3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF2A531D).withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    color: Color(0xFF2A531D),
                    size: 22,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'SELECTED GREGORIAN DATE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: Color(0xFF8C6D53),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateFormat('EEEE, d MMMM yyyy').format(_selectedDate),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF1F2937),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A531D),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.edit_calendar_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Conversion Output Result Box
          if (_isConverting)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: CircularProgressIndicator(color: Color(0xFF2A531D)),
            )
          else if (_convertedResult != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2A531D), Color(0xFF15803D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2A531D).withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'HIJRI CONVERSION',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      Text(
                        _convertedResult!.monthAr,
                        textDirection: TextDirection.rtl,
                        style: AppTypography.arabicHeader(
                          fontSize: 22,
                          color: Colors.amber.shade200,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Text(
                    '${_convertedResult!.day} ${_convertedResult!.monthEn}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_convertedResult!.year} AH',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: Colors.white24, height: 1),
                  const SizedBox(height: 10),

                  Text(
                    _convertedResult!.formatted,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.amber.shade100,
                    ),
                  ),
                ],
              ),
            ),
          if (_convertedResult != null) ...[
            const SizedBox(height: 14),

            // Regional Moon Sighting Disclaimer Note
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSubcontinent
                    ? const Color(0xFFD97724).withValues(alpha: 0.1)
                    : const Color(0xFF2563EB).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSubcontinent
                      ? const Color(0xFFD97724).withValues(alpha: 0.3)
                      : const Color(0xFF2563EB).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: isSubcontinent
                        ? const Color(0xFFD97724)
                        : const Color(0xFF2563EB),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isSubcontinent
                          ? 'Note: We have adjusted the Hijri dates for India, Pakistan, & Bangladesh based on local moon sighting. Hijri dates may vary by ±1 day.'
                          : 'Note: Hijri dates follow standard global astronomical calculation. Hijri dates may vary by ±1 day based on local moon sighting.',
                      style: GoogleFonts.lexend(
                        fontSize: 11,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? Colors.white70
                            : const Color(0xFF334155),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark
                    ? const Color(0xFF23322B)
                    : const Color(0xFFE8F4E5),
                foregroundColor: const Color(0xFF2A531D),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Close',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
