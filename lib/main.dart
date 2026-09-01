import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_background/just_audio_background.dart';
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

  // Initialize Background Audio Service
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.sprnt.adhkar.channel.audio',
    androidNotificationChannelName: 'Adhkar Audio Playback',
    androidNotificationOngoing: false,
    androidStopForegroundOnPause: true,
  );

  // Initialize Local Hive Storage
  final storageService = StorageService();
  await storageService.init();

  // Initialize Local Notifications
  await NotificationService().init();
  NotificationService().onNotificationSelected.listen((payload) {
    if (payload != null && payload.isNotEmpty) {
      if (payload.startsWith('reminder_id:')) {
        final remId = payload.substring('reminder_id:'.length);
        appRouter.push('/alarm?id=$remId');
      } else if (payload.startsWith('prayer:')) {
        final prayer = payload.substring('prayer:'.length);
        appRouter.push('/alarm?prayer=$prayer');
      }
    }
  });

  // Initialize Supabase Service
  await SupabaseService().init();

  runApp(
    ProviderScope(
      overrides: [storageServiceProvider.overrideWithValue(storageService)],
      child: const AdhkarApp(),
    ),
  );
}

class AdhkarApp extends ConsumerWidget {
  const AdhkarApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Adhkar - Islamic Companion',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(context),
      themeMode: ThemeMode.light, // Enforce Light Theme by default
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
