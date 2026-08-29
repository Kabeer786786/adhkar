import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/showcase_service.dart';
import '../../../core/typography/arabic_font.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/providers/user_profile_provider.dart';
import '../../../shared/widgets/location_selection_modal.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../core/calendar/models/calendar_type.dart';
import '../../../core/calendar/providers/calendar_providers.dart';
import '../../../widgets/app_header_bar.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

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

    final bgColor = isDark ? const Color(0xFF121B16) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF1E2D24) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF2B3F33) : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subTextColor = isDark ? Colors.white60 : const Color(0xFF64748B);
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
          // 1. Profile Account Section Card
          Consumer(
            builder: (context, ref, child) {
              final userProfile = ref.watch(userProfileProvider);
              final hasName = userProfile.name.isNotEmpty;
              final displayName = hasName ? userProfile.name : 'Guest User';

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: cardBorder, width: 1),
                  boxShadow: [
                    if (!isDark)
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    onTap: () => context.push('/profile'),
                    borderRadius: BorderRadius.circular(18),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? primaryGreen.withValues(alpha: 0.3)
                                  : const Color(0xFFF1F5F9),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.person_outline_rounded,
                              size: 24,
                              color: primaryGreen,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName,
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: textColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  userProfile.isEmailVerified
                                      ? 'Verified Profile'
                                      : (hasName
                                            ? 'Unverified Profile'
                                            : 'Tap to setup profile'),
                                  style: GoogleFonts.lexend(
                                    fontSize: 11.5,
                                    color: userProfile.isEmailVerified
                                        ? primaryGreen
                                        : const Color(0xFFD97724),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: Color(0xFF94A3B8),
                            size: 22,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // 6px light/dark gray divider box
          const _SectionDivider(),

          // 2. Location & GPS Section
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
                            ? const Color(0xFF23352B)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.location_on_outlined,
                        color: primaryGreen,
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
                      foregroundColor: primaryGreen,
                      side: BorderSide(
                        color: primaryGreen.withValues(alpha: 0.5),
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
                                ? const Color(0xFF23352B)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.calculate_outlined,
                            color: primaryGreen,
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

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Divider(height: 1, color: Color(0xFFE2E8F0)),
                ),

                // Asr Juristic Method Toggle
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF23352B)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.balance_outlined,
                        color: primaryGreen,
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
                                ? const Color(0xFF23352B)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.text_fields_rounded,
                            color: primaryGreen,
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
                                      ? primaryGreen.withValues(alpha: 0.25)
                                      : const Color(0xFFE8F5E9))
                                  : (isDark
                                      ? const Color(0xFF23352B)
                                      : const Color(0xFFF8FAFC)),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? primaryGreen
                                    : (isDark
                                        ? Colors.white10
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
                                          ? primaryGreen
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
                                                    color: primaryGreen
                                                        .withValues(alpha: 0.15),
                                                    borderRadius:
                                                        BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    'DEFAULT',
                                                    style: GoogleFonts.lexend(
                                                      fontSize: 9.5,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: primaryGreen,
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
                                        ? Colors.black.withValues(alpha: 0.25)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isDark
                                          ? Colors.white10
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
                                ? const Color(0xFF23352B)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.calendar_month_outlined,
                            color: primaryGreen,
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
                        ? const Color(0xFF23352B)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.explore_outlined,
                    color: primaryGreen,
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
                      ShowcaseService.startHomeShowcase(context);
                    });
                  },
                  // icon: const Icon(Icons.play_arrow_rounded, size: 16),
                  label: const Text('Start'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: GoogleFonts.lexend(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
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
                        color: Colors.white,
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
                              color: primaryGreen,
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
      height: 8,
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2822) : const Color(0xFFE2E8F0),
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
              ? const Color(0xFF2A531D)
              : (isDark ? const Color(0xFF23352B) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2A531D)
                : (isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
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
                    ? Colors.white
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
                    ? Colors.white.withValues(alpha: 0.85)
                    : (isDark ? Colors.white54 : const Color(0xFF64748B)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
