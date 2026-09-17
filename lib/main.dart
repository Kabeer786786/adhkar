import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audio_service/audio_service.dart';
import 'package:showcaseview/showcaseview.dart';
import 'config/routes/app_router.dart';
import 'core/services/adhkar_audio_handler.dart';
import 'core/services/alarm_audio_service.dart';
import 'core/services/app_update_service.dart';
import 'core/services/native_alarm_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/showcase_service.dart';
import 'core/services/storage_service.dart';
import 'core/services/supabase_service.dart';
import 'core/theme/app_theme.dart';
import 'features/quiet_hours/domain/quiet_hours_model.dart';
import 'features/quiet_hours/services/quiet_hours_service.dart';
import 'features/reminder/presentation/providers/reminder_provider.dart';
import 'shared/providers/app_providers.dart';

void _handleAlarmPayloadNavigation(String payload) {
  if (payload.startsWith('dismiss:')) {
    AlarmAudioService().stopAlarm();
    return;
  }

  String targetUrl = '';
  if (payload.startsWith('reminder_id:')) {
    final remId = payload.substring('reminder_id:'.length);
    targetUrl = '/alarm?id=$remId';
  } else if (payload.startsWith('prayer:')) {
    final prayer = payload.substring('prayer:'.length);
    targetUrl = '/alarm?prayer=$prayer';
  }

  if (targetUrl.isEmpty) return;

  final currentLoc = appRouter.routerDelegate.currentConfiguration.uri.toString();
  if (currentLoc == targetUrl || currentLoc.startsWith('/alarm')) {
    return;
  }

  // If at root or splash, use go to cleanly transition, otherwise push
  if (currentLoc == '/' || currentLoc.isEmpty || currentLoc == '/splash') {
    appRouter.go(targetUrl);
  } else {
    appRouter.push(targetUrl);
  }
}

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
      _handleAlarmPayloadNavigation(payload);
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

  // Note: App update check is now done inside AdhkarApp widget
  // so we have a valid BuildContext for the custom bottom sheet.

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

class AdhkarApp extends ConsumerStatefulWidget {
  const AdhkarApp({super.key});

  @override
  ConsumerState<AdhkarApp> createState() => _AdhkarAppState();
}

class _AdhkarAppState extends ConsumerState<AdhkarApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // 1. If cold-started from native Android alarm receiver, navigate immediately
      final pendingNative = await NativeAlarmService.instance.getPendingAlarm();
      if (pendingNative != null) {
        final remId = pendingNative['reminder_id'] as String?;
        final prayer = pendingNative['prayer_name'] as String?;
        if (remId != null && remId.isNotEmpty) {
          _handleAlarmPayloadNavigation('reminder_id:$remId');
          return;
        } else if (prayer != null && prayer.isNotEmpty) {
          _handleAlarmPayloadNavigation('prayer:$prayer');
          return;
        }
      }

      // 2. If cold-started from full-screen alarm notification, navigate immediately
      final pendingPayload = NotificationService.consumePendingAlarmPayload();
      if (pendingPayload != null && pendingPayload.isNotEmpty) {
        _handleAlarmPayloadNavigation(pendingPayload);
        return;
      }
      // 3. Check for Google Play updates
      _checkForAppUpdate();
    });
  }

  Future<void> _checkForAppUpdate() async {
    // Wait a moment for the app UI to settle after startup
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      await AppUpdateService().checkAndShowGooglePlayUpdate();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Eagerly initialize reminders so that rescheduleAll() runs on every app
    // start, ensuring background notification alarms survive app kill / reboot.
    ref.read(remindersProvider);

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
