import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../shared/providers/app_providers.dart';
import '../alarm_screen.dart';

class AlarmBackgroundConfig {
  static const List<String> imageList = [
    'assets/images/alarm-bgs/bg1.jpg',
    'assets/images/alarm-bgs/bg2.jpg',
    'assets/images/alarm-bgs/bg3.jpg',
    'assets/images/alarm-bgs/bg4.jpg',
    'assets/images/alarm-bgs/bg5.jpg',
    'assets/images/alarm-bgs/bg6.jpg',
    'assets/images/alarm-bgs/bg7.jpg',
    'assets/images/alarm-bgs/bg8.jpg',
    'assets/images/alarm-bgs/bg9.jpg',
    'assets/images/alarm-bgs/bg10.jpg',
    'assets/images/alarm-bgs/bg11.jpg',
    'assets/images/alarm-bgs/bg12.jpg',
    'assets/images/alarm-bgs/bg13.jpg',
    'assets/images/alarm-bgs/bg14.jpg',
  ];

  static const List<Map<String, dynamic>> gradientList = [
    {
      'id': 'emerald_twilight',
      'name': 'Emerald Dusk',
      'colors': [Color(0xFF04160C), Color(0xFF0A2B19), Color(0xFF13452A)],
    },
    {
      'id': 'midnight_aurora',
      'name': 'Midnight Sky',
      'colors': [Color(0xFF090E18), Color(0xFF101F36), Color(0xFF1C385E)],
    },
    {
      'id': 'dark_obsidian',
      'name': 'Obsidian Slate',
      'colors': [Color(0xFF0C0D10), Color(0xFF171A21), Color(0xFF222733)],
    },
    {
      'id': 'royal_amethyst',
      'name': 'Royal Amethyst',
      'colors': [Color(0xFF13091F), Color(0xFF24133B), Color(0xFF381F59)],
    },
    {
      'id': 'mystic_teal',
      'name': 'Mystic Teal',
      'colors': [Color(0xFF061819), Color(0xFF0D3235), Color(0xFF184C4F)],
    },
    {
      'id': 'rain_mist',
      'name': 'Rainy Mist',
      'colors': [Color(0xFF111A20), Color(0xFF1F2D36), Color(0xFF2F424E)],
    },
  ];

  static List<Color> getGradientColors(String id) {
    final found = gradientList.firstWhere(
      (g) => g['id'] == id,
      orElse: () => gradientList.first,
    );
    return (found['colors'] as List).cast<Color>();
  }
}

class AlarmCustomizationModal extends ConsumerStatefulWidget {
  const AlarmCustomizationModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AlarmCustomizationModal(),
    );
  }

  @override
  ConsumerState<AlarmCustomizationModal> createState() =>
      _AlarmCustomizationModalState();
}

class _AlarmCustomizationModalState
    extends ConsumerState<AlarmCustomizationModal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late String _selectedType;
  late String _selectedValue;
  late bool _showWaves;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final storage = ref.read(storageServiceProvider);
    _selectedType = storage.getAlarmBgType();
    _selectedValue = storage.getAlarmBgValue();
    _showWaves = storage.getAlarmShowWaves();

    if (_selectedType == 'gradient') {
      _tabController.index = 1;
    } else {
      _tabController.index = 0;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    final storage = ref.read(storageServiceProvider);
    await storage.setAlarmBgType(_selectedType);
    await storage.setAlarmBgValue(_selectedValue);
    await storage.setAlarmShowWaves(_showWaves);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF15803D),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          content: Text(
            'Alarm screen appearance updated',
            style: GoogleFonts.lexend(fontSize: 13, color: Colors.white),
          ),
        ),
      );
    }
  }

  void _previewAlarm() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AlarmScreen(
          title: "It's time !",
          soundType: 'preview_silent',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF131D17) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = isDark ? Colors.white70 : const Color(0xFF64748B);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Container(
            width: 44,
            height: 4.5,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 14),

          // Header Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Alarm Screen Theme',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Customize your alarm background & animations',
                        style: GoogleFonts.lexend(fontSize: 12, color: subColor),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () async {
                    // Temporarily persist current choice so preview uses it
                    final storage = ref.read(storageServiceProvider);
                    await storage.setAlarmBgType(_selectedType);
                    await storage.setAlarmBgValue(_selectedValue);
                    await storage.setAlarmShowWaves(_showWaves);
                    _previewAlarm();
                  },
                  icon: const Icon(Icons.remove_red_eye_outlined, size: 16),
                  label: const Text('Preview'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF16A34A),
                    backgroundColor: const Color(0xFF16A34A).withValues(alpha: 0.12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Tab Bar: Wallpapers vs Gradients
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F2E24) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: const Color(0xFF16A34A),
                borderRadius: BorderRadius.circular(12),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: subColor,
              labelStyle: GoogleFonts.lexend(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              tabs: const [
                Tab(
                  iconMargin: EdgeInsets.zero,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.photo_library_outlined, size: 16),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Wallpapers',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Tab(
                  iconMargin: EdgeInsets.zero,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.gradient_rounded, size: 16),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Gradients',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Waves Ambient Animation Toggle
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A281F) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? const Color(0xFF2D4034) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16A34A).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.waves_rounded,
                    color: Color(0xFF16A34A),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Ambient Wave Motion',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'Render professional ambient waves behind the alarm',
                        style: GoogleFonts.lexend(fontSize: 11, color: subColor),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Switch.adaptive(
                  value: _showWaves,
                  activeTrackColor: const Color(0xFF16A34A),
                  onChanged: (val) {
                    setState(() => _showWaves = val);
                  },
                ),
              ],
            ),
          ),

          const Divider(height: 16),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // 1. Wallpaper Image Grid
                _buildWallpaperGrid(),

                // 2. Gradient Selection
                _buildGradientList(),
              ],
            ),
          ),

          // Bottom Action Bar
          Container(
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              MediaQuery.of(context).padding.bottom > 0
                  ? MediaQuery.of(context).padding.bottom + 8
                  : 16,
            ),
            decoration: BoxDecoration(
              color: bgColor,
              border: Border(
                top: BorderSide(
                  color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.06),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(
                        color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.lexend(
                        color: subColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Apply Theme',
                      style: GoogleFonts.lexend(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWallpaperGrid() {
    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.65,
      ),
      itemCount: AlarmBackgroundConfig.imageList.length,
      itemBuilder: (context, index) {
        final imgPath = AlarmBackgroundConfig.imageList[index];
        final isSelected =
            _selectedType == 'image' && _selectedValue == imgPath;

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedType = 'image';
              _selectedValue = imgPath;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? const Color(0xFF22C55E) : Colors.transparent,
                width: isSelected ? 3.0 : 1.0,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: const Color(0xFF22C55E).withValues(alpha: 0.3),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    imgPath,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(
                      color: const Color(0xFF1F2937),
                      child: const Icon(
                        Icons.broken_image_rounded,
                        color: Colors.white54,
                        size: 24,
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.5),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 6,
                    left: 6,
                    right: 6,
                    child: Text(
                      'Wallpaper ${index + 1}',
                      style: GoogleFonts.lexend(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isSelected)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Color(0xFF22C55E),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGradientList() {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: AlarmBackgroundConfig.gradientList.length,
      itemBuilder: (context, index) {
        final grad = AlarmBackgroundConfig.gradientList[index];
        final gradId = grad['id'] as String;
        final name = grad['name'] as String;
        final colors = (grad['colors'] as List).cast<Color>();
        final isSelected =
            _selectedType == 'gradient' && _selectedValue == gradId;

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedType = 'gradient';
              _selectedValue = gradId;
            });
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            height: 74,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: colors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? const Color(0xFF22C55E) : Colors.white24,
                width: isSelected ? 2.5 : 1.0,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: const Color(0xFF22C55E).withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white54, width: 1.5),
                      gradient: RadialGradient(colors: colors),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      name,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFF22C55E),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
