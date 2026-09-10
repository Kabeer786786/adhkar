import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../widgets/app_header_bar.dart';
import '../../../shared/widgets/app_floating_toast.dart';
import '../domain/quiet_hours_model.dart';
import '../services/quiet_hours_service.dart';
import 'providers/quiet_hours_provider.dart';
import 'widgets/quiet_hours_library_modal.dart';
import 'widgets/quiet_hours_modal.dart';

class QuietHoursScreen extends ConsumerStatefulWidget {
  const QuietHoursScreen({super.key});

  @override
  ConsumerState<QuietHoursScreen> createState() => _QuietHoursScreenState();
}

class _QuietHoursScreenState extends ConsumerState<QuietHoursScreen>
    with WidgetsBindingObserver {
  bool _hasDndPermission = true;
  bool _isBatteryOptIgnored = true;
  bool _canScheduleExactAlarms = true;
  bool _isAutoStartSupported = false;
  String _deviceManufacturer = '';
  Timer? _timer;
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = <String>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermission();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) {
        ref.read(quietHoursProvider.notifier).syncDndState();
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermission();
      ref.read(quietHoursProvider.notifier).syncDndState();
    }
  }

  Future<void> _checkPermission() async {
    final service = ref.read(quietHoursServiceProvider);
    if (!service.isSupported) {
      if (mounted) setState(() => _hasDndPermission = false);
      return;
    }
    final granted = await service.isDndPermissionGranted();
    final batteryIgnored = await service.isBatteryOptimizationIgnored();
    final canAlarms = await service.canScheduleExactAlarms();
    final autoStartSupported = await service.isAutoStartSupported();
    final manufacturer = await service.getDeviceManufacturer();
    if (mounted) {
      setState(() {
        _hasDndPermission = granted;
        _isBatteryOptIgnored = batteryIgnored;
        _canScheduleExactAlarms = canAlarms;
        _isAutoStartSupported = autoStartSupported;
        _deviceManufacturer = manufacturer;
      });
    }
  }

  String _formatTimeOfDay(TimeOfDay tod) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, tod.hour, tod.minute);
    return DateFormat('hh:mm a').format(dt);
  }

  String _calculateDurationStr(QuietHours model) {
    int startMinutes = model.startHour * 60 + model.startMinute;
    int endMinutes = model.endHour * 60 + model.endMinute;

    if (endMinutes < startMinutes) {
      endMinutes += 24 * 60; // Overnight
    }

    final diffMinutes = endMinutes - startMinutes;
    final hours = diffMinutes ~/ 60;
    final minutes = diffMinutes % 60;

    if (hours > 0 && minutes > 0) {
      return '$hours hr $minutes min';
    } else if (hours > 0) {
      return '$hours hr';
    } else {
      return '$minutes min';
    }
  }

  void _confirmDeleteSelected(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final count = _selectedIds.length;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E2D24) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Delete Timing${count > 1 ? 's' : ''}?',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          content: Text(
            'Are you sure you want to delete $count selected Quiet Hours timing${count > 1 ? 's' : ''}?',
            style: GoogleFonts.lexend(
              fontSize: 13,
              color: isDark ? Colors.white70 : const Color(0xFF64748B),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.lexend(
                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                ref
                    .read(quietHoursProvider.notifier)
                    .deleteMultipleSchedules(_selectedIds);
                setState(() {
                  _selectedIds.clear();
                  _isSelectionMode = false;
                });
                Navigator.pop(context);
                _showDeleteToast(
                  context,
                  '$count timing${count > 1 ? 's' : ''} deleted',
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Delete',
                style: GoogleFonts.lexend(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        );
      },
    );
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _showToast(
    BuildContext context,
    String message,
    bool isActivated,
    bool isDark,
  ) {
    final toastBg = isActivated
        ? const Color(0xFF2A531D)
        : (isDark ? const Color(0xFF1E2D24) : const Color(0xFF1E293B));
    final borderColor = isActivated
        ? const Color(0xFF4ADE80).withValues(alpha: 0.6)
        : const Color(0xFF2A531D).withValues(alpha: 0.4);

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        backgroundColor: Colors.transparent,
        duration: const Duration(milliseconds: 1400),
        margin: const EdgeInsets.only(bottom: 20, left: 100, right: 100),
        content: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: toastBg,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: borderColor, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.lexend(
                color: Colors.white,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteToast(BuildContext context, [String message = 'Removed']) {
    AppFloatingToast.showRemoved(context, message: message);
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    bool isDark,
    Color textColor,
    List<QuietHours> allSchedules,
    Color primaryGreen,
    bool isSupported,
    QuietHoursService service,
  ) {
    if (_isSelectionMode) {
      final isAllSelected = allSchedules.isNotEmpty &&
          _selectedIds.length == allSchedules.length;

      return AppBar(
        backgroundColor: isDark ? const Color(0xFF1E2D24) : Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: textColor),
          onPressed: () {
            setState(() {
              _isSelectionMode = false;
              _selectedIds.clear();
            });
          },
        ),
        title: Text(
          '${_selectedIds.length} Selected',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isAllSelected
                  ? Icons.select_all_rounded
                  : Icons.deselect_rounded,
              color: isAllSelected ? primaryGreen : textColor,
            ),
            tooltip: isAllSelected ? 'Deselect All' : 'Select All',
            onPressed: () {
              setState(() {
                if (isAllSelected) {
                  _selectedIds.clear();
                } else {
                  _selectedIds.addAll(allSchedules.map((s) => s.id));
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: Color(0xFFEF4444),
            ),
            onPressed: _selectedIds.isEmpty
                ? null
                : () => _confirmDeleteSelected(context),
            tooltip: 'Delete Selected',
          ),
          const SizedBox(width: 8),
        ],
      );
    }

    return AppHeaderBar(
      title: 'QUIET HOURS',
      showBackButton: true,
      actions: [
        if (isSupported)
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Center(
              child: GestureDetector(
                onTap: _hasDndPermission
                    ? null
                    : () => service.openDndPermissionSettings(),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _hasDndPermission
                        ? const Color(0xFF10B981).withValues(alpha: 0.12)
                        : const Color(0xFFF59E0B).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _hasDndPermission
                          ? const Color(0xFF10B981).withValues(alpha: 0.35)
                          : const Color(0xFFF59E0B).withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _hasDndPermission
                            ? Icons.check_circle_rounded
                            : Icons.info_outline_rounded,
                        size: 13,
                        color: _hasDndPermission
                            ? const Color(0xFF10B981)
                            : const Color(0xFFD97706),
                      ),
                      const SizedBox(width: 4.5),
                      Text(
                        _hasDndPermission ? 'Granted' : 'Not Granted',
                        style: GoogleFonts.lexend(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _hasDndPermission
                              ? const Color(0xFF10B981)
                              : const Color(0xFFD97706),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(width: 4),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final rawSchedules = ref.watch(quietHoursProvider);
    final schedules = List<QuietHours>.from(rawSchedules)
      ..sort(
        (a, b) => (a.startHour * 60 + a.startMinute).compareTo(
          b.startHour * 60 + b.startMinute,
        ),
      );
    final service = ref.watch(quietHoursServiceProvider);
    final isSupported = service.isSupported;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryGreen = Color(0xFF2A531D);
    final bgColor = isDark ? const Color(0xFF121B16) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF1E2D24) : Colors.white;
    final cardBorder = isDark
        ? const Color(0xFF2B3F33)
        : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subTextColor = isDark ? Colors.white60 : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: _buildAppBar(context, isDark, textColor, schedules, primaryGreen, isSupported, service),
      body: schedules.isEmpty
          ? _buildEmptyState(context, ref, primaryGreen, isDark, subTextColor)
          : ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 90, top: 12),
              children: [
                // DND Permission Alert Card if permission missing on Android
                if (isSupported && !_hasDndPermission) ...[
                  Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF382315)
                          : const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.5),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Allow Quiet Hours Access',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFB45309),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Grant Do Not Disturb policy access to silence interruptions during scheduled times.',
                          style: GoogleFonts.lexend(
                            fontSize: 12,
                            color: isDark
                                ? Colors.white70
                                : const Color(0xFF78350F),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFB45309),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () =>
                                service.openDndPermissionSettings(),
                            child: Text(
                              'Grant Access',
                              style: GoogleFonts.lexend(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Battery Saver / Optimization Warning Card
                if (isSupported && !_isBatteryOptIgnored) ...[
                  Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF261C14)
                          : const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFD97706).withValues(alpha: 0.5),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.battery_alert_rounded, color: Color(0xFFD97706), size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Allow Background Activity',
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFD97706),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Power Saving Mode on your device will block Quiet Hours from toggling Do Not Disturb when the app is closed. Allow Adhkar to run unrestricted in the background.',
                          style: GoogleFonts.lexend(
                            fontSize: 12,
                            color: isDark ? Colors.white70 : const Color(0xFF92400E),
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD97706),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () async {
                              await service.requestIgnoreBatteryOptimization();
                              await Future.delayed(const Duration(seconds: 1));
                              _checkPermission();
                            },
                            child: Text(
                              'Allow Background Running',
                              style: GoogleFonts.lexend(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // OEM Autostart / Protected App Card (Xiaomi, Oppo, Vivo, Realme, OnePlus, Samsung, etc.)
                if (isSupported && _isAutoStartSupported) ...[
                  Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1B2836)
                          : const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF16A34A).withValues(alpha: 0.4),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.rocket_launch_rounded,
                              color: Color(0xFF16A34A),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Enable Autostart (${_deviceManufacturer.toUpperCase()})',
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF15803D),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'On ${_deviceManufacturer.isNotEmpty ? _deviceManufacturer[0].toUpperCase() + _deviceManufacturer.substring(1) : "OEM"} devices, swiping the app from recents revokes background alarms. Enable Autostart so Quiet Hours always triggers on schedule.',
                          style: GoogleFonts.lexend(
                            fontSize: 12,
                            color: isDark
                                ? Colors.white70
                                : const Color(0xFF14532D),
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF16A34A),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () => service.openAutoStartSettings(),
                            child: Text(
                              'Allow Autostart / Background Run',
                              style: GoogleFonts.lexend(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Exact Alarms Permission Card on Android 12+
                if (isSupported && !_canScheduleExactAlarms) ...[
                  Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E2638)
                          : const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.5),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.alarm_on_rounded, color: Color(0xFF2563EB), size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Exact Alarms Permission',
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF2563EB),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Allow Adhkar to schedule exact start and end triggers so Do Not Disturb turns on and off precisely on time when the app is closed.',
                          style: GoogleFonts.lexend(
                            fontSize: 12,
                            color: isDark ? Colors.white70 : const Color(0xFF1E40AF),
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () async {
                              await service.openExactAlarmSettings();
                              await Future.delayed(const Duration(seconds: 1));
                              _checkPermission();
                            },
                            child: Text(
                              'Enable Exact Alarms',
                              style: GoogleFonts.lexend(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                Padding(
                  padding: const EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 0,
                    bottom: 6,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ALL QUIET TIMINGS',
                        style: GoogleFonts.lexend(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.6,
                          color: subTextColor,
                        ),
                      ),
                      if (_isSelectionMode)
                        InkWell(
                          onTap: () {
                            setState(() {
                              if (schedules.isNotEmpty &&
                                  _selectedIds.length == schedules.length) {
                                _selectedIds.clear();
                              } else {
                                _selectedIds.addAll(schedules.map((s) => s.id));
                              }
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 4,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  schedules.isNotEmpty &&
                                          _selectedIds.length == schedules.length
                                      ? Icons.check_box_rounded
                                      : Icons.check_box_outline_blank_rounded,
                                  size: 18,
                                  color: primaryGreen,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  schedules.isNotEmpty &&
                                          _selectedIds.length == schedules.length
                                      ? 'Deselect All'
                                      : 'Select All',
                                  style: GoogleFonts.lexend(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                    color: primaryGreen,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                ...schedules.map(
                  (s) => _buildQuietHoursCard(
                    context,
                    ref,
                    s,
                    primaryGreen,
                    cardBg,
                    cardBorder,
                    textColor,
                    subTextColor,
                    isDark,
                  ),
                ),
              ],
            ),
      floatingActionButton: (schedules.isEmpty || _isSelectionMode)
          ? null
          : FloatingActionButton.extended(
              onPressed: () {
                QuietHoursLibraryModal.show(context);
              },
              backgroundColor: primaryGreen,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: Text(
                'Add Timing',
                style: GoogleFonts.lexend(
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                ),
              ),
            ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    WidgetRef ref,
    Color primaryGreen,
    bool isDark,
    Color subTextColor,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E2D24)
                    : const Color(0xFFFFFFFF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.do_not_disturb_on_outlined,
                size: 44,
                color: Color(0xFF2A531D),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No Quiet Hours Timings Yet',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Set automatic quiet periods for prayers or focus.',
              style: GoogleFonts.lexend(
                fontSize: 13,
                color: subTextColor,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                QuietHoursLibraryModal.show(context);
              },
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add Timing'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuietHoursCard(
    BuildContext context,
    WidgetRef ref,
    QuietHours schedule,
    Color primaryGreen,
    Color cardBg,
    Color cardBorder,
    Color textColor,
    Color subTextColor,
    bool isDark,
  ) {
    final gridBg = isDark ? const Color(0xFF16251C) : const Color(0xFFF8FAFC);
    final gridBorder = isDark ? Colors.white12 : const Color(0xFFE2E8F0);
    final daysMap = const {
      1: 'Mon',
      2: 'Tue',
      3: 'Wed',
      4: 'Thu',
      5: 'Fri',
      6: 'Sat',
      7: 'Sun',
    };
    final isSelected = _selectedIds.contains(schedule.id);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected
            ? (isDark
                ? primaryGreen.withValues(alpha: 0.15)
                : const Color(0xFFE8F5E9))
            : cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isSelected ? primaryGreen : cardBorder,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          if (!isDark && !isSelected)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            if (_isSelectionMode) {
              _toggleSelection(schedule.id);
            } else {
              QuietHoursModal.show(
                context: context,
                initialSchedule: schedule,
                onSave: (updated) {
                  ref.read(quietHoursProvider.notifier).updateSchedule(updated);
                },
                onDelete: () {
                  ref
                      .read(quietHoursProvider.notifier)
                      .deleteSchedule(schedule.id);
                  _showDeleteToast(context, 'Timing deleted');
                },
              );
            }
          },
          onLongPress: () {
            if (!_isSelectionMode) {
              setState(() {
                _isSelectionMode = true;
                _selectedIds.add(schedule.id);
              });
            } else {
              _toggleSelection(schedule.id);
            }
          },
          child: Padding(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: 12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1st ROW: Title, Subtitle, and right-side Switch / Selection Checkbox
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (_isSelectionMode) ...[
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 24,
                        height: 24,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? primaryGreen : Colors.transparent,
                          border: Border.all(
                            color: isSelected
                                ? primaryGreen
                                : (isDark
                                    ? Colors.white38
                                    : Colors.grey.shade400),
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                size: 16,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            schedule.title,
                            maxLines: 1,
                            style: GoogleFonts.outfit(
                              fontSize: 17.5,
                              height: 1.2,
                              fontWeight: FontWeight.w500,
                              color: schedule.enabled
                                  ? textColor
                                  : (isDark ? Colors.white38 : Colors.grey),
                            ),
                          ),
                          if (schedule.description != null &&
                              schedule.description!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              schedule.description!,
                              style: GoogleFonts.lexend(
                                fontSize: 12,
                                color: subTextColor,
                                height: 1.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    IgnorePointer(
                      ignoring: _isSelectionMode,
                      child: Transform.scale(
                        scale: 0.82,
                        child: Switch(
                          value: schedule.enabled,
                          activeTrackColor: primaryGreen,
                          onChanged: (val) {
                            ref
                                .read(quietHoursProvider.notifier)
                                .toggleScheduleEnabled(schedule.id, val);
                            _showToast(
                              context,
                              val ? 'Activated' : 'Deactivated',
                              val,
                              isDark,
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // 2nd ROW: Time Range Box & Repeat Days Grid
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 0,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: gridBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: gridBorder, width: 1),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time_filled_rounded,
                                  size: 16,
                                  color: schedule.enabled
                                      ? primaryGreen
                                      : subTextColor,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${_formatTimeOfDay(schedule.startTime)} – ${_formatTimeOfDay(schedule.endTime)}',
                                  style: GoogleFonts.outfit(
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.bold,
                                    color: schedule.enabled
                                        ? primaryGreen
                                        : subTextColor,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              _calculateDurationStr(schedule),
                              style: GoogleFonts.lexend(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: subTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Divider(
                        height: 1,
                        color: isDark
                            ? Colors.grey.shade700
                            : Colors.grey.shade300,
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [1, 2, 3, 4, 5, 6, 7].map((dayInt) {
                            final dayName = daysMap[dayInt]!;
                            final isSelected = schedule.weekdays.contains(
                              dayInt,
                            );
                            return Container(
                              width: 36,
                              height: 36,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? (schedule.enabled
                                          ? primaryGreen
                                          : (isDark
                                                ? Colors.white24
                                                : Colors.grey.shade400))
                                    : Colors.transparent,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? (schedule.enabled
                                            ? primaryGreen
                                            : (isDark
                                                  ? Colors.white24
                                                  : Colors.grey.shade400))
                                      : gridBorder,
                                ),
                              ),
                              child: Text(
                                dayName,
                                style: GoogleFonts.lexend(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? Colors.white
                                      : subTextColor,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
