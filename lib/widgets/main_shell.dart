import 'package:flutter/material.dart';
import 'package:flutter_islamic_icons/flutter_islamic_icons.dart';
import 'package:go_router/go_router.dart';
import '../core/extensions/context_extensions.dart';
import 'app_drawer.dart';

class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  void _onTapIndex(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: navigationShell.currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (navigationShell.currentIndex != 0) {
          navigationShell.goBranch(0);
        }
      },
      child: Scaffold(
        drawer: const AppDrawer(),
        body: navigationShell,
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
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: _onTapIndex,
              indicatorColor: context.colorScheme.primaryContainer,
              elevation: 0,
              height: 70,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              destinations: const [
                NavigationDestination(
                  icon: Icon(FlutterIslamicIcons.mosque, size: 22),
                  selectedIcon: Icon(FlutterIslamicIcons.solidMosque, size: 22),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(FlutterIslamicIcons.quran2, size: 22),
                  selectedIcon: Icon(FlutterIslamicIcons.solidQuran2, size: 22),
                  label: 'Quran',
                ),
                NavigationDestination(
                  icon: Icon(FlutterIslamicIcons.tasbih2, size: 22),
                  selectedIcon: Icon(FlutterIslamicIcons.solidTasbih2, size: 22),
                  label: 'Adhkar',
                ),
                NavigationDestination(
                  icon: Icon(FlutterIslamicIcons.qibla, size: 22),
                  selectedIcon: Icon(FlutterIslamicIcons.solidQibla, size: 22),
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
 