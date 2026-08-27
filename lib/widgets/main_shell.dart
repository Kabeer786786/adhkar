import 'package:flutter/material.dart';
import 'package:flutter_islamic_icons/flutter_islamic_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/extensions/context_extensions.dart';
import '../core/services/showcase_service.dart';
import '../features/asma_ul_husna/services/asma_audio_service.dart';
import '../features/quran/services/quran_audio_service.dart';
import '../shared/widgets/app_showcase.dart';
import 'app_drawer.dart';

class MainShell extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAndNavigateToActiveMedia();
    }
  }

  void _checkAndNavigateToActiveMedia() {
    final quranAudio = ref.read(quranAudioProvider);
    final asmaAudio = ref.read(asmaAudioProvider);

    if (quranAudio.currentIndex >= 0 && quranAudio.isPlaying) {
      final surahNum = quranAudio.surahNumber ?? 1;
      final name = Uri.encodeComponent(quranAudio.title);
      context.push('/quran/surah?num=$surahNum&name=$name');
    } else if (asmaAudio.currentIndex >= 0 && asmaAudio.isPlaying) {
      context.push('/asma-ul-husna');
    }
  }

  void _onTapIndex(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: widget.navigationShell.currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (widget.navigationShell.currentIndex != 0) {
          widget.navigationShell.goBranch(0);
        }
      },
      child: Scaffold(
        drawer: const AppDrawer(),
        body: widget.navigationShell,
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(
                color: Color(0xFFE5E7EB),
                width: 1.0,
              ),
            ),
          ),
              child: NavigationBarTheme(
                data: NavigationBarThemeData(
                  height: 60,
                  labelTextStyle: WidgetStateProperty.resolveWith((states) {
                    final isSelected = states.contains(WidgetState.selected);
                    return TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      height: 1.2,
                    );
                  }),
                ),
                child: NavigationBar(
                  selectedIndex: widget.navigationShell.currentIndex,
                  onDestinationSelected: _onTapIndex,
                  indicatorColor: context.colorScheme.primaryContainer,
                  elevation: 0,
                  height: 70,
                  labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                  destinations: [
                    const NavigationDestination(
                      icon: Icon(FlutterIslamicIcons.mosque, size: 22),
                      selectedIcon: Icon(FlutterIslamicIcons.solidMosque, size: 22),
                      label: 'Home',
                    ),
                    NavigationDestination(
                      icon: AppShowcase(
                        globalKey: ShowcaseService.keyQuranTab,
                        title: 'Holy Quran',
                        description:
                            'Explore Surahs with audio recitations, translations, and verse bookmarking.',
                        stepIndex: 13,
                        totalSteps: 15,
                        targetShapeBorder: const CircleBorder(),
                        child: const Icon(FlutterIslamicIcons.solidQuran2, size: 22),
                      ),
                      selectedIcon:
                          const Icon(FlutterIslamicIcons.solidQuran2, size: 22),
                      label: 'Quran',
                    ),
                    NavigationDestination(
                      icon: AppShowcase(
                        globalKey: ShowcaseService.keyAdhkarTab,
                        title: 'Daily Adhkar',
                        description:
                            'Access Morning, Evening, Bedtime, and Daily Remembrance Supplications.',
                        stepIndex: 14,
                        totalSteps: 15,
                        targetShapeBorder: const CircleBorder(),
                        child: const Icon(FlutterIslamicIcons.tasbih2, size: 22),
                      ),
                      selectedIcon:
                          const Icon(FlutterIslamicIcons.solidTasbih2, size: 22),
                      label: 'Adhkar',
                    ),
                    NavigationDestination(
                      icon: AppShowcase(
                        globalKey: ShowcaseService.keyQiblaTab,
                        title: 'Qibla Compass',
                        description:
                            'Find the exact Qibla direction anywhere in the world using interactive compass.',
                        stepIndex: 15,
                        totalSteps: 15,
                        targetShapeBorder: const CircleBorder(),
                        child: const Icon(FlutterIslamicIcons.qibla, size: 22),
                      ),
                      selectedIcon:
                          const Icon(FlutterIslamicIcons.solidQibla, size: 22),
                      label: 'Qibla',
                    ),
                  ],
                ),
              ),
        ),
      ),
    );
  }
}