import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_islamic_icons/flutter_islamic_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/widgets/floating_download_bar.dart';
import '../../../widgets/app_header_bar.dart';
import '../data/juz_model.dart';
import '../repositories/quran_repository.dart';

class QuranScreen extends ConsumerStatefulWidget {
  const QuranScreen({super.key});

  @override
  ConsumerState<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends ConsumerState<QuranScreen> {
  final QuranRepository _repository = QuranRepository();
  final TextEditingController _searchController = TextEditingController();
  int _selectedTab = 0; // 0: Surahs, 1: Juz (Paras)
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final arabicFont = ref.watch(arabicFontProvider);
    final allSurahs = _repository.getSurahs();
    final storage = ref.watch(storageServiceProvider);

    final lastSurahNum = storage.getLastReadSurah() ?? 1;
    final lastJuzNum = storage.getLastReadJuz() ?? 1;
    final lastSurah = allSurahs.firstWhere(
      (s) => s.number == lastSurahNum,
      orElse: () => allSurahs.first,
    );
    final lastJuz = juzList.firstWhere(
      (j) => j.number == lastJuzNum,
      orElse: () => juzList.first,
    );

    final query = _searchController.text.trim().toLowerCase();
    final filteredSurahs = allSurahs.where((s) {
      return query.isEmpty ||
          s.nameEnglish.toLowerCase().contains(query) ||
          s.nameTranslation.toLowerCase().contains(query) ||
          s.number.toString().contains(query);
    }).toList();

    final filteredJuz = juzList.where((j) {
      return query.isEmpty ||
          j.nameEnglish.toLowerCase().contains(query) ||
          j.nameArabic.contains(query) ||
          j.number.toString().contains(query);
    }).toList();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Stack(
        children: [
          Scaffold(
            backgroundColor:
                isDark ? const Color(0xFF17241E) : const Color(0xFFFFFFFF),
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: AppHeaderBar(
            title: 'QURAN',
            showBackButton: false,
            showDrawerButton: true,
            systemOverlayStyle:
                isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
            backgroundColor: isDark ? const Color(0xFF192520) : Colors.white,
            iconColor: isDark ? Colors.white : const Color(0xFF2A531D),
            titleWidget: Text(
              'HOLY QURAN',
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF2A531D),
                fontWeight: FontWeight.bold,
                fontSize: 18,
                letterSpacing: 0.8,
              ),
            ),
            actions: [
              IconButton(
                onPressed: () {
                  setState(() {
                    _isSearching = !_isSearching;
                    if (!_isSearching) _searchController.clear();
                  });
                },
                icon: Icon(
                  _isSearching ? Icons.close_rounded : Icons.search_rounded,
                  color: isDark ? Colors.white : const Color(0xFF2A531D),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
        body: Column(
          children: [
            if (_isSearching)
              Container(
                color: isDark ? const Color(0xFF192520) : Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF1F2937),
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: _selectedTab == 0
                        ? 'Search Surah by name or number...'
                        : 'Search Juz by name or number...',
                    hintStyle: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: Color(0xFF2A531D),
                    ),
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF23322B)
                        : const Color(0xFFF9F9F9),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                children: [
                  // Last Read Hero Banner Card
                  GestureDetector(
                    onTap: () {
                      if (_selectedTab == 1) {
                        context.push(
                          '/quran/surah?juz=${lastJuz.number}&name=${Uri.encodeComponent("Juz ${lastJuz.number} - ${lastJuz.nameEnglish}")}',
                        );
                      } else {
                        context.push(
                          '/quran/surah?num=${lastSurah.number}&name=${Uri.encodeComponent(lastSurah.nameEnglish)}',
                        );
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 18,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [
                                  const Color(0xFF1E3A15),
                                  const Color(0xFF0F1A0E),
                                ]
                              : [
                                  const Color(0xFF669f1d),
                                  const Color(0xFF2A531D),
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF2A531D,
                            ).withValues(alpha: 0.2),
                            blurRadius: 14,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top Category Badge
                          Row(
                            children: [
                              const Icon(
                                FlutterIslamicIcons.quran2,
                                size: 16,
                                color: Color(0xFFd1ffbe),
                              ),
                              const SizedBox(width: 7),
                              Text( 
                                _selectedTab == 1
                                    ? 'LAST READ JUZ'
                                    : 'LAST READ SURAH',
                                style: const TextStyle(
                                  color: Color(0xFFd1ffbe),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11.5,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // English Name & Arabic Name Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _selectedTab == 1
                                          ? lastJuz.nameEnglish
                                          : lastSurah.nameEnglish,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 22,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                    Text(
                                      _selectedTab == 1
                                          ? 'Para (Juz) : ${lastJuz.number}'
                                          : lastSurah.nameTranslation,
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.9,
                                        ),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ), 
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Padding(
                                padding: const EdgeInsets.only(right: 6),
                                  child: Text(
                                    _selectedTab == 1
                                        ? lastJuz.nameArabic
                                        : lastSurah.nameArabic,
                                    textDirection: TextDirection.rtl,
                                    style: AppTypography.arabicHeader(
                                      arabicFont: arabicFont,
                                      fontSize: 28,
                                      color: const Color(0xFFd1ffbe), 
                                      height: 1.2,
                                    ),
                                  ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Below Arabic & English Name: Surah Number, Meccan/Medinan, Total Ayahs
                          if (_selectedTab == 1)
                            Text(
                              lastJuz.surahRange,
                              style: const TextStyle(
                                color: Color(0xFFd1ffbe),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            )
                          else
                            Text(
                              'Surah ${lastSurah.number}  •  ${lastSurah.revelationType}  •  ${lastSurah.verseCount} Total Ayahs',
                              style: const TextStyle(
                                color: Color(0xFFd1ffbe),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Al Quran Title & Segmented Pill Navigation Tabs Header Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Al Quran',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF1F2937),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF23322B)
                              : const Color(0xFFF4FAF3),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark
                                ? Colors.white10
                                : const Color(0xFFE2E8F0),
                          ),
                        ), 
                        child: Row(
                          children: [
                            _buildPillTab(
                              'Surahs (${allSurahs.length})',
                              0,
                              isDark,
                            ),
                            _buildPillTab(
                              'Juz (30)',
                              1,
                              isDark,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Tab 0: Surahs List
                  if (_selectedTab == 0)
                    ...filteredSurahs.map((surah) {
                      final isLastRead = surah.number == lastSurahNum;

                      return Column(
                        children: [
                          InkWell(
                            onTap: () => context.push(
                              '/quran/surah?num=${surah.number}&name=${Uri.encodeComponent(surah.nameEnglish)}',
                            ),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 4,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: isLastRead
                                          ? const Color(0xFF2A531D)
                                          : (isDark
                                                ? const Color(0xFF23322B)
                                                : const Color(0xFFF4FAF3)),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isLastRead
                                            ? const Color(0xFF2A531D)
                                            : (isDark
                                                  ? Colors.white12
                                                  : const Color(
                                                      0xFF2A531D,
                                                    ).withValues(alpha: 0.15)),
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        surah.number < 10
                                            ? '0${surah.number}'
                                            : '${surah.number}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: isLastRead
                                              ? Colors.white
                                              : (isDark
                                                    ? Colors.white70
                                                    : const Color(0xFF2A531D)),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          surah.nameEnglish,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: isDark
                                                ? Colors.white
                                                : const Color(0xFF1F2937),
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Row(
                                          children: [
                                            Icon(
                                              surah.revelationType
                                                          .toLowerCase() ==
                                                      'meccan'
                                                  ? FlutterIslamicIcons.solidKaaba
                                                  : FlutterIslamicIcons.solidMosque,
                                              size: 13,
                                              color: const Color(0xFF2A531D),
                                            ),
                                            const SizedBox(width: 5),
                                            Text(
                                              '${surah.revelationType}  •  ${surah.verseCount} Ayahs',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                   Text(
                                     surah.nameArabic,
                                     textDirection: TextDirection.rtl,
                                     style: AppTypography.arabicHeader(
                                       arabicFont: arabicFont,
                                       fontSize: 20,
                                       color: const Color(0xFF2A531D),
                                       height: 1.7,
                                     ),
                                   ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    }),

                  // Tab 1: Juz (30 Paras) List
                  if (_selectedTab == 1)
                    ...filteredJuz.map((juz) {
                      final isLastRead = juz.number == lastJuzNum;

                      return Column(
                        children: [
                          InkWell(
                            onTap: () => context.push(
                              '/quran/surah?juz=${juz.number}&name=${Uri.encodeComponent("Juz ${juz.number} - ${juz.nameEnglish}")}',
                            ),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 4,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: isLastRead
                                          ? const Color(0xFF2A531D)
                                          : (isDark
                                                ? const Color(0xFF23322B)
                                                : const Color(0xFFF4FAF3)),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isLastRead
                                            ? const Color(0xFF2A531D)
                                            : (isDark
                                                  ? Colors.white12
                                                  : const Color(
                                                      0xFF2A531D,
                                                    ).withValues(alpha: 0.15)),
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        juz.number < 10
                                            ? '0${juz.number}'
                                            : '${juz.number}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: isLastRead
                                              ? Colors.white
                                              : (isDark
                                                    ? Colors.white70
                                                    : const Color(0xFF2A531D)),
                                        ),
                                      ),
                                    ),
                                  ),
                                  
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          juz.nameEnglish,
                                          style: TextStyle(
                                            fontSize: 15.5,
                                            fontWeight: FontWeight.bold,
                                            color: isDark
                                                ? Colors.white
                                                : const Color(0xFF1F2937),
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          juz.surahRange,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                   Text(
                                     juz.nameArabic,
                                     textDirection: TextDirection.rtl,
                                     style: AppTypography.arabicHeader(
                                       arabicFont: arabicFont,
                                       fontSize: 22,
                                       color: const Color(0xFF2A531D),
                                     ),
                                   ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    }),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
      const Align(
        alignment: Alignment.bottomCenter,
        child: FloatingDownloadBar(),
      ),
    ],
  ),
);
  }

  Widget _buildPillTab(String label, int index, bool isDark) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2A531D) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white70 : const Color(0xFF4B5563)),
          ),
        ),
      ),
    );
  }
}
