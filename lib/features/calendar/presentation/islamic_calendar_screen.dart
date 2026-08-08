import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/utils/hijri_date.dart';
import '../../../widgets/app_header_bar.dart';

class IslamicCalendarScreen extends StatefulWidget {
  const IslamicCalendarScreen({super.key});

  @override
  State<IslamicCalendarScreen> createState() => _IslamicCalendarScreenState();
}

class _IslamicCalendarScreenState extends State<IslamicCalendarScreen> {
  late DateTime _selectedDate;
  late HijriDate _currentHijri;

  final List<Map<String, String>> _hijriMonths = [
    {
      'number': '1',
      'nameEn': 'Muharram',
      'nameAr': 'المحَرَّم',
      'tag': '1st Month in Islam (Sacred)',
      'desc': 'The sacred month of Allah and the official beginning of the Islamic lunar calendar year.',
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
      'desc': 'The month in which Prophet Muhammad (peace be upon him) was born.',
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
      'desc': 'The month of preparation before Ramadan, recommended for voluntary fasting.',
      'color': '0xFFEC4899',
    },
    {
      'number': '9',
      'nameEn': 'Ramadan',
      'nameAr': 'رَمَضَان',
      'tag': '9th Month (Holy Fasting)',
      'desc': 'The holiest month of obligatory fasting, night prayers, and revelation of the Quran.',
      'color': '0xFF15803D',
    },
    {
      'number': '10',
      'nameEn': 'Shawwal',
      'nameAr': 'شَوَّال',
      'tag': '10th Month (Eid al-Fitr)',
      'desc': 'The month starting with Eid al-Fitr and the recommended 6 days of Sunnah fasting.',
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
      'desc': 'The month of the Hajj pilgrimage, the Day of Arafah, and Eid al-Adha.',
      'color': '0xFFB45309',
    },
  ];

  final List<Map<String, String>> _islamicEvents = [
    {
      'hijri': '1 Ramadan',
      'title': 'Start of Ramadan Fasting',
      'description': 'First day of the holy month of fasting, prayer, and Quran recitation.',
      'type': 'fasting',
    },
    {
      'hijri': '27 Ramadan',
      'title': 'Laylat al-Qadr (Night of Power)',
      'description': 'The night in which the Quran was first revealed to Prophet Muhammad (ﷺ). Better than 1,000 months.',
      'type': 'holy',
    },
    {
      'hijri': '1 Shawwal',
      'title': 'Eid al-Fitr',
      'description': 'Blessed Islamic festival celebrating the successful completion of Ramadan.',
      'type': 'eid',
    },
    {
      'hijri': '9 Dhul-Hijjah',
      'title': 'Day of Arafah',
      'description': 'The pinnacle day of Hajj pilgrimage. Fasting on this day expiates sins of two years.',
      'type': 'hajj',
    },
    {
      'hijri': '10 Dhul-Hijjah',
      'title': 'Eid al-Adha',
      'description': 'Feast of Sacrifice honoring Prophet Ibrahim\'s obedience to Allah.',
      'type': 'eid',
    },
    {
      'hijri': '1 Muharram',
      'title': 'Islamic New Year',
      'description': 'First day of the Hijri year commemorating Prophet Muhammad\'s (ﷺ) migration to Madinah.',
      'type': 'newyear',
    },
    {
      'hijri': '10 Muharram',
      'title': 'Day of Ashura',
      'description': 'Day Prophet Musa (AS) was saved from Pharaoh. Recommended Sunnah fast.',
      'type': 'fasting',
    },
    {
      'hijri': '12 Rabi\' al-Awwal',
      'title': 'Mawlid an-Nabi',
      'description': 'Commemorating the birth of Prophet Muhammad (peace be upon him).',
      'type': 'prophet',
    },
    {
      'hijri': '27 Rajab',
      'title': 'Isra and Mi\'raj',
      'description': 'The miraculous Night Journey and Ascension of Prophet Muhammad (ﷺ).',
      'type': 'miracle',
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _currentHijri = HijriDate.fromGregorian(_selectedDate);
  }

  void _changeMonth(int increment) {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + increment, 1);
      _currentHijri = HijriDate.fromGregorian(_selectedDate);
    });
  }

  void _showFullCalendarModal(BuildContext context) {
    final isDark = context.isDarkMode;
    DateTime tempDate = _selectedDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF192520) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final daysInMonth = DateUtils.getDaysInMonth(tempDate.year, tempDate.month);
            final firstDayOffset = DateTime(tempDate.year, tempDate.month, 1).weekday - 1;
            final currentHijriForMonth = HijriDate.fromGregorian(tempDate);

            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Month Selector Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () {
                          setModalState(() {
                            tempDate = DateTime(tempDate.year, tempDate.month - 1, 1);
                          });
                        },
                        icon: Icon(
                          Icons.chevron_left_rounded,
                          color: isDark ? Colors.white : const Color(0xFF2A531D),
                        ),
                      ),
                      Column(
                        children: [
                          Text(
                            currentHijriForMonth.monthNameEn.toUpperCase(),
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF2A531D),
                            ),
                          ),
                          Text(
                            '${currentHijriForMonth.year} AH  •  ${_getMonthName(tempDate.month)} ${tempDate.year}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () {
                          setModalState(() {
                            tempDate = DateTime(tempDate.year, tempDate.month + 1, 1);
                          });
                        },
                        icon: Icon(
                          Icons.chevron_right_rounded,
                          color: isDark ? Colors.white : const Color(0xFF2A531D),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Days of Week Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map((day) {
                      return Expanded(
                        child: Center(
                          child: Text(
                            day,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: day == 'Fri'
                                  ? const Color(0xFF16A34A)
                                  : (isDark ? Colors.white60 : Colors.grey.shade600),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),

                  // Calendar Days Grid View
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      childAspectRatio: 0.9,
                      mainAxisSpacing: 6,
                      crossAxisSpacing: 6,
                    ),
                    itemCount: daysInMonth + firstDayOffset,
                    itemBuilder: (context, index) {
                      if (index < firstDayOffset) {
                        return const SizedBox.shrink();
                      }

                      final dayNumber = index - firstDayOffset + 1;
                      final dayDate = DateTime(tempDate.year, tempDate.month, dayNumber);
                      final dayHijri = HijriDate.fromGregorian(dayDate);
                      final isToday = DateUtils.isSameDay(dayDate, DateTime.now());

                      return Container(
                        decoration: BoxDecoration(
                          color: isToday
                              ? const Color(0xFF2A531D)
                              : (isDark ? const Color(0xFF23322B) : const Color(0xFFF8FAFC)),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isToday
                                ? const Color(0xFF2A531D)
                                : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$dayNumber',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isToday
                                    ? Colors.white
                                    : (isDark ? Colors.white : const Color(0xFF1F2937)),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${dayHijri.day} ${dayHijri.monthNameEn.substring(0, 3)}',
                              style: TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w500,
                                color: isToday
                                    ? Colors.white.withValues(alpha: 0.9)
                                    : const Color(0xFFD97724),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2A531D),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(46),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Close Calendar', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final now = DateTime.now();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF17241E) : const Color(0xFFF9F9F9),
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: AppHeaderBar(
            title: 'ISLAMIC CALENDAR',
            showBackButton: true,
            systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
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
            // Calendar Month Navigation Banner Card (Clickable to view full Dual Calendar Grid)
            InkWell(
              onTap: () => _showFullCalendarModal(context),
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.all(18),
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
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () => _changeMonth(-1),
                          icon: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 28),
                        ),
                        Column(
                          children: [
                            Text(
                              _currentHijri.monthNameEn.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${_currentHijri.year} AH  •  ${_getMonthName(_selectedDate.month)} ${_selectedDate.year}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () => _changeMonth(1),
                          icon: const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 28),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.grid_view_rounded, size: 14, color: Colors.white70),
                        const SizedBox(width: 6),
                        Text(
                          'Tap to view monthly English & Hijri grid',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Colors.white.withValues(alpha: 0.85),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Today's Date Banner Card (Clickable to view full Dual Calendar Grid)
            InkWell(
              onTap: () => _showFullCalendarModal(context),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF192520) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? Colors.white10 : const Color(0xFF2A531D).withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A531D).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.calendar_month_rounded,
                        color: Color(0xFF2A531D),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TODAY\'S DUAL DATE',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              color: isDark ? Colors.white60 : Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            HijriDate.fromGregorian(now).formatEn(),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF1F2937),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${now.day}/${now.month}/${now.year}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2A531D),
                          ),
                        ),
                        const Text(
                          'English Date',
                          style: TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // FIRST MONTH IN ISLAM & 12 HIJRI MONTHS GUIDE
            const Text(
              '1ST MONTH IN ISLAM & THE 12 HIJRI MONTHS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: Color(0xFFD97724),
                decoration: TextDecoration.underline,
                decorationColor: Color(0xFFD97724),
              ),
            ),
            const SizedBox(height: 12),

            // 1st Month Spotlight Banner
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF192520) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFD97724).withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD97724).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          '1ST MONTH IN ISLAM',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFD97724),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'المحَرَّم',
                        textDirection: TextDirection.rtl,
                        style: GoogleFonts.amiri(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFD97724),
                          height: 1.7,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Muharram (1st Month of Islamic Year)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 4),
                  SelectableText(
                    'Muharram is the first month of the Islamic lunar calendar. It is one of the four sacred months (Ashhur al-Hurum) designated by Allah in Surah At-Tawbah [9:36]. Fasting on the 10th of Muharram (Day of Ashura) is highly recommended in Sunnah.',
                    style: GoogleFonts.lexend(
                      fontSize: 12.5,
                      color: isDark ? Colors.white70 : const Color(0xFF4B5563),
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // All 12 Months Cards Grid / List
            ..._hijriMonths.map(
              (m) => Container(
                margin: const EdgeInsets.only(bottom: 10),
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
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Color(int.parse(m['color']!)).withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          m['number']!,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(int.parse(m['color']!)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                m['nameEn']!,
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : const Color(0xFF1F2937),
                                ),
                              ),
                              Text(
                                m['nameAr']!,
                                textDirection: TextDirection.rtl,
                                style: GoogleFonts.amiri(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: Color(int.parse(m['color']!)),
                                  height: 1.7,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            m['tag']!,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: Color(int.parse(m['color']!)),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            m['desc']!,
                            style: GoogleFonts.lexend(
                              fontSize: 12,
                              color: isDark ? Colors.white60 : const Color(0xFF4B5563),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Significant Islamic Events Header
            const Text(
              'SIGNIFICANT ISLAMIC DATES & HOLIDAYS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: Color(0xFF2A531D),
                decoration: TextDecoration.underline,
                decorationColor: Color(0xFF2A531D),
              ),
            ),
            const SizedBox(height: 12),

            // Islamic Events List
            ..._islamicEvents.map(
              (event) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF192520) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getEventColor(event['type']!).withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        event['hijri']!,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _getEventColor(event['type']!),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event['title']!,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            event['description']!,
                            style: GoogleFonts.lexend(
                              fontSize: 12,
                              color: isDark ? Colors.white60 : const Color(0xFF4B5563),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Color _getEventColor(String type) {
    switch (type) {
      case 'eid':
        return const Color(0xFFD97724);
      case 'fasting':
        return const Color(0xFF16A34A);
      case 'holy':
        return const Color(0xFF9333EA);
      case 'hajj':
        return const Color(0xFF2563EB);
      default:
        return const Color(0xFF0D9488);
    }
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }
}
