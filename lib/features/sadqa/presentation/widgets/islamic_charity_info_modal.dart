import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_typography.dart';

class IslamicCharityInfoModal extends StatefulWidget {
  const IslamicCharityInfoModal({super.key});

  @override
  State<IslamicCharityInfoModal> createState() =>
      _IslamicCharityInfoModalState();
}

class _IslamicCharityInfoModalState extends State<IslamicCharityInfoModal> {
  int _selectedIndex = 0;

  final List<Map<String, dynamic>> _gridItems = [
    {
      'title': 'Virtues & Benefits',
      'icon': Icons.auto_awesome_rounded,
      'color': const Color(0xFF16A34A),
    },
    {
      'title': 'Warnings if Neglect',
      'icon': Icons.warning_amber_rounded,
      'color': const Color(0xFFDC2626),
    },
    {
      'title': 'Sadaqah vs Zakat',
      'icon': Icons.balance_rounded,
      'color': const Color(0xFFD97724),
    },
    {
      'title': '8 Eligible Recipients',
      'icon': Icons.people_alt_rounded,
      'color': const Color(0xFF2563EB),
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final primaryColor = const Color(0xFF2A531D);

    return Container(
      height: MediaQuery.of(context).size.height * 0.90, // 90% screen height
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF192520) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        children: [
          // Drag Handle Bar
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Modal Title Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAB308).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.menu_book_rounded,
                    color: Color(0xFFD97724),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Islamic Charity Guidelines',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2A531D),
                        ),
                      ),
                      Text(
                        'Virtues of Sadaqah & Rules of Zakat',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 2x2 Grid Selection Bar (2 Rows x 2 Columns)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _gridItems.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 5,
                mainAxisSpacing: 5,
                childAspectRatio: 3.5,
              ),
              itemBuilder: (context, index) {
                final item = _gridItems[index];
                final isSelected = _selectedIndex == index;
                final iconData = item['icon'] as IconData;

                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? primaryColor
                          : (isDark
                                ? const Color(0xFF23322B)
                                : const Color(0xFFF3FAF2)),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? primaryColor
                            : primaryColor.withValues(alpha: 0.2),
                        width: isSelected ? 2.0 : 1.0,
                      ),
                      // boxShadow: isSelected
                      //     ? [
                      //         BoxShadow(
                      //           color: primaryColor.withValues(alpha: 0.3),
                      //           blurRadius: 6,
                      //           offset: const Offset(0, 3),
                      //         ),
                      //       ]
                      //     : [],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white.withValues(alpha: 0.2)
                                : primaryColor.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            iconData,
                            size: 16,
                            color: isSelected ? Colors.white : primaryColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item['title'] as String,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark
                                        ? Colors.white
                                        : const Color(0xFF2A531D)),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Selected Section Body
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                _buildVirtuesTab(isDark),
                _buildWarningsTab(isDark),
                _buildComparisonTab(isDark),
                _buildRecipientsTab(isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVirtuesTab(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(12),
      physics: const BouncingScrollPhysics(),
      children: [
        // Highlight Quranic Verse Box
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFDF8F0),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFEAB308).withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'مَّن ذَا الَّذِي يُقْرِضُ اللَّهَ قَرْضًا حَسَنًا فَيُضَاعِفَهُ لَهُ أَضْعَافًا كَثِيرَةً',
                  textDirection: TextDirection.rtl,
                  style: AppTypography.arabicBody(
                    fontSize: 20,
                    color: const Color(0xFF78350F),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '"Who is it that would loan Allah a goodly loan so He may multiply it for him many times over?" (Surah Al-Baqarah 2:245)',
                style: GoogleFonts.lexend(
                  fontSize: 12.5,
                  fontStyle: FontStyle.italic,
                  color: const Color(0xFF92400E),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // List of Virtues Cards
        _buildBenefitCard(
          icon: Icons.shield_rounded,
          iconColor: const Color(0xFF16A34A),
          title: 'Protection & Wiping Away Sins',
          description:
              '"Sadaqah extinguishes sin as water extinguishes fire." (Jami` at-Tirmidhi 614)',
          arabic:
              'الصَّدَقَةُ تُطْفِئُ الْخَطِيئَةَ كَمَا يُطْفِئُ الْمَاءُ النَّارَ',
          isDark: isDark,
        ),
        const SizedBox(height: 8),

        _buildBenefitCard(
          icon: Icons.trending_up_rounded,
          iconColor: const Color(0xFF2563EB),
          title: 'Increases Wealth & Brings Barakah',
          description:
              '"Sadaqah does not decrease wealth." (Sahih Muslim 2588). Giving charity purifies your remaining wealth and attracts divine multiplication.',
          arabic: 'مَا نَقَصَتْ صَدَقَةٌ مِنْ مَالٍ',
          isDark: isDark,
        ),
        const SizedBox(height: 8),

        _buildBenefitCard(
          icon: Icons.wb_sunny_rounded,
          iconColor: const Color(0xFFEAB308),
          title: 'Shade on Judgment Day',
          description:
              '"The believer’s shade on the Day of Resurrection will be his charity." (Sunan al-Tirmidhi 604)',
          arabic: 'ظِلُّ الْمُؤْمِنِ يَوْمَ الْقِيَامَةِ صَدَقَتُهُ',
          isDark: isDark,
        ),
        const SizedBox(height: 8),

        _buildBenefitCard(
          icon: Icons.favorite_rounded,
          iconColor: const Color(0xFFDC2626),
          title: 'Heals Illness & Wards Off Calamities',
          description:
              '"Treat your sick ones with Sadaqah." (Bayhaqi). Charity acts as a spiritual barrier against unexpected trials and harm.',
          arabic: 'دَاوُوا مَرْضَاكُمْ بِالصَّدَقَةِ',
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildWarningsTab(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(12),
      physics: const BouncingScrollPhysics(),
      children: [
        // Warning Header Box
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFEF4444).withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFDC2626),
                    size: 22,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Zakat is Mandatory (Fard)',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFDC2626),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Zakat is one of the 5 Pillars of Islam. Withholding Zakat after reaching Nisab is a major sin and brings severe spiritual consequences in both this world and the Hereafter.',
                style: GoogleFonts.lexend(
                  fontSize: 12,
                  color: const Color(0xFF991B1B),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Quran Verse Warning
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2D1F1F) : const Color(0xFFFFF5F5),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFDC2626).withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Quranic Warning (Surah At-Tawbah 9:34-35)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFDC2626),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'وَالَّذِينَ يَكْنِزُونَ الذَّهَبَ وَالْفِضَّةَ وَلَا يُنفِقُونَهَا فِي سَبِيلِ اللَّهِ فَبَشِّرْهُم بِعَذَابٍ أَلِيمٍ',
                  textDirection: TextDirection.rtl,
                  style: AppTypography.arabicBody(
                    fontSize: 18,
                    color: const Color(0xFF7F1D1D),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '"And those who hoard gold and silver and spend it not in the way of Allah – give them tidings of a painful punishment. On the Day when it will be heated in the fire of Hell and branded therewith their foreheads, flanks, and backs..."',
                style: GoogleFonts.lexend(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: isDark ? Colors.white70 : const Color(0xFF374151),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Hadith Warning
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2A241F) : const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFEAB308).withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Hadith Warning (Sahih al-Bukhari 1403)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFB45309),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '"Whoever is given wealth by Allah and does not pay Zakat for it, his wealth will be made into a bald poisonous snake with two black spots over its eyes, which will encircle his neck on the Day of Resurrection and seize his cheeks..."',
                style: GoogleFonts.lexend(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: isDark ? Colors.white70 : const Color(0xFF78350F),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildComparisonTab(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(12),
      physics: const BouncingScrollPhysics(),
      children: [
        const Text(
          'Difference between Sadaqah & Zakat',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2A531D),
          ),
        ),
        const SizedBox(height: 12),

        _buildComparisonRow(
          feature: 'Islamic Status',
          sadaqah: 'Voluntary Charity (Mustahabb / Sunnah)',
          zakat: 'Mandatory Obligation (3rd Pillar of Islam)',
          isDark: isDark,
        ),
        const SizedBox(height: 10),

        _buildComparisonRow(
          feature: 'Amount Required',
          sadaqah: 'Any amount, large or small, as per heart',
          zakat: 'Fixed 2.5% on qualifying net assets',
          isDark: isDark,
        ),
        const SizedBox(height: 10),

        _buildComparisonRow(
          feature: 'Eligibility Threshold',
          sadaqah: 'No minimum wealth required',
          zakat: 'Requires Nisab threshold (Gold 87.48g / Silver 612.36g)',
          isDark: isDark,
        ),
        const SizedBox(height: 10),

        _buildComparisonRow(
          feature: 'Time Period',
          sadaqah: 'Anytime, any day of the year',
          zakat: 'Annually after holding Nisab for 1 lunar year (Hawl)',
          isDark: isDark,
        ),
        const SizedBox(height: 10),

        _buildComparisonRow(
          feature: 'Recipients',
          sadaqah: 'Anyone in need, non-Muslims, public causes',
          zakat: 'Strictly 8 categories listed in Quran (Surah 9:60)',
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildRecipientsTab(bool isDark) {
    final recipients = [
      {
        'title': '1. Al-Fuqara (The Poor)',
        'desc':
            'Individuals with zero or very meager income who cannot meet basic survival needs.',
        'icon': Icons.person_off_rounded,
      },
      {
        'title': '2. Al-Masakin (The Needy)',
        'desc':
            'People who have some income but it falls short of basic living requirements.',
        'icon': Icons.volunteer_activism_rounded,
      },
      {
        'title': '3. Al-Amilina \'Alayha (Zakat Collectors)',
        'desc': 'Appointed administrators who collect and distribute Zakat.',
        'icon': Icons.assignment_ind_rounded,
      },
      {
        'title': '4. Al-Mu\'allafati Qulubuhum (Reconciling Hearts)',
        'desc':
            'New Muslims or those whose hearts are to be inclined towards Islam.',
        'icon': Icons.favorite_border_rounded,
      },
      {
        'title': '5. Fi al-Riqab (Freeing Captives)',
        'desc':
            'Freeing individuals from slavery, captivity, or human trafficking.',
        'icon': Icons.key_rounded,
      },
      {
        'title': '6. Al-Gharimin (Debtors in Distress)',
        'desc':
            'Those burdened with overwhelming lawful debt they cannot repay.',
        'icon': Icons.account_balance_wallet_rounded,
      },
      {
        'title': '7. Fi Sabilillah (In the Cause of Allah)',
        'desc':
            'Striving in Allah\'s cause, promoting Islamic education, dawah, and protecting faith.',
        'icon': Icons.mosque_rounded,
      },
      {
        'title': '8. Ibn al-Sabil (Stranded Traveler)',
        'desc':
            'Travelers stranded without sufficient funds to return home safely.',
        'icon': Icons.explore_rounded,
      },
    ];

    return ListView(
      padding: const EdgeInsets.all(12),
      physics: const BouncingScrollPhysics(),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF3FAF2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF2A531D).withValues(alpha: 0.2),
            ),
          ),
          child: Text(
            '"Zakat expenditures are only for the poor and for the needy and for those employed to collect [zakat] and for bringing hearts together..." (Surah At-Tawbah 9:60)',
            style: GoogleFonts.lexend(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: const Color(0xFF2A531D),
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 10),

        ...recipients.map(
          (r) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF23322B)
                    : const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.white12 : const Color(0xFFE5E7EB),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A531D).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      r['icon'] as IconData,
                      color: const Color(0xFF2A531D),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r['title'] as String,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2A531D),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          r['desc'] as String,
                          style: GoogleFonts.lexend(
                            fontSize: 12,
                            color: isDark
                                ? Colors.white70
                                : const Color(0xFF4B5563),
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
        ),
      ],
    );
  }

  Widget _buildBenefitCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required String arabic,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF23322B) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1F2937),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              arabic,
              textDirection: TextDirection.rtl,
              style: AppTypography.arabicBody(
                fontSize: 18,
                color: const Color(0xFF2A531D),
              ),
            ),
          ),
          const SizedBox(height: 6),
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
    );
  }

  Widget _buildComparisonRow({
    required String feature,
    required String sadaqah,
    required String zakat,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF23322B) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            feature,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFFD97724),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sadaqah (Sadqa)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF16A34A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sadaqah,
                      style: GoogleFonts.lexend(
                        fontSize: 11.5,
                        color: isDark
                            ? Colors.white70
                            : const Color(0xFF374151),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Zakat',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      zakat,
                      style: GoogleFonts.lexend(
                        fontSize: 11.5,
                        color: isDark
                            ? Colors.white70
                            : const Color(0xFF374151),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
