import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../widgets/app_header_bar.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _enableAll = true;
  bool _adhanAlerts = true;
  bool _morningEveningAdhkar = true;
  bool _fridayKahfReminder = true;
  bool _fastingReminders = true;
  bool _tahajjudReminder = false;

  final List<Map<String, String>> _notificationLogs = [
    {
      'title': 'Fajr Prayer Notification',
      'body': 'Fajr prayer time has begun. May Allah accept your worship.',
      'time': 'Today, 05:12 AM',
      'type': 'prayer',
    },
    {
      'title': 'Morning Adhkar Reminder',
      'body': 'Start your day with morning remembrance & protection.',
      'time': 'Today, 06:00 AM',
      'type': 'adhkar',
    },
    {
      'title': 'Sunnah Fasting Alert',
      'body': 'Tomorrow is Thursday. Prepare for Sunnah fasting.',
      'time': 'Yesterday, 08:30 PM',
      'type': 'fasting',
    },
    {
      'title': 'Friday Surah Al-Kahf',
      'body': 'Don\'t forget to recite Surah Al-Kahf today for light between Fridays.',
      'time': 'Friday, 07:00 AM',
      'type': 'kahf',
    },
  ];

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
            title: 'NOTIFICATIONS',
            showBackButton: true,
            systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
            backgroundColor: isDark ? const Color(0xFF192520) : Colors.white,
            iconColor: isDark ? Colors.white : const Color(0xFF2A531D),
            titleWidget: Text(
              'NOTIFICATIONS',
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
            // Master Switch Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF192520) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? Colors.white10 : const Color(0xFF2A531D).withValues(alpha: 0.15),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black26 : const Color(0xFF2A531D).withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeThumbColor: const Color(0xFF2A531D),
                value: _enableAll,
                onChanged: (val) {
                  setState(() {
                    _enableAll = val;
                    _adhanAlerts = val;
                    _morningEveningAdhkar = val;
                    _fridayKahfReminder = val;
                    _fastingReminders = val;
                    _tahajjudReminder = val;
                  });
                },
                title: Text(
                  'Allow All Notifications',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1F2937),
                  ),
                ),
                subtitle: Text(
                  'Receive timely reminders for prayers, adhkar, and fasting',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: isDark ? Colors.white60 : Colors.grey.shade600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Notification Categories Header
            const Text(
              'NOTIFICATION PREFERENCES',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: Color(0xFF2A531D),
              ),
            ),
            const SizedBox(height: 10),

            // Notification Toggles List
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF192520) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                children: [
                  _buildToggleTile(
                    title: 'Adhan & Prayer Time Alerts',
                    subtitle: 'Notifications at Fajr, Dhuhr, Asr, Maghrib, and Isha',
                    icon: Icons.access_time_filled_rounded,
                    iconColor: const Color(0xFF16A34A),
                    value: _adhanAlerts,
                    onChanged: (v) => setState(() => _adhanAlerts = v),
                    isDark: isDark,
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildToggleTile(
                    title: 'Morning & Evening Adhkar',
                    subtitle: 'Daily reminders at 06:00 AM and 05:30 PM',
                    icon: Icons.wb_sunny_rounded,
                    iconColor: const Color(0xFFD97724),
                    value: _morningEveningAdhkar,
                    onChanged: (v) => setState(() => _morningEveningAdhkar = v),
                    isDark: isDark,
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildToggleTile(
                    title: 'Friday Surah Al-Kahf',
                    subtitle: 'Weekly reminder every Friday morning',
                    icon: Icons.menu_book_rounded,
                    iconColor: const Color(0xFF2563EB),
                    value: _fridayKahfReminder,
                    onChanged: (v) => setState(() => _fridayKahfReminder = v),
                    isDark: isDark,
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildToggleTile(
                    title: 'Sunnah Fasting Reminders',
                    subtitle: 'Mondays, Thursdays & White Days (13th, 14th, 15th)',
                    icon: Icons.nightlight_round,
                    iconColor: const Color(0xFF9333EA),
                    value: _fastingReminders,
                    onChanged: (v) => setState(() => _fastingReminders = v),
                    isDark: isDark,
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildToggleTile(
                    title: 'Tahajjud & Pre-Fajr Alert',
                    subtitle: 'Gentle notification 30 minutes before Fajr',
                    icon: Icons.bedtime_rounded,
                    iconColor: const Color(0xFF0D9488),
                    value: _tahajjudReminder,
                    onChanged: (v) => setState(() => _tahajjudReminder = v),
                    isDark: isDark,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Recent Notification History Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'RECENT NOTIFICATION LOGS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: Color(0xFF2A531D),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _notificationLogs.clear();
                    });
                  },
                  child: const Text(
                    'Clear All',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Logs List
            if (_notificationLogs.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF192520) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text(
                    'No notification logs available',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ),
              )
            else
              ..._notificationLogs.map(
                (log) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF192520) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
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
                        child: const Icon(
                          Icons.notifications_active_rounded,
                          color: Color(0xFF2A531D),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    log['title']!,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : const Color(0xFF1F2937),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  log['time']!,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              log['body']!,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: isDark ? Colors.white60 : const Color(0xFF4B5563),
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

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isDark,
  }) {
    return SwitchListTile(
      activeThumbColor: const Color(0xFF2A531D),
      value: value,
      onChanged: onChanged,
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12), 
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : const Color(0xFF1F2937),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: isDark ? Colors.white60 : Colors.grey.shade600,
        ),
      ),
    );
  }
}
