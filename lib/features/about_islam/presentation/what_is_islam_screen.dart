import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../widgets/app_header_bar.dart';

class WhatIsIslamScreen extends StatelessWidget {
  const WhatIsIslamScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final primaryColor = isDark
        ? const Color(0xFF18A74C)
        : const Color(0xFF2A531D);
    final cardBg = isDark ? const Color(0xFF18181B) : Colors.white;
    final cardBorder = isDark
        ? const Color(0xFF27272A)
        : const Color(0xFFE2E8F0);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF0F0F12)
            : const Color(0xFFF8FAFC),
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: AppHeaderBar(
            title: 'WHAT IS ISLAM',
            showBackButton: true,
            systemOverlayStyle: isDark
                ? SystemUiOverlayStyle.light
                : SystemUiOverlayStyle.dark,
            backgroundColor: cardBg,
            iconColor: isDark ? Colors.white : const Color(0xFF2A531D),
            titleWidget: Text(
              'WHAT IS ISLAM',
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
            // Top Hero Banner Card
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF143820), const Color(0xFF18181B)]
                      : [const Color(0xFF2A531D), const Color(0xFF15803D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF18A74C).withValues(alpha: 0.3)
                      : Colors.transparent,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.4)
                        : const Color(0xFF2A531D).withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF18A74C).withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'THE WAY OF PEACE',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: isDark ? const Color(0xFF86EFAC) : Colors.white,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Understanding Islam',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Islam is an Arabic word meaning "peace" and "submission to Almighty Allah". It is a comprehensive way of life that guides humanity towards righteousness, inner peace, and noble character.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.9),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Section 1: The 5 Pillars of Islam Header
            Row(
              children: [
                Icon(
                  Icons.account_balance_rounded,
                  size: 18,
                  color: primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'THE 5 PILLARS OF ISLAM (ARKAN AL-ISLAM)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: primaryColor,
                    decoration: TextDecoration.underline,
                    decorationColor: primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            _buildPillarTile(
              number: '1',
              icon: Icons.verified_user_rounded,
              title: 'Shahada (Declaration of Faith)',
              arabic:
                  'أَشْهَدُ أَنْ لَا إِلٰهَ إِلَّا اللهُ وَأَشْهَدُ أَنَّ مُحَمَّدًا رَسُولُ اللهِ',
              description:
                  'Bearing witness that there is no deity worthy of worship except Allah, and Muhammad (ﷺ) is His Messenger.',
              color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A),
              isDark: isDark,
              cardBg: cardBg,
              cardBorder: cardBorder,
            ),
            _buildPillarTile(
              number: '2',
              icon: Icons.schedule_rounded,
              title: 'Salah (Daily Prayer)',
              arabic: 'الصَّلَاة',
              description:
                  'Performing five daily obligatory prayers to maintain a continuous spiritual connection with Almighty Allah.',
              color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
              isDark: isDark,
              cardBg: cardBg,
              cardBorder: cardBorder,
            ),
            _buildPillarTile(
              number: '3',
              icon: Icons.volunteer_activism_rounded,
              title: 'Zakat (Obligatory Charity)',
              arabic: 'الزَّكَاة',
              description:
                  'Giving 2.5% of accumulated annual savings to purify wealth and support the poor, orphans, and needy.',
              color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97724),
              isDark: isDark,
              cardBg: cardBg,
              cardBorder: cardBorder,
            ),
            _buildPillarTile(
              number: '4',
              icon: Icons.nights_stay_rounded,
              title: 'Sawm (Fasting in Ramadan)',
              arabic: 'الصَّوْم',
              description:
                  'Fasting from dawn until sunset during the holy month of Ramadan to cultivate piety, gratitude, and self-restraint.',
              color: isDark ? const Color(0xFFC084FC) : const Color(0xFF9333EA),
              isDark: isDark,
              cardBg: cardBg,
              cardBorder: cardBorder,
            ),
            _buildPillarTile(
              number: '5',
              icon: Icons.mosque_rounded,
              title: 'Hajj (Pilgrimage to Makkah)',
              arabic: 'الْحَجّ',
              description:
                  'Pilgrimage to the Holy Kaaba in Makkah once in a lifetime for those physically and financially able.',
              color: isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0D9488),
              isDark: isDark,
              cardBg: cardBg,
              cardBorder: cardBorder,
            ),

            const SizedBox(height: 24),

            // Section 2: The 6 Articles of Faith Header
            Row(
              children: [
                Icon(
                  Icons.stars_rounded,
                  size: 18,
                  color: isDark
                      ? const Color(0xFF60A5FA)
                      : const Color(0xFF2563EB),
                ),
                const SizedBox(width: 8),
                Text(
                  'THE 6 ARTICLES OF FAITH (IMAN)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: isDark
                        ? const Color(0xFF60A5FA)
                        : const Color(0xFF2563EB),
                    decoration: TextDecoration.underline,
                    decorationColor: isDark
                        ? const Color(0xFF60A5FA)
                        : const Color(0xFF2563EB),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: cardBorder),
              ),
              child: Column(
                children: [
                  _buildFaithTile(
                    icon: Icons.brightness_7_rounded,
                    title: '1. Belief in Allah (Tawheed)',
                    desc:
                        'The One and Only Creator, without partners, offspring, or equals.',
                    color: isDark
                        ? const Color(0xFF4ADE80)
                        : const Color(0xFF16A34A),
                    isDark: isDark,
                  ),
                  Divider(height: 20, color: cardBorder),
                  _buildFaithTile(
                    icon: Icons.auto_awesome_rounded,
                    title: '2. Belief in His Angels (Mala\'ikah)',
                    desc:
                        'Noble spiritual beings created from light who carry out Allah\'s commands faithfully.',
                    color: isDark
                        ? const Color(0xFF60A5FA)
                        : const Color(0xFF2563EB),
                    isDark: isDark,
                  ),
                  Divider(height: 20, color: cardBorder),
                  _buildFaithTile(
                    icon: Icons.menu_book_rounded,
                    title: '3. Belief in Divine Books (Kutub)',
                    desc:
                        'Original divine revelations including the Torah, Gospel, Psalms, and the final unchanged Quran.',
                    color: isDark
                        ? const Color(0xFFFBBF24)
                        : const Color(0xFFD97724),
                    isDark: isDark,
                  ),
                  Divider(height: 20, color: cardBorder),
                  _buildFaithTile(
                    icon: Icons.people_alt_rounded,
                    title: '4. Belief in His Prophets (Rusul)',
                    desc:
                        'Messengers sent to all nations, from Adam, Noah, Abraham, Moses, Jesus, to Muhammad (ﷺ).',
                    color: isDark
                        ? const Color(0xFFC084FC)
                        : const Color(0xFF9333EA),
                    isDark: isDark,
                  ),
                  Divider(height: 20, color: cardBorder),
                  _buildFaithTile(
                    icon: Icons.hourglass_bottom_rounded,
                    title: '5. Belief in the Day of Judgment (Akhirah)',
                    desc:
                        'The day of resurrection and justice when all humans will account for their deeds before Allah.',
                    color: isDark
                        ? const Color(0xFFF87171)
                        : const Color(0xFFDC2626),
                    isDark: isDark,
                  ),
                  Divider(height: 20, color: cardBorder),
                  _buildFaithTile(
                    icon: Icons.balance_rounded,
                    title: '6. Belief in Divine Decree (Al-Qadr)',
                    desc:
                        'Allah\'s ultimate knowledge, wisdom, and sovereign decree over all creation and events.',
                    color: isDark
                        ? const Color(0xFF2DD4BF)
                        : const Color(0xFF0D9488),
                    isDark: isDark,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Section 3: Universal Verses of Peace Header
            Row(
              children: [
                Icon(
                  Icons.format_quote_rounded,
                  size: 18,
                  color: isDark
                      ? const Color(0xFFFBBF24)
                      : const Color(0xFFD97724),
                ),
                const SizedBox(width: 8),
                Text(
                  'QURANIC VERSES ON HARMONY & MERCY',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: isDark
                        ? const Color(0xFFFBBF24)
                        : const Color(0xFFD97724),
                    decoration: TextDecoration.underline,
                    decorationColor: isDark
                        ? const Color(0xFFFBBF24)
                        : const Color(0xFFD97724),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'يا أَيُّهَا النَّاسُ إِنَّا خَلَقْنَاكُم مِّن ذَكَرٍ وَأُنثَىٰ وَجَعَلْنَاكُمْ شُعُوبًا وَقَبَائِلَ لِتَعَارَفُوا',
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: AppTypography.arabicHeader(
                      fontSize: 21,
                      color: primaryColor,
                      height: 1.8,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SelectableText(
                    '"O mankind, indeed We have created you from male and female and made you peoples and tribes that you may know one another. Indeed, the most noble of you in the sight of Allah is the most righteous of you."',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lexend(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: isDark ? Colors.white70 : const Color(0xFF334155),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color:
                            (isDark
                                    ? const Color(0xFFFBBF24)
                                    : const Color(0xFFD97724))
                                .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Surah Al-Hujurat [49:13]',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? const Color(0xFFFBBF24)
                              : const Color(0xFFD97724),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPillarTile({
    required String number,
    required IconData icon,
    required String title,
    required String arabic,
    required String description,
    required Color color,
    required bool isDark,
    required Color cardBg,
    required Color cardBorder,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(icon, size: 22, color: color),
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    width: 15,
                    height: 15,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        number,
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  arabic,
                  textDirection: TextDirection.rtl,
                  style: AppTypography.arabicHeader(
                    fontSize: 16,
                    color: color,
                    height: 1.7,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.lexend(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : const Color(0xFF4B5563),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaithTile({
    required IconData icon,
    required String title,
    required String desc,
    required Color color,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                desc,
                style: GoogleFonts.lexend(
                  fontSize: 12,
                  color: isDark ? Colors.white70 : const Color(0xFF4B5563),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
