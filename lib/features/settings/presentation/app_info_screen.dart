import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../widgets/app_header_bar.dart';

class AppInfoScreen extends StatelessWidget {
  const AppInfoScreen({super.key});

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final primaryColor =
        isDark ? const Color(0xFF22C55E) : const Color(0xFF2A531D);
    final cardBg = isDark ? const Color(0xFF18181B) : Colors.white;
    final cardBorder =
        isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor:
            isDark ? const Color(0xFF0F0F12) : const Color(0xFFF8FAFC),
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: AppHeaderBar(
            title: 'APP INFO',
            showBackButton: true,
            systemOverlayStyle:
                isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
            backgroundColor: cardBg,
            iconColor: isDark ? Colors.white : const Color(0xFF2A531D),
            titleWidget: Text(
              'APP INFO',
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
            // App Branding Hero Card
            Container(
              padding: const EdgeInsets.all(24),
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
                      ? const Color(0xFF22C55E).withValues(alpha: 0.3)
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
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/logo.png',
                        width: 76,
                        height: 76,
                        fit: BoxFit.cover,
                        cacheWidth: 228,
                        cacheHeight: 228,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'ADHKAR',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Islamic Companion & Deen Utility',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FutureBuilder<PackageInfo>(
                    future: PackageInfo.fromPlatform(),
                    builder: (context, snapshot) {
                      final versionText = snapshot.hasData
                          ? 'Version ${snapshot.data!.version}'
                          : 'Version 1.3.0';
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF22C55E).withValues(alpha: 0.2)
                              : Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          versionText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? const Color(0xFF86EFAC)
                                : Colors.white,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Mission Statement
            Row(
              children: [
                Icon(
                  Icons.favorite_border_rounded,
                  size: 18,
                  color: primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'OUR MISSION & PROMISE',
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
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: cardBorder),
              ),
              child: SelectableText(
                'Adhkar App is built solely for the pleasure of Allah and to serve the global Muslim Ummah. We are 100% committed to being completely AD-FREE forever, with zero data tracking, so that your worship remains peaceful, authentic, and undisturbed.',
                style: GoogleFonts.lexend(
                  fontSize: 13.5,
                  color: isDark ? Colors.white70 : const Color(0xFF334155),
                  height: 1.5,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Data Sources & API Credits
            Row(
              children: [
                Icon(
                  Icons.cloud_sync_rounded,
                  size: 18,
                  color: isDark
                      ? const Color(0xFFFBBF24)
                      : const Color(0xFFD97724),
                ),
                const SizedBox(width: 8),
                Text(
                  'DATA SOURCES & API CREDITS',
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
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Adhkar App integrates verified region-specific Islamic calendar data and astronomical prayer calculation services from trusted data providers:',
                    style: GoogleFonts.lexend(
                      fontSize: 12.5,
                      color: isDark ? Colors.white70 : const Color(0xFF4B5563),
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ChandKiTarikh API Card
                  _buildApiSourceCard(
                    context: context,
                    title: 'ChandKiTarikh API',
                    badge: 'India, Pakistan & Bangladesh',
                    description:
                        'Provides regional moon-sighting based Hijri dates, monthly calendars, and Gregorian to Hijri date conversions for South Asia.',
                    url: 'https://chandkitarikh.today/',
                    icon: Icons.calendar_month_rounded,
                    accentColor: isDark
                        ? const Color(0xFFFBBF24)
                        : const Color(0xFFD97724),
                    isDark: isDark,
                  ),

                  const SizedBox(height: 14),

                  // Aladhan API Card
                  _buildApiSourceCard(
                    context: context,
                    title: 'Aladhan API',
                    badge: 'Global Prayer & Hijri Calendar',
                    description:
                        'Provides astronomical solar prayer times, global Hijri calendar schedules, and high-precision Qibla direction calculations worldwide.',
                    url: 'https://aladhan.com/',
                    icon: Icons.public_rounded,
                    accentColor: isDark
                        ? const Color(0xFF60A5FA)
                        : const Color(0xFF2563EB),
                    isDark: isDark,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Features Grid
            Row(
              children: [
                Icon(
                  Icons.grid_view_rounded,
                  size: 18,
                  color: primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'KEY FEATURES AT A GLANCE',
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
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: cardBorder),
              ),
              child: Column(
                children: [
                  _buildFeatureRow(
                    icon: Icons.access_time_filled_rounded,
                    title: 'Prayer Times & Adhan',
                    desc:
                        'Accurate location-based prayer schedules with countdown & notifications',
                    color: isDark
                        ? const Color(0xFF4ADE80)
                        : const Color(0xFF16A34A),
                    isDark: isDark,
                  ),
                  Divider(height: 18, color: cardBorder),
                  _buildFeatureRow(
                    icon: Icons.menu_book_rounded,
                    title: 'Noble Qur\'an',
                    desc:
                        'Full Surah reader with translation, transliteration & audio playback',
                    color: isDark
                        ? const Color(0xFF60A5FA)
                        : const Color(0xFF2563EB),
                    isDark: isDark,
                  ),
                  Divider(height: 18, color: cardBorder),
                  _buildFeatureRow(
                    icon: Icons.touch_app_rounded,
                    title: 'Digital Tasbeeh',
                    desc:
                        'Customizable dhikr counter with vibration feedback & reset goals',
                    color: isDark
                        ? const Color(0xFFFBBF24)
                        : const Color(0xFFD97724),
                    isDark: isDark,
                  ),
                  Divider(height: 18, color: cardBorder),
                  _buildFeatureRow(
                    icon: Icons.front_hand_rounded,
                    title: 'Daily Adhkar & Duas',
                    desc:
                        'Authentic Sunnah supplications for morning, evening, and all occasions',
                    color: isDark
                        ? const Color(0xFFC084FC)
                        : const Color(0xFF9333EA),
                    isDark: isDark,
                  ),
                  Divider(height: 18, color: cardBorder),
                  _buildFeatureRow(
                    icon: Icons.calendar_month_rounded,
                    title: 'Islamic Calendar',
                    desc:
                        'Dual Hijri & Gregorian monthly calendar with date converter',
                    color: isDark
                        ? const Color(0xFF2DD4BF)
                        : const Color(0xFF0D9488),
                    isDark: isDark,
                  ),
                  Divider(height: 18, color: cardBorder),
                  _buildFeatureRow(
                    icon: Icons.volunteer_activism_rounded,
                    title: 'Sadaqah & Zakat',
                    desc:
                        'Zakat nisab calculator and personal charity transaction logger',
                    color: isDark
                        ? const Color(0xFFFB7185)
                        : const Color(0xFFE11D48),
                    isDark: isDark,
                  ),
                  Divider(height: 18, color: cardBorder),
                  _buildFeatureRow(
                    icon: Icons.explore_rounded,
                    title: 'High-Precision Qibla',
                    desc:
                        'Real-time sensor-based direction finder towards the Holy Kaaba',
                    color: isDark
                        ? const Color(0xFF38BDF8)
                        : const Color(0xFF0284C7),
                    isDark: isDark,
                  ),
                  Divider(height: 18, color: cardBorder),
                  _buildFeatureRow(
                    icon: Icons.science_rounded,
                    title: 'Scientific Islam',
                    desc:
                        'Quranic scientific miracles backed by modern academic research',
                    color: isDark
                        ? const Color(0xFFA78BFA)
                        : const Color(0xFF7C3AED),
                    isDark: isDark,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Privacy & Credits
            Row(
              children: [
                Icon(
                  Icons.security_rounded,
                  size: 18,
                  color: isDark
                      ? const Color(0xFF60A5FA)
                      : const Color(0xFF2563EB),
                ),
                const SizedBox(width: 8),
                Text(
                  'PRIVACY & CREDITS',
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
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        color: isDark
                            ? const Color(0xFF4ADE80)
                            : const Color(0xFF16A34A),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '100% Offline & Private',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? const Color(0xFF4ADE80)
                              : const Color(0xFF16A34A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  SelectableText(
                    'All your data (adhkar counts, zakat records, book notes) remains strictly stored on your local device. We never collect, track, or transmit your personal information.',
                    style: GoogleFonts.lexend(
                      fontSize: 12.5,
                      color: isDark ? Colors.white70 : const Color(0xFF4B5563),
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Divider(
                    height: 1,
                    color: cardBorder,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Icon(
                        Icons.favorite_rounded,
                        color: Colors.redAccent,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Built for the Ummah',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF1F2937),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  SelectableText(
                    'Developed with love for the global Muslim Ummah. May Allah accept this humble effort as Sadaqah Jariyah for all contributors.',
                    style: GoogleFonts.lexend(
                      fontSize: 12.5,
                      color: isDark ? Colors.white70 : const Color(0xFF4B5563),
                      height: 1.45,
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

  Widget _buildApiSourceCard({
    required BuildContext context,
    required String title,
    required String badge,
    required String description,
    required String url,
    required IconData icon,
    required Color accentColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F0F12) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? const Color(0xFF27272A)
              : accentColor.withValues(alpha: 0.3),
          width: 1,
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
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accentColor, size: 20),
              ),
              const SizedBox(width: 10),
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
                    Text(
                      badge,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: accentColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: GoogleFonts.lexend(
              fontSize: 12,
              color: isDark ? Colors.white70 : const Color(0xFF4B5563),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: () => _launchUrl(url),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.open_in_new_rounded, size: 14, color: accentColor),
                  const SizedBox(width: 6),
                  Text(
                    url,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                      decoration: TextDecoration.underline,
                      decorationColor: accentColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow({
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
              const SizedBox(height: 2),
              Text(
                desc,
                style: GoogleFonts.lexend(
                  fontSize: 12,
                  color: isDark ? Colors.white70 : const Color(0xFF4B5563),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
