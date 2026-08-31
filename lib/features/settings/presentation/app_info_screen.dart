import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../widgets/app_header_bar.dart';

import 'package:package_info_plus/package_info_plus.dart';

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

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF17241E)
            : const Color(0xFFF9F9F9),
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: AppHeaderBar(
            title: 'APP INFO',
            showBackButton: true,
            systemOverlayStyle: isDark
                ? SystemUiOverlayStyle.light
                : SystemUiOverlayStyle.dark,
            backgroundColor: isDark ? const Color(0xFF192520) : Colors.white,
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
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/logo.png',
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
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
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          versionText,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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
            const Text(
              'OUR MISSION & PROMISE',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: Color(0xFF2A531D),
                decoration: TextDecoration.underline,
                decorationColor: Color(0xFF2A531D),
              ),
            ),
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF192520) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                ),
              ),
              child: SelectableText(
                'Adhkar App is built to serve the global Muslim Ummah. We are 100% committed to being completely AD-FREE forever, with zero data tracking, so that your worship remains peaceful and undisturbed.',
                style: GoogleFonts.lexend(
                  fontSize: 13.5,
                  color: isDark ? Colors.white70 : const Color(0xFF334155),
                  height: 1.5,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Data Sources & API Credits
            const Text(
              'DATA SOURCES & API CREDITS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: Color(0xFFD97724),
                decoration: TextDecoration.underline,
                decorationColor: Color(0xFFD97724),
              ),
            ),
            const SizedBox(height: 10),

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
                    accentColor: const Color(0xFFD97724),
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
                    accentColor: const Color(0xFF2563EB),
                    isDark: isDark,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Features Grid
            const Text(
              'KEY FEATURES AT A GLANCE',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: Color(0xFF15803D),
                decoration: TextDecoration.underline,
                decorationColor: Color(0xFF15803D),
              ),
            ),
            const SizedBox(height: 10),

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
                  _buildFeatureRow(
                    '🕌 Prayer Times & Adhan',
                    'Accurate location-based prayer schedules with countdown',
                  ),
                  const Divider(height: 16),
                  _buildFeatureRow(
                    '📖 Noble Qur\'an',
                    'Full Surah reader with translation, transliteration & audio',
                  ),
                  const Divider(height: 16),
                  _buildFeatureRow(
                    '📿 Digital Tasbeeh',
                    'Customizable dhikr counter with vibration feedback',
                  ),
                  const Divider(height: 16),
                  _buildFeatureRow(
                    '🤲 Daily Adhkar & Duas',
                    'Authentic Sunnah supplications for morning and evening',
                  ),
                  const Divider(height: 16),
                  _buildFeatureRow(
                    '📅 Islamic Calendar',
                    'Dual Hijri & Gregorian monthly calendar with date converter',
                  ),
                  const Divider(height: 16),
                  _buildFeatureRow(
                    '💰 Sadaqah & Zakat',
                    'Zakat nisab calculator and charity transaction logger',
                  ),
                  const Divider(height: 16),
                  _buildFeatureRow(
                    '🧭 High-Precision Qibla',
                    'Real-time sensor-based direction finder towards Kaaba',
                  ),
                  const Divider(height: 16),
                  _buildFeatureRow(
                    '🔬 Scientific Islam',
                    'Quranic scientific miracles backed by academic research',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Privacy & Credits
            const Text(
              'PRIVACY & CREDITS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: Color(0xFF2563EB),
                decoration: TextDecoration.underline,
                decorationColor: Color(0xFF2563EB),
              ),
            ),
            const SizedBox(height: 10),

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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        color: Color(0xFF16A34A),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        '100% Offline & Private',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF16A34A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  SelectableText(
                    'All your data (adhkar counts, zakat records, book notes) remains strictly stored on your local device. We never collect or transmit your personal information.',
                    style: GoogleFonts.lexend(
                      fontSize: 12.5,
                      color: isDark ? Colors.white60 : const Color(0xFF4B5563),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Divider(
                    height: 1,
                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
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
                      color: isDark ? Colors.white60 : const Color(0xFF4B5563),
                      height: 1.4,
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
        color: isDark ? const Color(0xFF23322B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withValues(alpha: 0.3), width: 1),
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
              color: isDark ? Colors.white60 : const Color(0xFF4B5563),
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

  Widget _buildFeatureRow(String title, String desc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2A531D),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          desc,
          style: GoogleFonts.lexend(
            fontSize: 12,
            color: const Color(0xFF4B5563),
          ),
        ),
      ],
    );
  }
}
