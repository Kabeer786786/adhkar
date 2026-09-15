import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audio_service/audio_service.dart';
import 'package:showcaseview/showcaseview.dart';
import 'config/routes/app_router.dart';
import 'core/services/adhkar_audio_handler.dart';
import 'core/services/alarm_audio_service.dart';
import 'core/services/app_update_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/showcase_service.dart';
import 'core/services/storage_service.dart';
import 'core/services/supabase_service.dart';
import 'core/theme/app_theme.dart';
import 'features/quiet_hours/domain/quiet_hours_model.dart';
import 'features/quiet_hours/services/quiet_hours_service.dart';
import 'shared/providers/app_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); 

  // Initialize Background Audio Service (AudioService singleton with AdhkarAudioHandler)
  final adhkarAudioHandler = await AudioService.init(
    builder: () => AdhkarAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.sprnt.adhkar.channel.audio',
      androidNotificationChannelName: 'Adhkar Audio Playback',
      androidNotificationChannelDescription:
          'Playback notifications for Quran recitation and Asma-ul-Husna',
      androidNotificationIcon: 'drawable/ic_notification',
      androidNotificationOngoing: false,
      androidStopForegroundOnPause: false,
    ),
  );

  // Initialize Local Hive Storage
  final storageService = StorageService();
  await storageService.init();

  // Initialize Local Notifications and bind notification selection early
  final notificationService = NotificationService();
  notificationService.onNotificationSelected.listen((payload) {
    if (payload != null && payload.isNotEmpty) {
      if (payload.startsWith('dismiss:')) {
        AlarmAudioService().stopAlarm();
        return;
      }

      final currentLoc = appRouter.routerDelegate.currentConfiguration.uri.toString();
      if (currentLoc.startsWith('/alarm')) {
        return;
      }

      if (payload.startsWith('reminder_id:')) {
        final remId = payload.substring('reminder_id:'.length);
        appRouter.push('/alarm?id=$remId');
      } else if (payload.startsWith('prayer:')) {
        final prayer = payload.substring('prayer:'.length);
        appRouter.push('/alarm?prayer=$prayer');
      }
    }
  });
  await notificationService.init();

  // Synchronize Quiet Hours & DND native alarms with system
  try {
    final quietHoursService = QuietHoursService();
    final dataList = storageService.getQuietHoursList();
    List<QuietHours> loaded = [];
    if (dataList != null && dataList.isNotEmpty) {
      loaded = dataList.map((e) => QuietHours.fromJson(e)).toList();
    } else {
      loaded = QuietHours.defaultSchedules();
    }
    await quietHoursService.syncQuietHoursList(loaded, storageService);
  } catch (e) {
    debugPrint('[main] Quiet Hours init sync error: $e');
  }

  // Check for Google Play In-App Updates in background
  AppUpdateService().checkForUpdate();

  // Initialize Supabase Service
  await SupabaseService().init();

  runApp(
    ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(storageService),
        adhkarAudioHandlerProvider.overrideWithValue(adhkarAudioHandler),
      ],
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
