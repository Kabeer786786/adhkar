import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/services/native_alarm_service.dart';
import '../../../../shared/providers/app_providers.dart';
import '../../../../shared/widgets/app_floating_toast.dart';
import '../alarm_screen.dart';

class AlarmInteractionSettingsModal extends ConsumerStatefulWidget {
  const AlarmInteractionSettingsModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AlarmInteractionSettingsModal(),
    );
  }

  @override
  ConsumerState<AlarmInteractionSettingsModal> createState() =>
      _AlarmInteractionSettingsModalState();
}

class _AlarmInteractionSettingsModalState
    extends ConsumerState<AlarmInteractionSettingsModal> {
  VolumeButtonAction _volumeAction = VolumeButtonAction.stopAlarm;
  ScreenOffAction _screenOffAction = ScreenOffAction.stopAlarm;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final storage = ref.read(storageServiceProvider);
    final storedVolume = storage.getVolumeButtonAction();
    final storedScreenOff = storage.getScreenOffAction();

    // Check native sync
    final nativeSettings =
        await NativeAlarmService.instance.getAlarmInteractionSettings();
    final effectiveVolume = nativeSettings['volumeButtonAction'] ?? storedVolume;
    final effectiveScreenOff =
        nativeSettings['screenOffAction'] ?? storedScreenOff;

    if (mounted) {
      setState(() {
        _volumeAction = VolumeButtonAction.fromValue(effectiveVolume);
        _screenOffAction = ScreenOffAction.fromValue(effectiveScreenOff);
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    final storage = ref.read(storageServiceProvider);
    await storage.setVolumeButtonAction(_volumeAction.value);
    await storage.setScreenOffAction(_screenOffAction.value);

    await NativeAlarmService.instance.saveAlarmInteractionSettings(
      volumeButtonAction: _volumeAction,
      screenOffAction: _screenOffAction,
    );

    if (mounted) {
      Navigator.pop(context);
      AppFloatingToast.showSuccess(
        context,
        message: 'Alarm interaction settings saved',
      );
    }
  }

  void _testAlarmBehavior() {
    // Launch a safe 10-second test alarm so the user can test volume button and screen-off behavior
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const AlarmScreen(
          title: 'Test Alarm Interaction',
          soundType: 'Default Ringtone',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E2D24) : Colors.white;
    final cardBorder =
        isDark ? const Color(0xFF2B3F33) : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subTextColor = isDark ? Colors.white60 : const Color(0xFF64748B);
    const primaryGreen = Color(0xFF2A531D);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Header Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryGreen.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.touch_app_outlined,
                        color: primaryGreen,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Alarm Interaction',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                        Text(
                          'Volume button & screen-off controls',
                          style: GoogleFonts.lexend(
                            fontSize: 11.5,
                            color: subTextColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          Divider(
            height: 1,
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          ),

          // Scrollable Settings Content
          Flexible(
            child: _isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(color: primaryGreen),
                    ),
                  )
                : ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    children: [
                      // Section A: Volume Button Action
                      Text(
                        'VOLUME BUTTON ACTION',
                        style: GoogleFonts.lexend(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.6,
                          color: primaryGreen,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Choose what happens when you press a volume button during an active alarm.',
                        style: GoogleFonts.lexend(
                          fontSize: 12,
                          color: subTextColor,
                        ),
                      ),
                      const SizedBox(height: 12),

                      ...VolumeButtonAction.values.map((action) {
                        final isSelected = _volumeAction == action;
                        return _buildOptionCard(
                          title: action.title,
                          description: action.description,
                          isSelected: isSelected,
                          onTap: () => setState(() => _volumeAction = action),
                          isDark: isDark,
                          textColor: textColor,
                          subTextColor: subTextColor,
                          primaryGreen: primaryGreen,
                          cardBorder: cardBorder,
                        );
                      }),

                      const SizedBox(height: 20),

                      // Section B: Screen-Off Action
                      Text(
                        'SCREEN-OFF ALARM ACTION',
                        style: GoogleFonts.lexend(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.6,
                          color: primaryGreen,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Choose what happens when your phone screen turns off (e.g. power button pressed) during an active alarm.',
                        style: GoogleFonts.lexend(
                          fontSize: 12,
                          color: subTextColor,
                        ),
                      ),
                      const SizedBox(height: 12),

                      ...ScreenOffAction.values.map((action) {
                        final isSelected = _screenOffAction == action;
                        return _buildOptionCard(
                          title: action.title,
                          description: action.description,
                          isSelected: isSelected,
                          onTap: () => setState(() => _screenOffAction = action),
                          isDark: isDark,
                          textColor: textColor,
                          subTextColor: subTextColor,
                          primaryGreen: primaryGreen,
                          cardBorder: cardBorder,
                        );
                      }),

                    ],
                  ),
          ),

          // Sticky Bottom Save Bar
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            decoration: BoxDecoration(
              color: cardBg,
              border: Border(
                top: BorderSide(
                  color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveSettings,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Save Changes',
                    style: GoogleFonts.lexend(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required String title,
    required String description,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
    required Color textColor,
    required Color subTextColor,
    required Color primaryGreen,
    required Color cardBorder,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected
                ? primaryGreen.withValues(alpha: isDark ? 0.22 : 0.08)
                : (isDark ? const Color(0xFF23352B) : const Color(0xFFF8FAFC)),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? primaryGreen
                  : cardBorder,
              width: isSelected ? 1.6 : 1.0,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(
                  isSelected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  color: isSelected ? primaryGreen : (isDark ? Colors.white38 : const Color(0xFF94A3B8)),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? (isDark ? Colors.white : primaryGreen)
                            : textColor,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
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
        ),
      ),
    );
  }
}
