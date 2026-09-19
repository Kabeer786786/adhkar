package com.sprnt.adhkar

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.os.Build
import android.os.PowerManager
import android.util.Log
import androidx.core.app.NotificationCompat

/**
 * BroadcastReceiver triggered directly by AlarmManager when an exact alarm fires.
 * Operates independent of Flutter lifecycle and even if the app process was terminated.
 */
class AlarmReceiver : BroadcastReceiver() {
    companion object {
        const val TAG = "AdhkarAlarmReceiver"
        const val ACTION_ALARM_TRIGGER = "com.sprnt.adhkar.ACTION_ALARM_TRIGGER"
        const val ACTION_DISMISS_ALARM = "com.sprnt.adhkar.ACTION_DISMISS_ALARM"
        const val ACTION_SNOOZE_ALARM = "com.sprnt.adhkar.ACTION_SNOOZE_ALARM"
        const val CHANNEL_ID = "adhkar_native_alarm_channel_v4"
    }

    override fun onReceive(context: Context, intent: Intent?) {
        if (intent == null) return
        val action = intent.action ?: return

        if (action == ACTION_DISMISS_ALARM) {
            AlarmStateManager.stopActiveAlarm(context, "NotificationAction")
            return
        }

        if (action == ACTION_SNOOZE_ALARM) {
            AlarmStateManager.snoozeActiveAlarm(context, "NotificationAction", 10)
            return
        }

        if (action != ACTION_ALARM_TRIGGER) return

        val reminderId = intent.getStringExtra("reminder_id") ?: ""
        val title = intent.getStringExtra("alarm_title") ?: "Reminder"
        val body = intent.getStringExtra("alarm_body") ?: "It's time for your scheduled reminder."
        val soundType = intent.getStringExtra("sound_type") ?: "Default Ringtone"
        val prayerName = intent.getStringExtra("prayer_name")
        val sound = intent.getBooleanExtra("sound", true)
        val vibration = intent.getBooleanExtra("vibration", true)

        Log.i(TAG, "Native Alarm triggered: reminderId=$reminderId, title=$title, soundType=$soundType")

        // 1. Acquire WakeLock to turn on screen and guarantee CPU execution
        val pm = context.getSystemService(Context.POWER_SERVICE) as? PowerManager
        @Suppress("DEPRECATION")
        val wakeLock = pm?.newWakeLock(
            PowerManager.SCREEN_BRIGHT_WAKE_LOCK or PowerManager.ACQUIRE_CAUSES_WAKEUP or PowerManager.ON_AFTER_RELEASE,
            "Adhkar:AlarmWakeLock"
        )
        wakeLock?.acquire(25 * 1000L) // 25 seconds max timeout

        // Deterministic notification ID matching Flutter's generateNotificationId
        val notifId = Math.abs(reminderId.hashCode()) % 100000000

        // 2. Prepare Intent to launch MainActivity with alarm route data
        val activityIntent = Intent(context, MainActivity::class.java).apply {
            this.action = ACTION_ALARM_TRIGGER
            putExtra("reminder_id", reminderId)
            putExtra("prayer_name", prayerName)
            putExtra("alarm_title", title)
            putExtra("alarm_body", body)
            putExtra("sound_type", soundType)
            putExtra("notif_id", notifId)
            addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_CLEAR_TOP or
                Intent.FLAG_ACTIVITY_SINGLE_TOP or
                Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
            )
        }

        val fullScreenPendingIntent = PendingIntent.getActivity(
            context,
            notifId,
            activityIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // 3. Prepare Dismiss & Snooze Action Buttons for notification
        val dismissIntent = Intent(context, AlarmReceiver::class.java).apply {
            this.action = ACTION_DISMISS_ALARM
            putExtra("notif_id", notifId)
        }
        val dismissPendingIntent = PendingIntent.getBroadcast(
            context,
            notifId,
            dismissIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val snoozeIntent = Intent(context, AlarmReceiver::class.java).apply {
            this.action = ACTION_SNOOZE_ALARM
            putExtra("notif_id", notifId)
            putExtra("reminder_id", reminderId)
            putExtra("alarm_title", title)
            putExtra("alarm_body", body)
            putExtra("sound_type", soundType)
            putExtra("prayer_name", prayerName)
            putExtra("sound", sound)
            putExtra("vibration", vibration)
        }
        val snoozePendingIntent = PendingIntent.getBroadcast(
            context,
            notifId + 1,
            snoozeIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // 4. Create Alarm Notification Channel
        // Note: Sound is strictly null because audio is played exclusively by the AlarmScreen
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && nm != null) {
            try {
                nm.deleteNotificationChannel("adhkar_native_alarm_channel_v3")
            } catch (_: Exception) {}

            val channel = NotificationChannel(
                CHANNEL_ID,
                "Alarm Reminders",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Full screen alarms and Adhkar reminders"
                enableVibration(vibration)
                if (vibration) {
                    vibrationPattern = longArrayOf(0, 800, 400, 800, 400, 800)
                }
                // Strictly SILENT: The alarm audio is played exclusively by the AlarmScreen
                setSound(null, null)
                lockscreenVisibility = NotificationCompat.VISIBILITY_PUBLIC
                setBypassDnd(true)
            }
            nm.createNotificationChannel(channel)
        }

        // 5. Post high-priority notification with full-screen intent
        val builder = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(body)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setAutoCancel(true)
            .setSound(null)
            .setContentIntent(fullScreenPendingIntent)
            .setFullScreenIntent(fullScreenPendingIntent, true)
            .addAction(0, "Turn Off", dismissPendingIntent)
            .addAction(0, "Snooze (10m)", snoozePendingIntent)

        if (vibration) {
            builder.setVibrate(longArrayOf(0, 800, 400, 800, 400, 800))
        } else {
            builder.setVibrate(null)
        }

        nm?.notify(notifId, builder.build())

        // 6. Store pending alarm in MainActivity companion object and notify AlarmStateManager
        val alarmData = mapOf(
            "reminder_id" to reminderId,
            "prayer_name" to prayerName,
            "alarm_title" to title,
            "alarm_body" to body,
            "sound_type" to soundType,
            "notif_id" to notifId,
            "sound" to sound,
            "vibration" to vibration
        )
        MainActivity.pendingAlarmData = alarmData
        AlarmStateManager.onAlarmStarted(context, alarmData)
        MainActivity.alarmMethodChannel?.invokeMethod("onAlarmTriggered", alarmData)

        // 7. Directly launch Activity
        try {
            context.startActivity(activityIntent)
            Log.i(TAG, "Successfully invoked startActivity from AlarmReceiver")
        } catch (e: Exception) {
            Log.d(TAG, "Background activity launch held for Full-Screen Intent: ${e.message}")
        }
    }
}
