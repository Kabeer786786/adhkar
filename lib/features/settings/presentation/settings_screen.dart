import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_islamic_icons/flutter_islamic_icons.dart';
import '../../../core/services/location_service.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/widgets/location_selection_modal.dart';
import '../../../shared/widgets/m3_card.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../widgets/app_header_bar.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const Map<String, String> _methodLabels = {
    'KARACHI': 'University of Islamic Sciences, Karachi',
    'MWL': 'Muslim World League (MWL)',
    'ISNA': 'Islamic Society of North America (ISNA)',
    'EGYPT': 'Egyptian General Authority of Survey',
    'MAKKAH': 'Umm Al-Qura University, Makkah',
    'GULF': 'Gulf Region Convention',
    'TEHRAN': 'Institute of Geophysics, Tehran',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storage = ref.watch(storageServiceProvider); 
    final currentMethod = ref.watch(calculationMethodProvider);
    final currentJuristic = ref.watch(asrJuristicProvider);
    final currentTheme = ref.watch(themeModeProvider);
    final locationAsync = ref.watch(currentLocationProvider);
    final location = locationAsync.value ?? LocationService.defaultLocation;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const AppHeaderBar(
        title: 'SETTINGS',
        showDrawerButton: false,
        showBackButton: true,
      ), 
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 36),
        children: [
          // 1. Hero Overview Banner Card
          M3Card(
            color: const Color(0xFFE8F4E5),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A531D).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    FlutterIslamicIcons.islam,
                    size: 32,
                    color: Color(0xFF2A531D),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Configuration Active',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: Color(0xFF8C6D53),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${location.city}, ${location.country}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2A531D),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _StatusBadge(label: currentMethod),
                          _StatusBadge(label: '$currentJuristic Asr'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // 2. Location & GPS Section
          const SectionHeader(
            title: 'Location & GPS',
            subtitle: 'Coordinates used for precise prayer calculations',
          ),
          M3Card(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE8F4E5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: Color(0xFF2A531D),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${location.city}, ${location.country}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2A531D),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${location.latitude.toStringAsFixed(4)}°, ${location.longitude.toStringAsFixed(4)}°',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => LocationSelectionModal.show(context),
                    icon: const Icon(Icons.edit_location_alt_rounded, size: 18),
                    label: const Text(
                      'Change City or Detect GPS',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2A531D),
                      side: const BorderSide(color: Color(0xFF2A531D), width: 1.2),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. Calculation Method & Juristic School
          const SectionHeader(
            title: 'Calculation Parameters',
            subtitle: 'Astronomical conventions for solar angle timings',
          ),
          M3Card(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Calculation Method Selector
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE8F4E5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.calculate_rounded,
                        color: Color(0xFF2A531D),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Text(
                        'Calculation Method',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2A531D),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _methodLabels[currentMethod] ?? currentMethod,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: _methodLabels.keys.map((key) {
                    final isSelected = currentMethod == key;
                    return ChoiceChip(
                      label: Text(key),
                      selected: isSelected,
                      selectedColor: const Color(0xFF2A531D),
                      backgroundColor: const Color(0xFFE8F4E5),
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: isSelected ? Colors.white : const Color(0xFF2A531D),
                      ),
                      side: BorderSide(
                        color: isSelected
                            ? const Color(0xFF2A531D)
                            : const Color(0xFFC8E6C9),
                      ),
                      onSelected: (selected) async {
                        if (selected) {
                          await storage.setCalculationMethod(key);
                          ref.read(calculationMethodProvider.notifier).state = key;
                        }
                      },
                    );
                  }).toList(),
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Divider(height: 1, color: Color(0xFFE0E0E0)),
                ),

                // Asr Juristic Method Toggle
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE8F4E5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.balance_rounded,
                        color: Color(0xFF2A531D),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Text(
                        'Asr Juristic Rule',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2A531D),
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
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _OptionSelectTile(
                        title: 'Standard',
                        subtitle: 'Shafi / Maliki',
                        isSelected: currentJuristic == 'Standard',
                        onTap: () async {
                          await storage.setAsrJuristic('Standard');
                          ref.read(asrJuristicProvider.notifier).state = 'Standard';
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _OptionSelectTile(
                        title: 'Hanafi',
                        subtitle: 'Double Shadow',
                        isSelected: currentJuristic == 'Hanafi',
                        onTap: () async {
                          await storage.setAsrJuristic('Hanafi');
                          ref.read(asrJuristicProvider.notifier).state = 'Hanafi';
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 4. Appearance Section
          const SectionHeader(
            title: 'Appearance',
            subtitle: 'Select application theme preference',
          ),
          M3Card(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _ThemeChip(
                  label: 'System',
                  icon: Icons.brightness_auto_rounded,
                  isSelected: currentTheme == 'system',
                  onTap: () async {
                    await storage.setThemeMode('system');
                    ref.read(themeModeProvider.notifier).state = 'system';
                  },
                ),
                const SizedBox(width: 8),
                _ThemeChip(
                  label: 'Light',
                  icon: Icons.light_mode_rounded,
                  isSelected: currentTheme == 'light',
                  onTap: () async {
                    await storage.setThemeMode('light');
                    ref.read(themeModeProvider.notifier).state = 'light';
                  },
                ),
                const SizedBox(width: 8),
                _ThemeChip(
                  label: 'Dark',
                  icon: Icons.dark_mode_rounded,
                  isSelected: currentTheme == 'dark',
                  onTap: () async {
                    await storage.setThemeMode('dark');
                    ref.read(themeModeProvider.notifier).state = 'dark';
                  },
                ),
              ],
            ),
          ),

          // 5. About & App Details
          const SectionHeader(
            title: 'About Adhkar',
            subtitle: 'Version and application info',
          ),
          M3Card(
            color: const Color(0xFFE8F4E5),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        FlutterIslamicIcons.quran,
                        color: Color(0xFF2A531D),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Adhkar App',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2A531D),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Version 1.0.0 • Material 3 Design',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF8C6D53),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Designed for daily consistency in Dhikr, Quran, and Salah.',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF2A531D),
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

class _StatusBadge extends StatelessWidget {
  final String label;

  const _StatusBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF2A531D).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Color(0xFF2A531D),
        ),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2A531D) : const Color(0xFFE8F4E5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF2A531D) : const Color(0xFFC8E6C9),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : const Color(0xFF2A531D),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.85)
                    : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ChoiceChip(
        avatar: Icon(
          icon,
          size: 18,
          color: isSelected ? Colors.white : const Color(0xFF2A531D),
        ),
        label: Text(label),
        selected: isSelected,
        selectedColor: const Color(0xFF2A531D),
        backgroundColor: const Color(0xFFE8F4E5),
        labelStyle: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          color: isSelected ? Colors.white : const Color(0xFF2A531D),
        ),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        side: BorderSide(
          color: isSelected ? const Color(0xFF2A531D) : const Color(0xFFC8E6C9),
        ),
        onSelected: (_) => onTap(),
      ),
    );
  }
}
