import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/showcase_service.dart';
import '../../../core/typography/arabic_font.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/widgets/location_selection_modal.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../core/calendar/models/calendar_type.dart';
import '../../../core/calendar/providers/calendar_providers.dart';
import '../../../widgets/app_header_bar.dart';
import '../../reminder/presentation/widgets/alarm_interaction_settings_modal.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  bool isAdaptiveDarkMode([DateTime? time]) {
    final now = time ?? DateTime.now();
    return now.hour >= 19 || now.hour < 7;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storage = ref.watch(storageServiceProvider);
    final currentJuristic = ref.watch(asrJuristicProvider);
    final locationAsync = ref.watch(currentLocationProvider);
    final location = locationAsync.value ?? LocationService.defaultLocation;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final packageInfoAsync = ref.watch(appPackageInfoProvider);

    final versionStr = packageInfoAsync.when(
      data: (info) => 'Version ${info.version}',
      loading: () => 'Loading version...',
      error: (_, _) => 'Version 1.3.0',
    );

    final selectedThemeMode = ref.watch(themeModeProvider);
    final isAdaptiveDark =
        ref.watch(adaptiveDarkScheduleProvider).value ?? isAdaptiveDarkMode();

    final bgColor = isDark ? const Color(0xFF0F0F12) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF18181B) : Colors.white;
    final cardBorder = isDark
        ? const Color(0xFF27272A)
        : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subTextColor = isDark ? Colors.white70 : const Color(0xFF64748B);
    const primaryGreen = Color(0xFF2A531D);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: const AppHeaderBar(
        title: 'SETTINGS',
        showDrawerButton: false,
        showBackButton: true,
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 36, top: 8),
        children: [
          // 0. Theme & Appearance Section
          const SectionHeader(
            title: 'Theme & Appearance',
            subtitle: 'Choose Light, Dark, or Automatic Adaptive Schedule',
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration( 
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: cardBorder, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    _ThemeOptionTile(
                      title: 'Light',
                      subtitle: 'Mode',
                      icon: Icons.light_mode_rounded,
                      isSelected: selectedThemeMode == 'light',
                      onTap: () {
                        HapticFeedback.selectionClick();
                        ref.read(themeModeProvider.notifier).setThemeMode('light');
                        ref.read(storageServiceProvider).setQuranReadingDarkMode(false);
                        ref.read(readingThemeProvider.notifier).setTheme(0);
                      },
                    ),
                    const SizedBox(width: 8),
                    _ThemeOptionTile(
                      title: 'Dark',
                      subtitle: 'Mode',
                      icon: Icons.dark_mode_rounded,
                      isSelected: selectedThemeMode == 'dark',
                      onTap: () {
                        HapticFeedback.selectionClick();
                        ref.read(themeModeProvider.notifier).setThemeMode('dark');
                        ref.read(storageServiceProvider).setQuranReadingDarkMode(true);
                        ref.read(readingThemeProvider.notifier).setTheme(2);
                      },
                    ),
                    const SizedBox(width: 8),
                    _ThemeOptionTile(
                      title: 'Adaptive',
                      subtitle: '7 PM – 7 AM',
                      icon: Icons.schedule_rounded,
                      isSelected: selectedThemeMode == 'adaptive',
                      onTap: () {
                        HapticFeedback.selectionClick();
                        ref.read(themeModeProvider.notifier).setThemeMode('adaptive');
                        final isDarkNow = isAdaptiveDarkMode();
                        ref.read(storageServiceProvider).setQuranReadingDarkMode(isDarkNow);
                        ref.read(readingThemeProvider.notifier).setTheme(isDarkNow ? 2 : 0);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Live Status Banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F0F12) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: selectedThemeMode == 'adaptive'
                              ? (isDark ? const Color(0xFF143820) : const Color(0xFFE7F6E3))
                              : (selectedThemeMode == 'dark'
                                  ? const Color(0xFF143820)
                                  : const Color(0xFFFEF3C7)),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          selectedThemeMode == 'adaptive'
                              ? Icons.auto_mode_rounded
                              : (selectedThemeMode == 'dark'
                                  ? Icons.nightlight_round
                                  : Icons.wb_sunny_rounded),
                          size: 16,
                          color: selectedThemeMode == 'adaptive'
                              ? (isDark ? const Color(0xFF18A74C) : const Color(0xFF2A531D))
                              : (selectedThemeMode == 'dark'
                                  ? const Color(0xFF86EFAC)
                                  : const Color(0xFFD97706)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          selectedThemeMode == 'adaptive'
                              ? (isAdaptiveDark
                                  ? 'Adaptive: Currently Night (Dark). Switches to Light at 7:00 AM.'
                                  : 'Adaptive: Currently Day (Light). Switches to Dark at 7:00 PM.')
                              : (selectedThemeMode == 'dark'
                                  ? 'Dark Mode: 24-hour full-time deep obsidian dark theme.'
                                  : 'Light Mode: 24-hour full-time light theme.'),
                          style: GoogleFonts.lexend( 
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white70 : const Color(0xFF475569),
                            height: 1.35,
                          ),
                        ),
                      ),
                      if (selectedThemeMode == 'adaptive') ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF143820) : const Color(0xFFE7F6E3),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF18A74C).withValues(alpha: 0.4)
                                  : const Color(0xFF2A531D).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isAdaptiveDark
                                    ? Icons.nightlight_round
                                    : Icons.wb_sunny_rounded,
                                size: 12,
                                color: isDark
                                    ? const Color(0xFF86EFAC)
                                    : const Color(0xFF2A531D),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isAdaptiveDark ? 'Dark' : 'Light',
                                style: GoogleFonts.lexend(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? const Color(0xFF86EFAC)
                                      : const Color(0xFF2A531D),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const _SectionDivider(),

          // 1. Location & GPS Section
          const SectionHeader(
            title: 'Location & GPS',
            subtitle: 'Coordinates used for precise prayer calculations',
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: cardBorder, width: 1),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF27272A)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.location_on_outlined,
                        color: isDark ? const Color(0xFF86EFAC) : primaryGreen,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${location.city}, ${location.country}',
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${location.latitude.toStringAsFixed(4)}°, ${location.longitude.toStringAsFixed(4)}°',
                            style: GoogleFonts.lexend(
                              fontSize: 11.5,
                              color: subTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => LocationSelectionModal.show(context),
                    icon: const Icon(
                      Icons.edit_location_alt_outlined,
                      size: 16,
                    ),
                    label: const Text('Change City or Detect GPS'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark
                          ? const Color(0xFF86EFAC)
                          : primaryGreen,
                      side: BorderSide(
                        color: isDark
                            ? const Color(0xFF86EFAC).withValues(alpha: 0.5)
                            : primaryGreen.withValues(alpha: 0.5),
                        width: 1,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: GoogleFonts.lexend(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 6px light/dark gray divider box
          const _SectionDivider(),

          // 3. Calculation Parameters & Juristic School
          const SectionHeader(
            title: 'Calculation Parameters',
            subtitle:
                'Astronomical conventions for solar angle & Asr juristic rule',
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: cardBorder, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF27272A)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.calculate_outlined,
                            color: isDark
                                ? const Color(0xFF86EFAC)
                                : primaryGreen,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Calculation Method',
                                style: GoogleFonts.outfit(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'University of Islamic Sciences, Karachi (Default)',
                      style: GoogleFonts.lexend(
                        fontSize: 12,
                        color: subTextColor,
                      ),
                    ),
                  ],
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Divider(
                    height: 1,
                    color: isDark
                        ? const Color(0xFF27272A)
                        : const Color(0xFFE2E8F0),
                  ),
                ),

                // Asr Juristic Method Toggle
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF27272A)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.balance_outlined,
                        color: isDark ? const Color(0xFF86EFAC) : primaryGreen,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Asr Juristic Rule',
                        style: GoogleFonts.outfit(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  currentJuristic == 'Hanafi'
                      ? 'Hanafi (Shadow ratio 2:1)'
                      : 'Standard (Shafi, Maliki, Hanbali - Shadow ratio 1:1)',
                  style: GoogleFonts.lexend(
                    fontSize: 11.5,
                    color: subTextColor,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _OptionSelectTile(
                        title: 'Hanafi',
                        subtitle: 'Double Shadow',
                        isSelected: currentJuristic == 'Hanafi',
                        onTap: () async {
                          await storage.setAsrJuristic('Hanafi');
                          ref.read(asrJuristicProvider.notifier).state =
                              'Hanafi';
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _OptionSelectTile(
                        title: 'Standard',
                        subtitle: 'Shafi / Maliki',
                        isSelected: currentJuristic == 'Standard',
                        onTap: () async {
                          await storage.setAsrJuristic('Standard');
                          ref.read(asrJuristicProvider.notifier).state =
                              'Standard';
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 6px light/dark gray divider box
          const _SectionDivider(),

          // Arabic Font Selection Section
          const SectionHeader(
            title: 'Arabic Font',
            subtitle: 'Global font for Quran, Adhkar, Dua, and Arabic text',
          ),
          Consumer(
            builder: (context, ref, _) {
              final activeFont = ref.watch(arabicFontProvider);
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: cardBorder, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF27272A)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.text_fields_rounded,
                            color: isDark
                                ? const Color(0xFF86EFAC)
                                : primaryGreen,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Arabic Script Font',
                                style: GoogleFonts.outfit(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Active: ${activeFont.displayName}',
                                style: GoogleFonts.lexend(
                                  fontSize: 12,
                                  color: subTextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ...ArabicFont.values.map((font) {
                      final isSelected = activeFont == font;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: InkWell(
                          onTap: () {
                            ref.read(arabicFontProvider.notifier).setFont(font);
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? (isDark
                                        ? const Color(
                                            0xFF18A74C,
                                          ).withValues(alpha: 0.25)
                                        : const Color(0xFFE8F5E9))
                                  : (isDark
                                        ? const Color(0xFF27272A)
                                        : const Color(0xFFF8FAFC)),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? (isDark
                                          ? const Color(0xFF18A74C)
                                          : primaryGreen)
                                    : (isDark
                                          ? const Color(0xFF3F3F46)
                                          : const Color(0xFFE2E8F0)),
                                width: isSelected ? 1.5 : 1.0,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      isSelected
                                          ? Icons.radio_button_checked_rounded
                                          : Icons.radio_button_off_rounded,
                                      color: isSelected
                                          ? (isDark
                                                ? const Color(0xFF18A74C)
                                                : primaryGreen)
                                          : (isDark
                                                ? Colors.white38
                                                : const Color(0xFF94A3B8)),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                font.displayName,
                                                style: GoogleFonts.outfit(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w600,
                                                  color: isSelected
                                                      ? (isDark
                                                            ? Colors.white
                                                            : primaryGreen)
                                                      : textColor,
                                                ),
                                              ),
                                              if (font.isDefault) ...[
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 2,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        (isDark
                                                                ? const Color(
                                                                    0xFF18A74C,
                                                                  )
                                                                : primaryGreen)
                                                            .withValues(
                                                              alpha: 0.15,
                                                            ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          6,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    'DEFAULT',
                                                    style: GoogleFonts.lexend(
                                                      fontSize: 9.5,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: isDark
                                                          ? const Color(
                                                              0xFF86EFAC,
                                                            )
                                                          : primaryGreen,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            font.description,
                                            style: GoogleFonts.lexend(
                                              fontSize: 11.5,
                                              color: subTextColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF0F0F12)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isDark
                                          ? const Color(0xFF27272A)
                                          : const Color(0xFFEEF2F6),
                                    ),
                                  ),
                                  child: Text(
                                    font.samplePreviewText,
                                    textDirection: TextDirection.rtl,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: font.fontFamily,
                                      fontSize: 18,
                                      height: 1.8,
                                      fontWeight: FontWeight.normal,
                                      color: textColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
          ),

          // 6px light/dark gray divider box
          const _SectionDivider(),

          // 4. Hijri Calendar Region Mode
          const SectionHeader(
            title: 'Hijri Calendar Convention',
            subtitle: 'Regional moon-sighting rules and target region',
          ),
          Builder(
            builder: (context) {
              final calPref = ref.watch(calendarPreferenceProvider);
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: cardBorder, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF27272A)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.calendar_month_outlined,
                            color: isDark
                                ? const Color(0xFF86EFAC)
                                : primaryGreen,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Calendar Region Mode',
                            style: GoogleFonts.outfit(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      calPref.calendarType == CalendarType.regional
                          ? 'Regional Mode (Subcontinent -1 day offset based on local moon sighting)'
                          : 'Global Standard Mode (Standard astronomical calendar without regional offset)',
                      style: GoogleFonts.lexend(
                        fontSize: 12,
                        color: subTextColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _OptionSelectTile(
                            title: 'Regional',
                            subtitle: 'IN / PK / BD',
                            isSelected:
                                calPref.calendarType == CalendarType.regional,
                            onTap: () {
                              ref
                                  .read(calendarPreferenceProvider.notifier)
                                  .setCalendarType(CalendarType.regional);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _OptionSelectTile(
                            title: 'Global',
                            subtitle: 'Standard',
                            isSelected:
                                calPref.calendarType == CalendarType.global,
                            onTap: () {
                              ref
                                  .read(calendarPreferenceProvider.notifier)
                                  .setCalendarType(CalendarType.global);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),

          // 6px light/dark gray divider box
          const _SectionDivider(),

          // Alarm Interaction Section
          const SectionHeader(
            title: 'Alarm Interaction',
            subtitle: 'Configure volume buttons and screen-off alarm actions',
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: cardBorder, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF27272A)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.touch_app_outlined,
                        color: isDark ? const Color(0xFF86EFAC) : primaryGreen,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hardware Button Actions',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Volume buttons & screen-off dismissal',
                            style: GoogleFonts.lexend(
                              fontSize: 11.5,
                              color: subTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        AlarmInteractionSettingsModal.show(context),
                    icon: const Icon(Icons.tune_rounded, size: 16),
                    label: const Text('Configure Alarm Interaction'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark
                          ? const Color(0xFF86EFAC)
                          : primaryGreen,
                      side: BorderSide(
                        color: isDark
                            ? const Color(0xFF86EFAC).withValues(alpha: 0.5)
                            : primaryGreen.withValues(alpha: 0.5),
                        width: 1,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: GoogleFonts.lexend(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 6px light/dark gray divider box
          const _SectionDivider(),

          // 5. Guided Feature Tour
          const SectionHeader(
            title: 'App Guided Tour',
            subtitle: 'Re-visit the guided tour of application features',
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: cardBorder, width: 1),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF27272A)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.explore_outlined,
                    color: isDark ? const Color(0xFF86EFAC) : primaryGreen,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Interactive Feature Tour',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Take a quick tour of key app features',
                        style: GoogleFonts.lexend(
                          fontSize: 12,
                          color: subTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    context.go('/');
                    Future.delayed(const Duration(milliseconds: 300), () {
                      if (context.mounted) {
                        ShowcaseService.startHomeShowcase(context);
                      }
                    });
                  },
                  label: const Text('Start'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark
                        ? const Color(0xFF18A74C)
                        : primaryGreen,
                    foregroundColor: isDark
                        ? const Color(0xFF0F0F12)
                        : Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: GoogleFonts.lexend(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 6px light/dark gray divider box
          const _SectionDivider(),

          // 6. About App Footer Card with Adhkar Logo & Dynamic Native Version
          const SectionHeader(
            title: 'About Adhkar',
            subtitle: 'Version and application info',
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: cardBorder, width: 1),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark ? const Color(0xFF27272A) : Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/logo.png',
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                          cacheWidth: 132,
                          cacheHeight: 132,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Adhkar App',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? const Color(0xFF86EFAC)
                                  : primaryGreen,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$versionStr • Material 3 Design',
                            style: GoogleFonts.lexend(
                              fontSize: 11.5,
                              color: subTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Designed for daily consistency in Dhikr, Quran, and Salah.',
                  style: GoogleFonts.lexend(
                    fontSize: 11.5,
                    color: subTextColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 6,
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0),
      ),
    );
  }
}

class _OptionSelectTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _OptionSelectTile({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF18A74C) : const Color(0xFF2A531D))
              : (isDark ? const Color(0xFF27272A) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? (isDark ? const Color(0xFF18A74C) : const Color(0xFF2A531D))
                : (isDark ? const Color(0xFF3F3F46) : const Color(0xFFE2E8F0)),
            width: 1.2,
          ),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? (isDark ? const Color(0xFF0F0F12) : Colors.white)
                    : (isDark ? Colors.white : const Color(0xFF1E293B)),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.lexend(
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? (isDark
                          ? const Color(0xFF0F0F12).withValues(alpha: 0.85)
                          : Colors.white.withValues(alpha: 0.85))
                    : (isDark ? Colors.white54 : const Color(0xFF64748B)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeOptionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOptionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final selectedBg = isDark
        ? const Color(0xFF143820)
        : const Color(0xFFE7F6E3);
    final unselectedBg = isDark
        ? const Color(0xFF18181B)
        : const Color(0xFFF8FAFC);
    final selectedBorder = isDark
        ? const Color(0xFF18A74C)
        : const Color(0xFF2A531D);
    final unselectedBorder = isDark
        ? const Color(0xFF27272A)
        : const Color(0xFFE2E8F0);

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
            decoration: BoxDecoration(
              color: isSelected ? selectedBg : unselectedBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? selectedBorder : unselectedBorder,
                width: isSelected ? 1.8 : 1.0,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: isSelected
                      ? (isDark ? const Color(0xFF86EFAC) : const Color(0xFF2A531D))
                      : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: GoogleFonts.lexend(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected
                        ? (isDark ? Colors.white : const Color(0xFF2A531D))
                        : (isDark ? Colors.white70 : const Color(0xFF334155)),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.lexend(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: isSelected
                        ? (isDark ? const Color(0xFF86EFAC) : const Color(0xFF2A531D))
                        : (isDark ? Colors.white38 : const Color(0xFF94A3B8)),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

