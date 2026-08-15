import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../widgets/app_header_bar.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen>
    with WidgetsBindingObserver {
  Map<String, PermissionStatus> _permissionStatuses = {};
  bool _isLoading = true;
  bool _vibrationEnabled = true;

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
    final dnd = await Permission.accessNotificationPolicy.status;
    final battery = await Permission.ignoreBatteryOptimizations.status;

    if (mounted) {
      setState(() {
        _permissionStatuses = {
          'notification': notification,
          'location': location,
          'alarm': alarm,
          'dnd': dnd,
          'battery': battery,
        };
        _isLoading = false;
      });
    }
  }

  Future<void> _requestPermission(Permission permission, String key) async {
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

  int get _grantedCount {
    return _permissionStatuses.values.where((status) => status.isGranted).length;
  }

  int get _totalCount => 5;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    const primaryGreen = Color(0xFF2A531D);
    final cardBg = isDark ? const Color(0xFF192520) : Colors.white;
    final borderColor = isDark ? Colors.white10 : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF1F2937);
    final subTextColor = isDark ? Colors.white60 : const Color(0xFF64748B);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF17241E) : const Color(0xFFF8FAFC),
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: AppHeaderBar(
            title: 'APP PERMISSIONS',
            showBackButton: true,
            systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
            backgroundColor: cardBg,
            iconColor: isDark ? Colors.white : primaryGreen,
            titleWidget: Text(
              'APP PERMISSIONS',
              style: GoogleFonts.outfit(
                color: isDark ? Colors.white : primaryGreen,
                fontWeight: FontWeight.bold,
                fontSize: 18,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: primaryGreen))
            : ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                physics: const BouncingScrollPhysics(),
                children: [
                  // Premium Overview Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF1E3A15), const Color(0xFF0F1A0E)]
                            : [const Color(0xFF2A531D), const Color(0xFF16A34A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: primaryGreen.withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.shield_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Permissions Health',
                                      style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '$_grantedCount of $_totalCount Active',
                                      style: GoogleFonts.lexend(
                                        color: Colors.white.withValues(alpha: 0.85),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: _grantedCount / _totalCount,
                            backgroundColor: Colors.white.withValues(alpha: 0.2),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                            minHeight: 8,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Section Header: Required App Permissions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'APP PERMISSIONS',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                          color: primaryGreen,
                        ),
                      ),
                      InkWell(
                        onTap: openAppSettings,
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.settings_rounded,
                                size: 14,
                                color: Color(0xFF2563EB),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'System Settings',
                                style: GoogleFonts.lexend(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF2563EB),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Container for App Permissions
                  Container(
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black26
                              : const Color(0xFF2A531D).withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // 1. Notification Permission
                        _buildPermissionItem(
                          title: 'Notification Access',
                          subtitle:
                              'Required for Adhan prayer alerts, morning & evening Adhkar, and fasting reminders.',
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
                        Divider(height: 1, indent: 58, color: borderColor),

                        // 2. Location Permission
                        _buildPermissionItem(
                          title: 'Location Access',
                          subtitle:
                              'Required to calculate accurate local prayer times, city detection, and Qibla direction.',
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
                        Divider(height: 1, indent: 58, color: borderColor),

                        // 3. Alarm Permission
                        _buildPermissionItem(
                          title: 'Alarm & Schedule Access',
                          subtitle:
                              'Required to trigger exact prayer alarms and scheduled reminders without OS delays.',
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
                        Divider(height: 1, indent: 58, color: borderColor),

                        // 4. Do Not Disturb Access
                        _buildPermissionItem(
                          title: 'Do Not Disturb (DND) Access',
                          subtitle:
                              'Allows Adhan prayer alerts to sound even when your phone is in Silent/DND mode.',
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
                        Divider(height: 1, indent: 58, color: borderColor),

                        // 5. Vibration & Haptics
                        _buildToggleItem(
                          title: 'Vibration & Haptics',
                          subtitle:
                              'Tactile vibration feedback for Adhkar counter taps and silent alerts.',
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

                  const SizedBox(height: 24),

                  // Section Header: System Optimizations
                  Text(
                    'SYSTEM OPTIMIZATIONS',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 10),

                  Container(
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black26
                              : const Color(0xFF2A531D).withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: _buildPermissionItem(
                      title: 'Battery Optimization Exemption',
                      subtitle:
                          'Prevents Android OS from stopping background prayer time timers and scheduled Adhkar alarms.',
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
                  ),

                  const SizedBox(height: 28),
                ],
              ),
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

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          height: 1.35,
          color: textColor,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Text(
          subtitle,
          style: GoogleFonts.lexend(
            fontSize: 12,
            color: subTextColor,
            height: 1.35,
          ),
        ),
      ),
      trailing: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: isGranted ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
            shape: BoxShape.circle,
            border: Border.all(
              color: isGranted ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5),
              width: 1.5,
            ),
          ),
          child: Icon(
            isGranted ? Icons.check_rounded : Icons.close_rounded,
            size: 18,
            color: isGranted ? const Color(0xFF15803D) : const Color(0xFFDC2626),
          ),
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
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      onTap: () => onChanged(!isEnabled),
      leading: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          height: 1.35,
          color: textColor,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Text(
          subtitle,
          style: GoogleFonts.lexend(
            fontSize: 12,
            color: subTextColor,
            height: 1.35,
          ),
        ),
      ),
      trailing: InkWell(
        onTap: () => onChanged(!isEnabled),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: isEnabled ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
            shape: BoxShape.circle,
            border: Border.all(
              color: isEnabled ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5),
              width: 1.5,
            ),
          ),
          child: Icon(
            isEnabled ? Icons.check_rounded : Icons.close_rounded,
            size: 18,
            color: isEnabled ? const Color(0xFF15803D) : const Color(0xFFDC2626),
          ),
        ),
      ),
    );
  }
}
