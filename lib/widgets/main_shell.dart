import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_islamic_icons/flutter_islamic_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/extensions/context_extensions.dart';
import '../core/services/showcase_service.dart';
import '../shared/widgets/app_floating_toast.dart';
import '../shared/widgets/app_showcase.dart';
import 'app_drawer.dart';

class MainShell extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  DateTime? _lastBackPressTime;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _onTapIndex(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        // 1. If drawer is open, close drawer first
        if (_scaffoldKey.currentState?.isDrawerOpen == true) {
          _scaffoldKey.currentState?.closeDrawer();
          return;
        }

        // 2. If user is on another tab/branch, switch to Home tab (branch 0)
        if (widget.navigationShell.currentIndex != 0) {
          widget.navigationShell.goBranch(0);
          return;
        }

        // 3. User is on Home screen: Require double-back press within 2000ms to exit
        final now = DateTime.now();
        if (_lastBackPressTime == null ||
            now.difference(_lastBackPressTime!) > const Duration(milliseconds: 2000)) {
          _lastBackPressTime = now;
          HapticFeedback.lightImpact();
          AppFloatingToast.showExitToast(context);
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        drawer: const AppDrawer(),
        body: widget.navigationShell,
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF18181B) : Colors.white,
            border: Border(
              top: BorderSide(
                color: isDark ? const Color(0xFF27272A) : const Color(0xFFE5E7EB),
                width: 1.0,
              ),
            ),
          ),
          child: NavigationBarTheme(
            data: NavigationBarThemeData(
              height: 60,
              indicatorColor: isDark
                  ? const Color(0xFF1C3822)
                  : context.colorScheme.primaryContainer,
              iconTheme: WidgetStateProperty.resolveWith((states) {
                final isSelected = states.contains(WidgetState.selected);
                return IconThemeData(
                  color: isSelected
                      ? (isDark ? const Color(0xFF86EFAC) : const Color(0xFF2A531D))
                      : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                );
              }),
              labelTextStyle: WidgetStateProperty.resolveWith((states) {
                final isSelected = states.contains(WidgetState.selected);
                return TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  height: 1.2,
                  color: isSelected
                      ? (isDark ? const Color(0xFF86EFAC) : const Color(0xFF2A531D))
                      : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                );
              }),
            ),
            child: NavigationBar(
              selectedIndex: widget.navigationShell.currentIndex,
              onDestinationSelected: _onTapIndex,
              indicatorColor: isDark
                  ? const Color(0xFF1C3822)
                  : context.colorScheme.primaryContainer,
              backgroundColor: isDark ? const Color(0xFF18181B) : Colors.white,
              elevation: 0,
              height: 70,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                  destinations: [
                    const NavigationDestination(
                      icon: SizedBox(
                        width: 44,
                        height: 44,
                        child: Center(
                          child: Icon(FlutterIslamicIcons.mosque, size: 22),
                        ),
                      ),
                      selectedIcon: SizedBox(
                        width: 44,
                        height: 44,
                        child: Center(
                          child: Icon(FlutterIslamicIcons.solidMosque, size: 22),
                        ),
                      ),
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
                        targetPadding: EdgeInsets.zero,
                        child: const SizedBox(
                          width: 44,
                          height: 44,
                          child: Center(
                            child: Icon(FlutterIslamicIcons.solidQuran2, size: 22),
                          ),
                        ),
                      ),
                      selectedIcon: const SizedBox(
                        width: 44,
                        height: 44,
                        child: Center(
                          child: Icon(FlutterIslamicIcons.solidQuran2, size: 22),
                        ),
                      ),
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
                        targetPadding: EdgeInsets.zero,
                        child: const SizedBox(
                          width: 44,
                          height: 44,
                          child: Center(
                            child: Icon(FlutterIslamicIcons.tasbih2, size: 22),
                          ),
                        ),
                      ),
                      selectedIcon: const SizedBox(
                        width: 44,
                        height: 44,
                        child: Center(
                          child: Icon(FlutterIslamicIcons.solidTasbih2, size: 22),
                        ),
                      ),
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
                        targetPadding: EdgeInsets.zero,
                        child: const SizedBox(
                          width: 44,
                          height: 44,
                          child: Center(
                            child: Icon(FlutterIslamicIcons.qibla, size: 22),
                          ),
                        ),
                      ),
                      selectedIcon: const SizedBox(
                        width: 44,
                        height: 44,
                        child: Center(
                          child: Icon(FlutterIslamicIcons.solidQibla, size: 22),
                        ),
                      ),
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