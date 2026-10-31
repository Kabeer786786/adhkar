import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One-time startup permissions bottom sheet to guide users to enable essential features.
class StartupPermissionsModal extends StatelessWidget {
  const StartupPermissionsModal({super.key});

  static const String prefKey = 'has_prompted_startup_permissions';

  /// Checks if the startup permissions prompt should be displayed, and if so, shows it.
  static Future<void> checkAndShow(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final hasPrompted = prefs.getBool(prefKey) ?? false;
    if (hasPrompted) return;

    // If notifications and location are already granted, mark prompted and skip
    final notifGranted = await Permission.notification.isGranted;
    final locGranted = await Permission.locationWhenInUse.isGranted;
    if (notifGranted && locGranted) {
      await prefs.setBool(prefKey, true);
      return;
    }

    if (!context.mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const StartupPermissionsModal(),
    );
  }

  Future<void> _handleEnableAll(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefKey, true);

    if (context.mounted) {
      Navigator.of(context).pop();
    }

    // Sequentially request core permissions
    try {
      await Permission.notification.request();
      await Permission.locationWhenInUse.request();
      await Permission.scheduleExactAlarm.request();
    } catch (_) {}
  }

  Future<void> _handleDismiss(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefKey, true);
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF18181B) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subTextColor = isDark ? Colors.white70 : const Color(0xFF64748B);
    const primaryGreen = Color(0xFF2A531D);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: cardBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top pull bar indicator
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF3F3F46) : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Round Adhkar App Logo with subtle gold ring
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.8),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1B4332).withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/logo.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.notifications_active_rounded,
                    size: 32,
                    color: primaryGreen,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Title
            Text(
              'Enable Essential Permissions',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 6),

            // Subtitle
            Text(
              'Enable notifications, prayer times, and alarms for the best spiritual experience.',
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.lexend(
                fontSize: 13,
                color: subTextColor,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),

            // Permission Items List
            _buildFeatureTile(
              icon: Icons.notifications_active_rounded,
              iconColor: const Color(0xFF2563EB),
              title: 'Notifications & Adhan',
              subtitle: 'Salah prayer calls, morning & evening Adhkar, and reminders.',
              isDark: isDark,
              textColor: textColor,
              subTextColor: subTextColor,
            ),
            const SizedBox(height: 10),
            _buildFeatureTile(
              icon: Icons.location_on_rounded,
              iconColor: const Color(0xFF16A34A),
              title: 'Location & Qibla Direction',
              subtitle: 'Calculates accurate prayer times for your city and Qibla compass.',
              isDark: isDark,
              textColor: textColor,
              subTextColor: subTextColor,
            ),
            const SizedBox(height: 10),
            _buildFeatureTile(
              icon: Icons.alarm_rounded,
              iconColor: const Color(0xFFD97724),
              title: 'Exact Alarms & Schedule',
              subtitle: 'Wakes screen and sounds alarms on time even when phone is locked.',
              isDark: isDark,
              textColor: textColor,
              subTextColor: subTextColor,
            ),

            const SizedBox(height: 24),

            // Primary Action Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => _handleEnableAll(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  foregroundColor: isDark ? const Color(0xFF0F0F12) : Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_outline_rounded, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Enable All Permissions',
                      style: GoogleFonts.lexend(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Dismiss Button
            TextButton(
              onPressed: () => _handleDismiss(context),
              style: TextButton.styleFrom(
                foregroundColor: subTextColor,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: Text(
                'Maybe Later',
                style: GoogleFonts.lexend(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isDark,
    required Color textColor,
    required Color subTextColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F0F12) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.lexend(
                    fontSize: 11.5,
                    color: subTextColor,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
