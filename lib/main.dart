import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:showcaseview/showcaseview.dart';
import 'config/routes/app_router.dart';
import 'core/services/notification_service.dart';
import 'core/services/showcase_service.dart';
import 'core/services/storage_service.dart';
import 'core/services/supabase_service.dart';
import 'core/theme/app_theme.dart';
import 'shared/providers/app_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Local Hive Storage
  final storageService = StorageService();
  await storageService.init();

  // Initialize Local Notifications
  await NotificationService().init();

  // Initialize Supabase Service
  await SupabaseService().init();

  runApp(
    ProviderScope( 
      overrides: [
        storageServiceProvider.overrideWithValue(storageService),
      ],
      child: const AdhkarApp(),
    ),
  );
}

class AdhkarApp extends ConsumerWidget {
  const AdhkarApp({super.key}); 

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeModeStr = ref.watch(themeModeProvider);

    ThemeMode themeMode;
    switch (themeModeStr) {
      case 'light':
        themeMode = ThemeMode.light;
        break;
      case 'dark':
        themeMode = ThemeMode.dark;
        break;
      default:
        themeMode = ThemeMode.system;
    }

    return MaterialApp.router(
      title: 'Adhkar - Islamic Companion',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(context), 
      darkTheme: AppTheme.darkTheme(context),
      themeMode: themeMode,
      routerConfig: appRouter,
      builder: (context, child) {
        return ShowCaseWidget(
          blurValue: 0,
          enableAutoScroll: false,
          onFinish: () {
            ShowcaseService.markHomeShowcaseAsSeen();
          },
          builder: (context) => child ?? const SizedBox.shrink(),
        );
      },



    );
  }
}
