import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/adhkar/presentation/adhkar_detail_screen.dart';
import '../../features/adhkar/presentation/adhkar_screen.dart';
import '../../features/asma_ul_husna/presentation/asma_ul_husna_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/prayer/presentation/prayer_screen.dart';
import '../../features/qibla/presentation/qibla_screen.dart';
import '../../features/quran/presentation/quran_screen.dart';
import '../../features/quran/presentation/surah_detail_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/settings/presentation/app_info_screen.dart';
import '../../features/tasbeeh/presentation/tasbeeh_screen.dart';
import '../../features/reminder/presentation/reminder_screen.dart';
import '../../features/roza/presentation/roza_screen.dart';
import '../../features/sci_islam/presentation/sci_islam_screen.dart';
import '../../features/dua/presentation/dua_screen.dart';
import '../../features/sadqa/presentation/sadqa_screen.dart';
import '../../features/books/presentation/books_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/calendar/presentation/islamic_calendar_screen.dart';
import '../../features/about_islam/presentation/what_is_islam_screen.dart';
import '../../widgets/main_shell.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainShell(navigationShell: navigationShell);
      },
      branches: [
        // Branch 0: Home
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),

        // Branch 1: Quran
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/quran',
              builder: (context, state) => const QuranScreen(),
            ),
          ],
        ),

        // Branch 2: Adhkar
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/adhkar',
              builder: (context, state) => const AdhkarScreen(),
            ),
          ],
        ),

        // Branch 3: Qibla
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/qibla',
              builder: (context, state) => const QiblaScreen(),
            ),
          ],
        ),
      ],
    ),

    // Additional full-screen routes accessible from drawer and search
    GoRoute(
      path: '/prayer',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const PrayerScreen(),
    ),

    GoRoute(
      path: '/tasbeeh',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const TasbeehScreen(),
    ),

    GoRoute(
      path: '/settings',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SettingsScreen(),
    ),

    GoRoute(
      path: '/app-info',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const AppInfoScreen(),
    ),

    GoRoute(
      path: '/notifications',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const NotificationsScreen(),
    ),

    GoRoute(
      path: '/islamic-calendar',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const IslamicCalendarScreen(),
    ),

    GoRoute(
      path: '/what-is-islam',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const WhatIsIslamScreen(),
    ),

    GoRoute(
      path: '/asma-ul-husna',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const AsmaUlHusnaScreen(),
    ),

    GoRoute(
      path: '/adhkar/detail',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final id = state.uri.queryParameters['id'] ?? 'morning';
        final title = state.uri.queryParameters['title'] ?? 'Morning Adhkar';
        return AdhkarDetailScreen(categoryId: id, title: title);
      },
    ),

    GoRoute(
      path: '/quran/surah',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final numStr = state.uri.queryParameters['num'] ?? '1';
        final name = state.uri.queryParameters['name'] ?? 'Al-Fatiha';
        return SurahDetailScreen(
          surahNumber: int.parse(numStr),
          surahName: name,
        );
      },
    ),
    GoRoute(
      path: '/reminder',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ReminderScreen(),
    ),

    GoRoute(
      path: '/roza',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const RozaScreen(),
    ),

    GoRoute(
      path: '/sci-islam',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SciIslamScreen(),
    ),

    GoRoute(
      path: '/dua',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const DuaScreen(),
    ),

    GoRoute(
      path: '/sadqa',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SadqaScreen(),
    ),

    GoRoute(
      path: '/books',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const BooksScreen(),
    ),
  ],
);
