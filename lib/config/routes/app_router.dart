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
import '../../features/reminder/presentation/alarm_screen.dart';
import '../../features/quiet_hours/presentation/quiet_hours_screen.dart';
import '../../features/roza/presentation/roza_screen.dart';
import '../../features/sci_islam/presentation/sci_islam_screen.dart';
import '../../features/dua/presentation/dua_screen.dart';
import '../../features/sadqa/presentation/sadqa_screen.dart';
import '../../features/books/presentation/books_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/permissions/presentation/permissions_screen.dart';
import '../../features/calendar/presentation/islamic_calendar_screen.dart';
import '../../features/about_islam/presentation/what_is_islam_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/onboarding/presentation/profile_setup_screen.dart';
import '../../features/auth/presentation/auth_screen.dart';
import '../../features/auth/presentation/verify_email_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../widgets/main_shell.dart';


import 'package:shared_preferences/shared_preferences.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  redirect: (context, state) async {
    final location = state.uri.toString();
    final isAuthRoute = location == '/splash' ||
        location == '/onboarding' ||
        location == '/auth' ||
        location.startsWith('/verify-email') ||
        location == '/profile-setup';

    final prefs = await SharedPreferences.getInstance();
    final isRegistered = prefs.getBool('registration_completed') ?? false;
    final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;
    final hasSkipped = prefs.getBool('has_skipped_registration') ?? false;

    final canAccessApp = isRegistered || hasSeenOnboarding || hasSkipped;

    if (!canAccessApp && !isAuthRoute) {
      return '/onboarding';
    }
    return null;

  },
  routes: [
    GoRoute(
      path: '/splash',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SplashScreen(),
    ),

    GoRoute(
      path: '/auth',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const AuthScreen(),
    ),

    GoRoute(
      path: '/verify-email',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final email = state.uri.queryParameters['email'];
        return VerifyEmailScreen(email: email);
      },
    ),

    GoRoute(
      path: '/onboarding',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const OnboardingScreen(),
    ),

    GoRoute(
      path: '/profile-setup',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ProfileSetupScreen(),
    ),

    GoRoute(
      path: '/profile',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ProfileScreen(),
    ),


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
              pageBuilder: (context, state) {
                return CustomTransitionPage(
                  key: state.pageKey,
                  child: const HomeScreen(),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    final scaleAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      ),
                    );
                    return FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale: scaleAnimation,
                        child: child,
                      ),
                    );
                  },
                );
              },
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
      path: '/permissions',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const PermissionsScreen(),
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
        final juzStr = state.uri.queryParameters['juz'];
        final name = state.uri.queryParameters['name'] ?? 'Al-Fatiha';
        final startAyahStr = state.uri.queryParameters['startAyah'];
        final isFromBookmark =
            state.uri.queryParameters['fromBookmark'] == 'true';
        return SurahDetailScreen(
          surahNumber: int.parse(numStr),
          juzNumber: juzStr != null ? int.tryParse(juzStr) : null,
          surahName: name,
          initialAyahNumber:
              startAyahStr != null ? int.tryParse(startAyahStr) : null,
          fromBookmark: isFromBookmark,
        );
      },
    ),
    GoRoute(
      path: '/reminder',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ReminderScreen(),
    ),

    GoRoute(
      path: '/quiet-hours',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const QuietHoursScreen(),
    ),

    GoRoute(
      path: '/alarm',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final reminderId = state.uri.queryParameters['id'];
        final prayerName = state.uri.queryParameters['prayer'];
        final title = state.uri.queryParameters['title'];
        final soundType = state.uri.queryParameters['sound'];
        return AlarmScreen(
          reminderId: reminderId,
          prayerName: prayerName,
          title: title,
          soundType: soundType,
        );
      },
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
