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

void _handleAlarmPayloadNavigation(String payload, {String? title, String? sound, int? notifId}) {
  if (payload.startsWith('dismiss:')) {
    AlarmAudioService().stopAlarm();
    return;
  }

  String targetUrl = '';
  if (payload.startsWith('reminder_id:')) {
    final remId = payload.substring('reminder_id:'.length);
    final params = <String, String>{'id': remId};
    if (title != null && title.isNotEmpty) params['title'] = title;
    if (sound != null && sound.isNotEmpty) params['sound'] = sound;
    if (notifId != null && notifId != 0) params['notif_id'] = notifId.toString();
    targetUrl = '/alarm?${Uri(queryParameters: params).query}';
  } else if (payload.startsWith('prayer:')) {
    final prayer = payload.substring('prayer:'.length);
    final params = <String, String>{'prayer': prayer};
    if (title != null && title.isNotEmpty) params['title'] = title;
    if (sound != null && sound.isNotEmpty) params['sound'] = sound;
    if (notifId != null && notifId != 0) params['notif_id'] = notifId.toString();
    targetUrl = '/alarm?${Uri(queryParameters: params).query}';
  }

  if (targetUrl.isEmpty) return;

  final currentLoc = appRouter.routerDelegate.currentConfiguration.uri.toString();
  if (currentLoc == targetUrl) {
    return;
  }
  if (currentLoc.startsWith('/alarm')) {
    appRouter.go(targetUrl);
    return;
  }

  // If at root or splash, use go to cleanly transition, otherwise push
  if (currentLoc == '/' || currentLoc.isEmpty || currentLoc == '/splash') {
    appRouter.go(targetUrl);
  } else {
    appRouter.push(targetUrl);
  }
}

String? _pendingAudioRoute;

/// Consume and clear any pending audio route registered before the router was mounted.
String? consumePendingAudioRoute() {
  final route = _pendingAudioRoute;
  _pendingAudioRoute = null;
  return route;
}

int _lastAudioNotifClickTime = 0;

void _handleAudioNotificationClicked(AdhkarAudioHandler handler) {
  final now = DateTime.now().millisecondsSinceEpoch;
  // Debounce rapid duplicate click events from Android notification bar
  if (now - _lastAudioNotifClickTime < 1000) return;
  _lastAudioNotifClickTime = now;

  try {
    final tag = handler.player.sequenceState?.currentSource?.tag;
    final media = handler.mediaItem.value ?? (tag is MediaItem ? tag : null);

    String? targetRoute = media?.extras?['route'] as String?;

    if (targetRoute == null || targetRoute.isEmpty) {
      final mediaId = media?.id ?? '';
      final type = media?.extras?['type'] as String? ?? '';

      if (type == 'quran' || mediaId.startsWith('quran_')) {
        final parts = mediaId.split('_');
        final surahNum = (parts.length > 1 && int.tryParse(parts[1]) != null)
            ? parts[1]
            : '1';
        targetRoute = '/quran/surah?num=$surahNum&name=Surah%20$surahNum';
      } else if (type == 'asma' ||
          mediaId.startsWith('asma') ||
          (media?.album?.contains('Asma') ?? false)) {
        targetRoute = '/asma-ul-husna';
      } else if (type == 'dua' || mediaId.startsWith('dua_')) {
        final duaId = mediaId.startsWith('dua_') ? mediaId.substring(4) : '';
        targetRoute = duaId.isNotEmpty ? '/dua/detail?id=$duaId' : '/dua';
      }
    }

    if (targetRoute == null || targetRoute.isEmpty) {
      return;
    }

    // If the navigator / router is not yet mounted (e.g. app cold-starting from notification click),
    // save the pending route so SplashScreen can navigate directly to it once ready.
    final navState = rootNavigatorKey.currentState;
    if (navState == null || !navState.mounted) {
      _pendingAudioRoute = targetRoute;
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final currentLoc =
            appRouter.routerDelegate.currentConfiguration.uri.toString();

        if (currentLoc == targetRoute) {
          return;
        }
        if (targetRoute!.contains('?')) {
          final targetUri = Uri.parse(targetRoute);
          final currentUri = Uri.parse(currentLoc);
          if (targetUri.path == currentUri.path) {
            if (targetUri.path == '/quran/surah') {
              if (targetUri.queryParameters['num'] ==
                  currentUri.queryParameters['num']) {
                return;
              }
            } else if (targetUri.path == '/dua/detail') {
              if (targetUri.queryParameters['id'] ==
                  currentUri.queryParameters['id']) {
                return;
              }
            } else {
              return;
            }
          }
        }

        // If at root or splash, use go to cleanly transition, otherwise push
        if (currentLoc == '/' || currentLoc.isEmpty || currentLoc == '/splash') {
          appRouter.go(targetRoute);
        } else {
          appRouter.push(targetRoute);
        }
      } catch (e) {
        debugPrint('[main] PostFrameCallback navigation error: $e');
      }
    });
  } catch (e) {
    debugPrint('[main] Audio notification click handling error: $e');
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
      androidStopForegroundOnPause: true,
    ),
  );

  // Directly navigate to playing audio screen (Quran, Asma-ul-Husna, Dua) when notification is clicked
  AudioService.notificationClicked.listen((clicked) {
    if (clicked) {
      _handleAudioNotificationClicked(adhkarAudioHandler);
    }
  });

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
        final title = pendingNative['alarm_title'] as String?;
        final sound = pendingNative['sound_type'] as String?;
        final notifId = (pendingNative['notif_id'] as num?)?.toInt();
        if (remId != null && remId.isNotEmpty) {
          _handleAlarmPayloadNavigation('reminder_id:$remId', title: title, sound: sound, notifId: notifId);
          return;
        } else if (prayer != null && prayer.isNotEmpty) {
          _handleAlarmPayloadNavigation('prayer:$prayer', title: title, sound: sound, notifId: notifId);
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

    final themeModeStr = ref.watch(themeModeProvider);
    final themeMode = themeModeStr == 'dark' ? ThemeMode.dark : ThemeMode.light;

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
