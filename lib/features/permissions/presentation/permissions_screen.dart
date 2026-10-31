import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../widgets/app_header_bar.dart';
import '../../quiet_hours/services/quiet_hours_service.dart';
import '../../quiet_hours/services/quiet_hours_permission_service.dart';
import '../../../core/services/native_alarm_service.dart';
import '../../reminder/services/reminder_permission_service.dart';
import 'widgets/reminder_permissions_required_modal.dart';
import 'widgets/quiet_hours_permissions_required_modal.dart';

class PermissionsScreen extends StatefulWidget {
  final String? from;

  const PermissionsScreen({super.key, this.from});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen>
    with WidgetsBindingObserver {
  Map<String, PermissionStatus> _permissionStatuses = {};
  bool _isLoading = true;
  bool _vibrationEnabled = true;
  bool _hasPromptedReminderModal = false;
  bool _hasPromptedQuietHoursModal = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkAllPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAllPermissions();
    }
  }

  Future<void> _checkAllPermissions() async {
    final notification = await Permission.notification.status;
    final location = await Permission.locationWhenInUse.status;
    final alarm = await Permission.scheduleExactAlarm.status;
    final dndGranted = await QuietHoursService().isDndPermissionGranted();
    final dnd = dndGranted ? PermissionStatus.granted : PermissionStatus.denied;
    final battery = await Permission.ignoreBatteryOptimizations.status;
    final fsiGranted = await NativeAlarmService.instance
        .canUseFullScreenIntent();
    final fsi = fsiGranted ? PermissionStatus.granted : PermissionStatus.denied;
    final overlay = await Permission.systemAlertWindow.status;

    final reminderMissing =
        await ReminderPermissionService.getMissingPermissions();
    final quietHoursMissing =
        await QuietHoursPermissionService.getMissingPermissions();

    if (mounted) {
      setState(() {
        _permissionStatuses = {
          'notification': notification,
          'location': location,
          'alarm': alarm,
          'dnd': dnd,
          'battery': battery,
          'fullScreenIntent': fsi,
          'systemAlertWindow': overlay,
        };
        _isLoading = false;
      });

      final hasReminderCritical = reminderMissing.any((p) => p.isCritical);
      if (widget.from == 'reminder' &&
          !_hasPromptedReminderModal &&
          hasReminderCritical) {
        _hasPromptedReminderModal = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ReminderPermissionsRequiredModal.show(
              context,
              missingPermissions: reminderMissing
                  .where((p) => p.isCritical)
                  .toList(),
            );
          }
        });
      }

      final hasQuietHoursCritical = quietHoursMissing.any((p) => p.isCritical);
      if (widget.from == 'quiet_hours' &&
          !_hasPromptedQuietHoursModal &&
          hasQuietHoursCritical) {
        _hasPromptedQuietHoursModal = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            QuietHoursPermissionsRequiredModal.show(
              context,
              missingPermissions: quietHoursMissing
                  .where((p) => p.isCritical)
                  .toList(),
            );
          }
        });
      }
    }
  }

  Future<void> _requestPermission(Permission permission, String key) async {
    if (key == 'dnd') {
      await QuietHoursService().openDndPermissionSettings();
      final isGranted = await QuietHoursService().isDndPermissionGranted();
      if (mounted) {
        setState(() {
          _permissionStatuses[key] = isGranted
              ? PermissionStatus.granted
              : PermissionStatus.denied;
        });
      }
      return;
    }

    if (key == 'fullScreenIntent') {
      await NativeAlarmService.instance.openFullScreenIntentSettings();
      final isGranted = await NativeAlarmService.instance
          .canUseFullScreenIntent();
      if (mounted) {
        setState(() {
          _permissionStatuses[key] = isGranted
              ? PermissionStatus.granted
              : PermissionStatus.denied;
        });
      }
      return;
    }

    final currentStatus = _permissionStatuses[key];

    if (currentStatus?.isGranted == true) {
      openAppSettings();
      return;
    }

    final status = await permission.request();

    if (mounted) {
      setState(() {
        _permissionStatuses[key] = status;
      });
    }

    if (!status.isGranted) {
      openAppSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryGreen = Color(0xFF2A531D);
    final bgColor = isDark ? const Color(0xFF0F0F12) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF18181B) : Colors.white;
    final cardBorder = isDark
        ? const Color(0xFF27272A)
        : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subTextColor = isDark ? Colors.white70 : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: const AppHeaderBar(
        title: 'APP PERMISSIONS',
        showDrawerButton: false,
        showBackButton: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryGreen))
          : ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 36, top: 4),
              children: [
                // 1. Notifications & Alerts Section
                const SectionHeader(
                  title: 'Notifications & Alerts',
                  subtitle:
                      'Required for Adhan prayer calls, Adhkar, and alarms screen',
                ),
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
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
                  child: Column(
                    children: [
                      _buildPermissionItem(
                        title: 'Notification Access',
                        subtitle:
                            'Alerts for Adhan prayer times, morning & evening Adhkar, and scheduled reminders.',
                        icon: Icons.notifications_active_rounded,
                        iconColor: const Color(0xFF2563EB),
                        status: _permissionStatuses['notification'],
                        onTap: () => _requestPermission(
                          Permission.notification,
                          'notification',
                        ),
                        textColor: textColor,
                        subTextColor: subTextColor,
                      ),
                      Divider(height: 1, color: cardBorder),
                      _buildPermissionItem(
                        title: 'Alarm & Schedule Access',
                        subtitle:
                            'Triggers exact prayer alarms and reminders on time without OS power-saving delays.',
                        icon: Icons.alarm_rounded,
                        iconColor: const Color(0xFFD97724),
                        status: _permissionStatuses['alarm'],
                        onTap: () => _requestPermission(
                          Permission.scheduleExactAlarm,
                          'alarm',
                        ),
                        textColor: textColor,
                        subTextColor: subTextColor,
                      ),
                      Divider(height: 1, color: cardBorder),
                      _buildPermissionItem(
                        title: 'Full-Screen Access',
                        subtitle:
                            'Displays the full-screen alarm screen over your lock screen when an alert sounds.',
                        icon: Icons.fullscreen_rounded,
                        iconColor: const Color(0xFFE11D48),
                        status: _permissionStatuses['fullScreenIntent'],
                        onTap: () => _requestPermission(
                          Permission.notification,
                          'fullScreenIntent',
                        ),
                        textColor: textColor,
                        subTextColor: subTextColor,
                      ),
                      Divider(height: 1, color: cardBorder),
                      _buildPermissionItem(
                        title: 'Appear on Top',
                        subtitle:
                            'Allows the alarm to immediately pop up full-screen over active apps even when unlocked.',
                        icon: Icons.layers_outlined,
                        iconColor: const Color(0xFFF59E0B),
                        status: _permissionStatuses['systemAlertWindow'],
                        onTap: () => _requestPermission(
                          Permission.systemAlertWindow,
                          'systemAlertWindow',
                        ),
                        textColor: textColor,
                        subTextColor: subTextColor,
                      ),
                      Divider(height: 1, color: cardBorder),
                      _buildPermissionItem(
                        title: 'Do Not Disturb (DND)',
                        subtitle:
                            'Allows important prayer Adhan alarms to sound even when your phone is in Silent mode.',
                        icon: Icons.do_not_disturb_on_rounded,
                        iconColor: const Color(0xFF9333EA),
                        status: _permissionStatuses['dnd'],
                        onTap: () => _requestPermission(
                          Permission.accessNotificationPolicy,
                          'dnd',
                        ),
                        textColor: textColor,
                        subTextColor: subTextColor,
                      ),
                    ],
                  ),
                ),

                const _SectionDivider(),

                // 2. Location & GPS Section
                const SectionHeader(
                  title: 'Location & GPS',
                  subtitle:
                      'Coordinates used for precise local prayer calculations and Qibla compass',
                ),
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
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
                  child: _buildPermissionItem(
                    title: 'Location Access',
                    subtitle:
                        'Calculates accurate local prayer times, sunrise/sunset, and Qibla direction for your city.',
                    icon: Icons.location_on_rounded,
                    iconColor: const Color(0xFF16A34A),
                    status: _permissionStatuses['location'],
                    onTap: () => _requestPermission(
                      Permission.locationWhenInUse,
                      'location',
                    ),
                    textColor: textColor,
                    subTextColor: subTextColor,
                  ),
                ),

                const _SectionDivider(),

                // 3. System & Battery Section
                const SectionHeader(
                  title: 'System & Battery',
                  subtitle:
                      'Optimizations to prevent Android from killing background prayer services',
                ),
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
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
                  child: Column(
                    children: [
                      _buildPermissionItem(
                        title: 'Battery Optimization Exemption',
                        subtitle:
                            'Prevents Android OS from stopping background prayer timers and scheduled Adhkar alarms.',
                        icon: Icons.battery_saver_rounded,
                        iconColor: const Color(0xFF0D9488),
                        status: _permissionStatuses['battery'],
                        onTap: () => _requestPermission(
                          Permission.ignoreBatteryOptimizations,
                          'battery',
                        ),
                        textColor: textColor,
                        subTextColor: subTextColor,
                      ),
                      Divider(height: 1, color: cardBorder),
                      _buildToggleItem(
                        title: 'Vibration & Haptics',
                        subtitle:
                            'Tactile vibration feedback for Adhkar counter taps and silent reminders.',
                        icon: Icons.vibration_rounded,
                        iconColor: const Color(0xFFE11D48),
                        isEnabled: _vibrationEnabled,
                        onChanged: (val) {
                          setState(() => _vibrationEnabled = val);
                        },
                        textColor: textColor,
                        subTextColor: subTextColor,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildPermissionItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required PermissionStatus? status,
    required VoidCallback onTap,
    required Color textColor,
    required Color subTextColor,
  }) {
    final isGranted = status?.isGranted ?? false;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Icon, Title (max 2 lines), and right-side minimized toggle switch
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7.5),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                      height: 1.25,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Transform.scale(
                  scale: 0.78,
                  child: Switch(
                    value: isGranted,
                    onChanged: (_) => onTap(),
                    activeTrackColor: isDark
                        ? const Color(0xFF166534)
                        : const Color(0xFF2A531D),
                    activeThumbColor: isDark
                        ? const Color(0xFF18A74C)
                        : Colors.white,
                    inactiveThumbColor: isDark
                        ? const Color(0xFF94A3B8)
                        : Colors.grey.shade400,
                    inactiveTrackColor: isDark
                        ? const Color(0xFF27272A)
                        : const Color(0xFFE2E8F0),
                    trackOutlineColor: WidgetStateProperty.resolveWith(
                      (states) => states.contains(WidgetState.selected)
                          ? Colors.transparent
                          : (isDark
                                ? const Color(0xFF3F3F46)
                                : const Color(0xFFCBD5E1)),
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Row 2: Total description from end to end (max 2 lines)
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.lexend(
                fontSize: 12,
                color: subTextColor,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool isEnabled,
    required ValueChanged<bool> onChanged,
    required Color textColor,
    required Color subTextColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () => onChanged(!isEnabled),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Icon, Title (max 2 lines), and minimized toggle button
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7.5),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                      height: 1.25,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Transform.scale(
                  scale: 0.78,
                  child: Switch(
                    value: isEnabled,
                    onChanged: onChanged,
                    activeTrackColor: isDark
                        ? const Color(0xFF166534)
                        : const Color(0xFF2A531D),
                    activeThumbColor: isDark
                        ? const Color(0xFF18A74C)
                        : Colors.white,
                    inactiveThumbColor: isDark
                        ? const Color(0xFF94A3B8)
                        : Colors.grey.shade400,
                    inactiveTrackColor: isDark
                        ? const Color(0xFF27272A)
                        : const Color(0xFFE2E8F0),
                    trackOutlineColor: WidgetStateProperty.resolveWith(
                      (states) => states.contains(WidgetState.selected)
                          ? Colors.transparent
                          : (isDark
                                ? const Color(0xFF3F3F46)
                                : const Color(0xFFCBD5E1)),
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Row 2: Description end to end (max 2 lines)
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.lexend(
                fontSize: 12,
                color: subTextColor,
                height: 1.35,
              ),
            ),
          ],
        ),
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
      margin: const EdgeInsets.symmetric(vertical: 10),
      color: isDark ? const Color(0xFF27272A) : const Color(0xFFF1F5F9),
    );
  }
}
