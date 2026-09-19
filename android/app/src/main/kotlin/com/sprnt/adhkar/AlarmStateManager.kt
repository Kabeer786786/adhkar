package com.sprnt.adhkar

import android.app.NotificationManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.media.VolumeProvider
import android.media.session.MediaSession
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import java.util.concurrent.atomic.AtomicBoolean

/**
 * Centralized, thread-safe native coordinator for active alarm state,
 * hardware volume key interception via MediaSession, and Screen-Off event detection.
 */
object AlarmStateManager {
    const val TAG = "AdhkarAlarmStateMgr"

    private val isRinging = AtomicBoolean(false)
    private val mainHandler = Handler(Looper.getMainLooper())

    @Volatile
    private var currentAlarmData: Map<String, Any?>? = null

    private var mediaSession: MediaSession? = null
    private var screenOffReceiver: BroadcastReceiver? = null
    private var appContext: Context? = null

    fun isAlarmActive(): Boolean = isRinging.get()

    fun getCurrentAlarm(): Map<String, Any?>? = currentAlarmData

    @Synchronized
    fun onAlarmStarted(context: Context, data: Map<String, Any?>) {
        appContext = context.applicationContext
        currentAlarmData = data
        isRinging.set(true)

        val reminderId = data["reminder_id"] as? String ?: ""
        val title = data["alarm_title"] as? String ?: "Reminder"
        Log.i(TAG, "Active alarm started: id=$reminderId, title=$title")

        mainHandler.post {
            setupVolumeMediaSession(context)
            registerScreenOffReceiver(context)
        }
    }

    private fun setupVolumeMediaSession(context: Context) {
        val volumeAction = AlarmInteractionSettings.getVolumeButtonAction(context)
        if (volumeAction == VolumeButtonAction.DO_NOTHING) {
            Log.d(TAG, "Volume action is DO_NOTHING. Skipping MediaSession creation.")
            return
        }

        try {
            cleanupMediaSession()

            val session = MediaSession(context, "AdhkarAlarmVolumeSession")
            val volumeProvider = object : VolumeProvider(VOLUME_CONTROL_RELATIVE, 100, 50) {
                override fun onAdjustVolume(direction: Int) {
                    val currentAction = AlarmInteractionSettings.getVolumeButtonAction(context)
                    Log.i(TAG, "Volume button pressed via MediaSession: dir=$direction, action=$currentAction")
                    mainHandler.post {
                        when (currentAction) {
                            VolumeButtonAction.STOP_ALARM -> {
                                stopActiveAlarm(context, "VolumeButton")
                            }
                            VolumeButtonAction.SNOOZE_ALARM -> {
                                snoozeActiveAlarm(context, "VolumeButton")
                            }
                            VolumeButtonAction.DO_NOTHING -> {
                                // Do nothing
                            }
                        }
                    }
                }
            }

            val playbackState = android.media.session.PlaybackState.Builder()
                .setState(android.media.session.PlaybackState.STATE_PLAYING, 0L, 1.0f)
                .setActions(
                    android.media.session.PlaybackState.ACTION_PLAY or
                    android.media.session.PlaybackState.ACTION_STOP or
                    android.media.session.PlaybackState.ACTION_PAUSE
                )
                .build()
            session.setPlaybackState(playbackState)
            session.setPlaybackToRemote(volumeProvider)
            session.isActive = true
            mediaSession = session
            Log.i(TAG, "MediaSession activated for hardware volume button handling")
        } catch (e: Exception) {
            Log.w(TAG, "Unable to activate MediaSession for volume keys: ${e.message}")
        }
    }

    private fun cleanupMediaSession() {
        try {
            mediaSession?.isActive = false
            mediaSession?.release()
        } catch (_: Exception) {}
        mediaSession = null
    }

    private fun registerScreenOffReceiver(context: Context) {
        if (screenOffReceiver != null) return

        val receiver = object : BroadcastReceiver() {
            override fun onReceive(c: Context?, intent: Intent?) {
                if (intent?.action == Intent.ACTION_SCREEN_OFF) {
                    val screenOffAction = AlarmInteractionSettings.getScreenOffAction(context)
                    Log.i(TAG, "Screen-off broadcast received. Setting=$screenOffAction")
                    if (screenOffAction == ScreenOffAction.STOP_ALARM) {
                        stopActiveAlarm(context, "ScreenOff")
                    }
                }
            }
        }

        val filter = IntentFilter(Intent.ACTION_SCREEN_OFF)
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                context.applicationContext.registerReceiver(receiver, filter, Context.RECEIVER_EXPORTED)
            } else {
                context.applicationContext.registerReceiver(receiver, filter)
            }
            screenOffReceiver = receiver
            Log.i(TAG, "Screen-off receiver dynamically registered")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to register screen-off receiver: ${e.message}")
        }
    }

    private fun unregisterScreenOffReceiver(context: Context) {
        val receiver = screenOffReceiver ?: return
        try {
            context.applicationContext.unregisterReceiver(receiver)
            Log.i(TAG, "Screen-off receiver successfully unregistered")
        } catch (_: Exception) {
            // Safe ignore if already unregistered
        }
        screenOffReceiver = null
    }

    /**
     * Single centralized, idempotent function to stop any active alarm.
     * Prevents duplicate cleanup and ensures no orphaned audio, vibration, or notification.
     */
    @Synchronized
    fun stopActiveAlarm(context: Context, reason: String = "UserStop"): Boolean {
        if (!isRinging.compareAndSet(true, false)) {
            Log.d(TAG, "stopActiveAlarm called but alarm is not active or already stopped. Reason=$reason")
            return false
        }

        Log.i(TAG, "Stopping active alarm idempotently. Reason=$reason")
        val alarmData = currentAlarmData
        currentAlarmData = null

        mainHandler.post {
            cleanupMediaSession()
            unregisterScreenOffReceiver(context)
        }

        // Cancel notification associated with this alarm
        try {
            val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
            val notifId = (alarmData?.get("notif_id") as? Number)?.toInt() ?: 0
            if (notifId != 0) {
                nm?.cancel(notifId)
            } else {
                nm?.cancelAll()
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && nm != null) {
                try {
                    for (statusBarNotif in nm.activeNotifications) {
                        if (statusBarNotif.notification.channelId == AlarmReceiver.CHANNEL_ID ||
                            (notifId != 0 && statusBarNotif.id == notifId)) {
                            nm.cancel(statusBarNotif.tag, statusBarNotif.id)
                        }
                    }
                } catch (_: Exception) {}
            }
        } catch (e: Exception) {
            Log.w(TAG, "Error cancelling notification during stopActiveAlarm: ${e.message}")
        }

        // Synchronize state with Flutter engine if connected
        mainHandler.post {
            try {
                MainActivity.alarmMethodChannel?.invokeMethod(
                    "dismissAlarm",
                    mapOf("reason" to reason)
                )
            } catch (e: Exception) {
                Log.w(TAG, "Error invoking dismissAlarm on Flutter channel: ${e.message}")
            }
        }

        return true
    }

    /**
     * Reliable snooze workflow: stops current ringing, schedules exactly one snooze alarm,
     * preserves original recurring schedule, and informs Flutter.
     */
    @Synchronized
    fun snoozeActiveAlarm(context: Context, reason: String = "UserSnooze", minutes: Int = 10): Boolean {
        val activeData = currentAlarmData ?: return false
        val reminderId = activeData["reminder_id"] as? String ?: "snooze"
        val title = activeData["alarm_title"] as? String ?: "Reminder"
        val body = activeData["alarm_body"] as? String ?: "Snoozed reminder ringing now."
        val soundType = activeData["sound_type"] as? String ?: "Default Ringtone"
        val prayerName = activeData["prayer_name"] as? String
        val sound = (activeData["sound"] as? Boolean) ?: true
        val vibration = (activeData["vibration"] as? Boolean) ?: true

        // 1. Idempotently stop current ringing and dismiss notification
        stopActiveAlarm(context, reason)

        // 2. Schedule exactly one snooze alarm natively in AlarmManager
        val snoozeTrigger = System.currentTimeMillis() + minutes * 60 * 1000L
        AlarmScheduler.scheduleAlarm(
            context = context,
            id = "${reminderId}_snooze",
            title = "Snoozed: $title",
            body = body,
            triggerAtMillis = snoozeTrigger,
            sound = sound,
            vibration = vibration,
            soundType = soundType,
            prayerName = prayerName
        )
        Log.i(TAG, "Snoozed alarm for reminderId=$reminderId for $minutes minutes. Reason=$reason")

        // 3. Notify Flutter
        mainHandler.post {
            try {
                MainActivity.alarmMethodChannel?.invokeMethod(
                    "onAlarmSnoozed",
                    mapOf(
                        "reminder_id" to reminderId,
                        "minutes" to minutes,
                        "reason" to reason
                    )
                )
            } catch (_: Exception) {}
        }

        return true
    }
}
