import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../widgets/app_header_bar.dart';

class WhatIsIslamScreen extends StatelessWidget {
  const WhatIsIslamScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF17241E) : const Color(0xFFF9F9F9),
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: AppHeaderBar(
            title: 'WHAT IS ISLAM',
            showBackButton: true,
            systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
            backgroundColor: isDark ? const Color(0xFF192520) : Colors.white,
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
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2A531D), Color(0xFF16A34A)],
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'THE WAY OF PEACE',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
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
                  const SizedBox(height: 6),
                  Text(
                    'Islam is an Arabic word meaning "peace" and "submission to Almighty Allah". It is a complete way of life guiding humanity towards righteousness, purpose, and good character.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.9),
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Section 1: The 5 Pillars of Islam Header
            const Text(
              'THE 5 PILLARS OF ISLAM (ARKAN AL-ISLAM)',
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

            _buildPillarTile(
              number: '1',
              title: 'Shahada (Declaration of Faith)',
              arabic: 'أَشْهَدُ أَنْ لَا إِلٰهَ إِلَّا اللهُ وَأَشْهَدُ أَنَّ مُحَمَّدًا رَسُولُ اللهِ',
              description: 'Bearing witness that there is no deity worthy of worship except Allah, and Muhammad (ﷺ) is His Messenger.',
              color: const Color(0xFF16A34A),
              isDark: isDark,
            ),
            _buildPillarTile(
              number: '2',
              title: 'Salah (Daily Prayer)',
              arabic: 'الصَّلَاة',
              description: 'Performing five daily obligatory prayers to maintain a continuous spiritual connection with Almighty Allah.',
              color: const Color(0xFF2563EB),
              isDark: isDark,
            ),
            _buildPillarTile(
              number: '3',
              title: 'Zakat (Obligatory Charity)',
              arabic: 'الزَّكَاة',
              description: 'Giving 2.5% of accumulated annual savings to purify wealth and support the poor, orphans, and needy.',
              color: const Color(0xFFD97724),
              isDark: isDark,
            ),
            _buildPillarTile(
              number: '4',
              title: 'Sawm (Fasting in Ramadan)',
              arabic: 'الصَّوْم',
              description: 'Fasting from dawn until sunset during the month of Ramadan to cultivate piety, gratitude, and self-restraint.',
              color: const Color(0xFF9333EA),
              isDark: isDark,
            ),
            _buildPillarTile(
              number: '5',
              title: 'Hajj (Pilgrimage to Makkah)',
              arabic: 'الْحَجّ',
              description: 'Pilgrimage to the Holy Kaaba in Makkah once in a lifetime for those physically and financially able.',
              color: const Color(0xFF0D9488),
              isDark: isDark,
            ),

            const SizedBox(height: 24),

            // Section 2: The 6 Articles of Faith Header
            const Text(
              'THE 6 ARTICLES OF FAITH (IMAN)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: Color(0xFF2563EB),
                decoration: TextDecoration.underline,
                decorationColor: Color(0xFF2563EB),
              ),
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF192520) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                children: [
                  _buildFaithBullet('1. Belief in Allah', 'The One and Only Creator, without partners, offspring, or equals.'),
                  const Divider(height: 16),
                  _buildFaithBullet('2. Belief in His Angels', 'Noble spiritual beings created from light who carry out Allah\'s commands.'),
                  const Divider(height: 16),
                  _buildFaithBullet('3. Belief in Divine Books', 'Original scriptures including the Torah, Gospel, Psalms, and the final unchanged Quran.'),
                  const Divider(height: 16),
                  _buildFaithBullet('4. Belief in His Prophets', 'Messengers sent to all nations, from Adam, Noah, Abraham, Moses, Jesus, to Muhammad (ﷺ).'),
                  const Divider(height: 16),
                  _buildFaithBullet('5. Belief in the Day of Judgment', 'The day of resurrection when all humans will account for their deeds.'),
                  const Divider(height: 16),
                  _buildFaithBullet('6. Belief in Divine Decree (Qadar)', 'Allah\'s ultimate knowledge, wisdom, and sovereign decree over all creation.'),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Section 3: Universal Verses of Peace Header
            const Text(
              'QURANIC VERSES ON HARMONY & MERCY',
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

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF192520) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'يا أَيُّهَا النَّاسُ إِنَّا خَلَقْنَاكُم مِّن ذَكَرٍ وَأُنثَىٰ وَجَعَلْنَاكُمْ شُعُوبًا وَقَبَائِلَ لِتَعَارَفُوا',
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: GoogleFonts.amiri(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2A531D),
                      height: 1.7,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SelectableText(
                    '"O mankind, indeed We have created you from male and female and made you peoples and tribes that you may know one another. Indeed, the most noble of you in the sight of Allah is the most righteous of you."',
                    style: GoogleFonts.lexend(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: isDark ? Colors.white70 : const Color(0xFF334155),
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Surah Al-Hujurat [49:13]',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFD97724),
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
    required String title,
    required String arabic,
    required String description,
    required Color color,
    required bool isDark,
  }) {
    return Container(
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
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
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
                  style: GoogleFonts.amiri(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                    height: 1.7,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
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
    );
  }

  Widget _buildFaithBullet(String title, String desc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2563EB),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          desc,
          style: GoogleFonts.lexend(
            fontSize: 12.5,
            color: const Color(0xFF4B5563),
            height: 1.35,
          ),
        ),
      ],
    );
  }
}
