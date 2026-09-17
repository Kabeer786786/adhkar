package com.sprnt.adhkar

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.PowerManager
import android.util.Log
import androidx.core.app.NotificationCompat

/**
 * BroadcastReceiver triggered directly by AlarmManager when an exact alarm fires.
 * Operates independent of Flutter lifecycle and even if the app was swiped from recent tasks.
 */
class AlarmReceiver : BroadcastReceiver() {
    companion object {
        const val TAG = "AdhkarAlarmReceiver"
        const val ACTION_ALARM_TRIGGER = "com.sprnt.adhkar.ACTION_ALARM_TRIGGER"
        const val ACTION_DISMISS_ALARM = "com.sprnt.adhkar.ACTION_DISMISS_ALARM"
        const val CHANNEL_ID = "adhkar_native_alarm_channel_v2"
    }

    override fun onReceive(context: Context, intent: Intent?) {
        if (intent == null) return
        val action = intent.action ?: return

        if (action == ACTION_DISMISS_ALARM) {
            val notifId = intent.getIntExtra("notif_id", 0)
            val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
            if (notifId != 0) {
                nm?.cancel(notifId)
            } else {
                nm?.cancelAll()
            }
            MainActivity.alarmMethodChannel?.invokeMethod("dismissAlarm", null)
            return
        }

        if (action != ACTION_ALARM_TRIGGER) return

        val reminderId = intent.getStringExtra("reminder_id") ?: ""
        val title = intent.getStringExtra("alarm_title") ?: "Reminder"
        val body = intent.getStringExtra("alarm_body") ?: "It's time for your scheduled reminder."
        val soundType = intent.getStringExtra("sound_type") ?: "Default Ringtone"
        val prayerName = intent.getStringExtra("prayer_name")
        val vibration = intent.getBooleanExtra("vibration", true)

        Log.i(TAG, "Native Alarm triggered: reminderId=$reminderId, title=$title, soundType=$soundType")

        // 1. Acquire WakeLock to turn on screen and guarantee CPU execution
        val pm = context.getSystemService(Context.POWER_SERVICE) as? PowerManager
        @Suppress("DEPRECATION")
        val wakeLock = pm?.newWakeLock(
            PowerManager.SCREEN_BRIGHT_WAKE_LOCK or PowerManager.ACQUIRE_CAUSES_WAKEUP or PowerManager.ON_AFTER_RELEASE,
            "Adhkar:AlarmWakeLock"
        )
        wakeLock?.acquire(30 * 1000L) // 30 seconds max timeout

        // 2. Prepare Intent to launch MainActivity with alarm route data
        val activityIntent = Intent(context, MainActivity::class.java).apply {
            this.action = ACTION_ALARM_TRIGGER
            putExtra("reminder_id", reminderId)
            putExtra("prayer_name", prayerName)
            putExtra("alarm_title", title)
            putExtra("alarm_body", body)
            putExtra("sound_type", soundType)
            addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_CLEAR_TOP or
                Intent.FLAG_ACTIVITY_SINGLE_TOP or
                Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
            )
        }

        val fullScreenPendingIntent = PendingIntent.getActivity(
            context,
            reminderId.hashCode(),
            activityIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notifId = (Math.abs(reminderId.hashCode()) % 1000000) + 20000

        // 3. Prepare Dismiss Action Button
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

        // 4. Create Notification Channel if not present
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && nm != null) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Alarm Reminders",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Full screen alarms and Adhkar reminders"
                enableVibration(vibration)
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
            .setContentIntent(fullScreenPendingIntent)
            .setFullScreenIntent(fullScreenPendingIntent, true)
            .addAction(0, "Turn Off", dismissPendingIntent)

        if (vibration) {
            builder.setVibrate(longArrayOf(0, 1000, 500, 1000, 500, 1000))
        }

        nm?.notify(notifId, builder.build())

        // 6. Store pending alarm in MainActivity companion object
        val alarmData = mapOf(
            "reminder_id" to reminderId,
            "prayer_name" to prayerName,
            "alarm_title" to title,
            "alarm_body" to body,
            "sound_type" to soundType
        )
        MainActivity.pendingAlarmData = alarmData
        MainActivity.alarmMethodChannel?.invokeMethod("onAlarmTriggered", alarmData)

        // 7. Explicitly start MainActivity to bring AlarmScreen up immediately
        try {
            context.startActivity(activityIntent)
            Log.i(TAG, "Successfully started MainActivity from AlarmReceiver")
        } catch (e: Exception) {
            Log.e(TAG, "Error starting MainActivity from background: ${e.message}", e)
        }
    }
}
