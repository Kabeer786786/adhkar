import 'package:flutter/material.dart';
import '../../data/surah_model.dart';

class QuranReadingSettingsModal {
  static void show({
    required BuildContext context,
    required bool isDark,
    required List<AyahModel> ayahs,
    required int selectedMode,
    required double arabicFontSize,
    required bool isReadingDarkMode,
    required String translationLanguage,
    required bool showTransliteration,
    required bool isDownloaded,
    required ValueChanged<int> onModeChanged,
    required ValueChanged<double> onFontSizeChanged,
    required ValueChanged<bool> onReadingDarkModeChanged,
    required ValueChanged<String> onTranslationLanguageChanged,
    required ValueChanged<bool> onTransliterationChanged,
    required VoidCallback onTriggerDownload,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF192520) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        int currentMode = selectedMode;
        double currentFontSize = arabicFontSize;
        String currentLang = translationLanguage; 
        bool currentTransliteration = showTransliteration;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.88,
              minChildSize: 0.45,
              maxChildSize: 0.92,
              expand: false,
              builder: (context, scrollController) {
                return ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(22, 16, 22, 30),
                  children: [
                    // Grabber
                    Center(
                      child: Container(
                        width: 38,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.tune_rounded,
                              color: Color(0xFF2A531D),
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Reading Preferences',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF1F2937),
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // SECTION 1: Reading & Display Modes
                    Text(
                      'READING DISPLAY MODE',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: isDark ? Colors.white60 : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildModeTile(
                      title: 'Verse-by-Verse List Mode',
                      subtitle:
                          'Full Arabic verse, transliteration, translations & audio play',
                      icon: Icons.translate_rounded,
                      modeIndex: 0,
                      selectedMode: currentMode,
                      isDark: isDark,
                      onTap: () {
                        setModalState(() => currentMode = 0);
                        onModeChanged(0);
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildModeTile(
                      title: 'Page-Wise Mushaf Mode',
                      subtitle:
                          'Authentic RTL page-by-page Mushaf view with smooth page traversal',
                      icon: Icons.auto_stories_rounded,
                      modeIndex: 1,
                      selectedMode: currentMode,
                      isDark: isDark,
                      onTap: () {
                        setModalState(() => currentMode = 1);
                        onModeChanged(1);
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildModeTile(
                      title: 'Continuous Flowing Mushaf Mode',
                      subtitle:
                          'Flowing continuous Arabic Mushaf text with Sajda, Rub & Hizb markers',
                      icon: Icons.menu_book_rounded,
                      modeIndex: 2,
                      selectedMode: currentMode,
                      isDark: isDark,
                      onTap: () {
                        setModalState(() => currentMode = 2);
                        onModeChanged(2);
                      },
                    ),

                    const SizedBox(height: 22),

                    // SECTION 2: Typography & Appearance Preferences
                    Text(
                      'APPEARANCE & TYPOGRAPHY',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: isDark ? Colors.white60 : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Font Size Slider Card
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF23322B)
                            : const Color(0xFFF4FAF3),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? Colors.white10
                              : const Color(0xFF2A531D).withValues(alpha: 0.12),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.format_size_rounded,
                                    size: 20,
                                    color: Color(0xFF2A531D),
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    'Arabic Font Size',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14.5,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '${currentFontSize.toInt()} pt',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2A531D),
                                ),
                              ),
                            ],
                          ),
                          SliderTheme(
                            data: SliderThemeData(
                              trackHeight: 4,
                              activeTrackColor: const Color(0xFF2A531D),
                              inactiveTrackColor: Colors.grey.shade300,
                              thumbColor: const Color(0xFF2A531D),
                            ),
                            child: Slider(
                              value: currentFontSize,
                              min: 18.0,
                              max: 42.0,
                              divisions: 12,
                              onChanged: (val) {
                                setModalState(() => currentFontSize = val);
                                onFontSizeChanged(val);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),

                    // SECTION 3: Translations & Transliteration
                    Text(
                      'TRANSLATION & TRANSLITERATION',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: isDark ? Colors.white60 : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 10),

                    _buildLangTile(
                      keyName: 'both',
                      title: 'Both English & Urdu',
                      subtitle: 'Side-by-side bilingual translation',
                      badge: 'EN + UR',
                      selectedLang: currentLang,
                      isDark: isDark,
                      onTap: () {
                        setModalState(() => currentLang = 'both');
                        onTranslationLanguageChanged('both');
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildLangTile(
                      keyName: 'en',
                      title: 'English Translation Only',
                      subtitle: 'Sahih International',
                      badge: 'EN',
                      selectedLang: currentLang,
                      isDark: isDark,
                      onTap: () {
                        setModalState(() => currentLang = 'en');
                        onTranslationLanguageChanged('en');
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildLangTile(
                      keyName: 'ur',
                      title: 'Urdu Translation Only',
                      subtitle: 'Fateh Muhammad Jalandhry',
                      badge: 'UR',
                      selectedLang: currentLang,
                      isDark: isDark,
                      onTap: () {
                        setModalState(() => currentLang = 'ur');
                        onTranslationLanguageChanged('ur');
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildLangTile(
                      keyName: 'none',
                      title: 'Arabic Only (Hide Translation)',
                      subtitle: 'Pure Arabic recitation mode',
                      badge: 'AR',
                      selectedLang: currentLang,
                      isDark: isDark,
                      onTap: () {
                        setModalState(() => currentLang = 'none');
                        onTranslationLanguageChanged('none');
                      },
                    ),

                    const SizedBox(height: 14),

                    // Transliteration Toggle Switch
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF23322B)
                            : const Color(0xFFF4FAF3),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? Colors.white10
                              : const Color(0xFF2A531D).withValues(alpha: 0.12),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.spellcheck_rounded,
                            size: 20,
                            color: Color(0xFF2A531D),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'English Transliteration',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14.5,
                              ),
                            ),
                          ),
                          Switch(
                            value: currentTransliteration,
                            activeThumbColor: const Color(0xFF2A531D),
                            onChanged: (val) {
                              setModalState(() => currentTransliteration = val);
                              onTransliterationChanged(val);
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),

                    // SECTION 4: Offline Audio Download
                    Text(
                      'OFFLINE AUDIO MEDIA',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: isDark ? Colors.white60 : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 10),

                    InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        onTriggerDownload();
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF23322B)
                              : const Color(0xFFF4FAF3),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? Colors.white10
                                : const Color(0xFF2A531D).withValues(alpha: 0.12),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isDownloaded
                                  ? Icons.cloud_done_rounded
                                  : Icons.download_for_offline_rounded,
                              size: 22,
                              color: isDownloaded
                                  ? const Color(0xFF22C55E)
                                  : const Color(0xFF2A531D),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isDownloaded
                                        ? 'Audio Downloaded'
                                        : 'Download Surah Audio',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14.5,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF1F2937),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isDownloaded
                                        ? 'Available for offline listening'
                                        : 'Listen without internet connection',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? Colors.white60
                                          : Colors.grey.shade600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isDownloaded
                                    ? const Color(0xFF166534)
                                    : const Color(0xFF2A531D),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                isDownloaded ? 'Downloaded' : 'Download',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  static Widget _buildModeTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required int modeIndex,
    required int selectedMode,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final bool isSelected = selectedMode == modeIndex;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF23322B) : const Color(0xFFF4FAF3))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF2A531D) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF2A531D)
                    : (isDark ? Colors.white12 : Colors.grey.shade200),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : const Color(0xFF2A531D)),
                size: 20,
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
                      fontWeight: FontWeight.bold,
                      fontSize: 14.5,
                      color: isDark ? Colors.white : const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark ? Colors.white60 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF2A531D),
                size: 22,
              ),
          ],
        ),
      ),
    );
  }

  static Widget _buildLangTile({
    required String keyName,
    required String title,
    required String subtitle,
    required String badge,
    required String selectedLang,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final bool isSelected = selectedLang == keyName;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF243B2A) : const Color(0xFFE8F5E9))
              : (isDark ? const Color(0xFF23322B) : const Color(0xFFF9FAF9)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2A531D)
                : (isDark ? Colors.white10 : Colors.grey.shade300),
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF2A531D)
                    : (isDark ? Colors.white12 : Colors.grey.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                badge,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.white70 : const Color(0xFF374151)),
                ),
              ),
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
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark ? Colors.white60 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF2A531D),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
