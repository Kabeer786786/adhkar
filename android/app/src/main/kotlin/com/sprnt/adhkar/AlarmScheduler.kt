package com.sprnt.adhkar

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import android.util.Log
import org.json.JSONArray
import org.json.JSONObject

/**
 * Native Android Alarm Scheduling Engine.
 * Schedules exact RTC_WAKEUP alarms in AlarmManager for reminders and prayers.
 * Operates purely on the native Android OS side so alarms survive app kill and device reboots.
 */
object AlarmScheduler {
    const val TAG = "AdhkarAlarmScheduler"
    private const val PREFS_NAME = "adhkar_native_alarms_prefs"
    private const val KEY_ALARMS_JSON = "key_alarms_json"

    private fun getPrefs(context: Context): SharedPreferences {
        return context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    }

    private fun getRequestCode(id: String): Int {
        return (Math.abs(id.hashCode()) % 1000000) + 10000
    }

    @Synchronized
    fun scheduleAlarm(
        context: Context,
        id: String,
        title: String,
        body: String,
        triggerAtMillis: Long,
        sound: Boolean,
        vibration: Boolean,
        soundType: String,
        prayerName: String?
    ) {
        val now = System.currentTimeMillis()
        if (triggerAtMillis <= now) {
            Log.w(TAG, "Cannot schedule alarm in past: id=$id, triggerAtMillis=$triggerAtMillis, now=$now")
            return
        }

        val am = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager
        if (am == null) {
            Log.e(TAG, "AlarmManager service unavailable")
            return
        }

        val requestCode = getRequestCode(id)
        val intent = Intent(context, AlarmReceiver::class.java).apply {
            action = AlarmReceiver.ACTION_ALARM_TRIGGER
            putExtra("reminder_id", id)
            putExtra("alarm_title", title)
            putExtra("alarm_body", body)
            putExtra("sound", sound)
            putExtra("vibration", vibration)
            putExtra("sound_type", soundType)
            putExtra("prayer_name", prayerName)
        }

        // Cancel any existing pending alarm with the same request code for idempotency
        val existingPi = PendingIntent.getBroadcast(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE
        )
        if (existingPi != null) {
            am.cancel(existingPi)
            existingPi.cancel()
        }

        val pi = PendingIntent.getBroadcast(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                if (am.canScheduleExactAlarms()) {
                    am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAtMillis, pi)
                } else {
                    Log.w(TAG, "canScheduleExactAlarms=false on Android 12+. Using setAndAllowWhileIdle")
                    am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAtMillis, pi)
                }
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAtMillis, pi)
            } else {
                am.setExact(AlarmManager.RTC_WAKEUP, triggerAtMillis, pi)
            }

            // Save alarm to persistent storage for reboot recovery
            saveAlarmToStorage(context, id, title, body, triggerAtMillis, sound, vibration, soundType, prayerName)
            Log.i(TAG, "Scheduled native alarm: id=$id, title=$title, triggerAtMillis=$triggerAtMillis (rc=$requestCode)")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to schedule alarm: ${e.message}", e)
        }
    }

    @Synchronized
    fun cancelAlarm(context: Context, id: String) {
        val am = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
        val requestCode = getRequestCode(id)
        val intent = Intent(context, AlarmReceiver::class.java).apply {
            action = AlarmReceiver.ACTION_ALARM_TRIGGER
        }
        val pi = PendingIntent.getBroadcast(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE
        )
        if (pi != null) {
            am.cancel(pi)
            pi.cancel()
        }
        removeAlarmFromStorage(context, id)
        Log.i(TAG, "Cancelled native alarm id=$id (rc=$requestCode)")
    }

    @Synchronized
    fun cancelAllAlarms(context: Context) {
        val alarms = getSavedAlarms(context)
        for (i in 0 until alarms.length()) {
            val obj = alarms.optJSONObject(i) ?: continue
            val id = obj.optString("id")
            if (id.isNotEmpty()) {
                cancelAlarm(context, id)
            }
        }
        getPrefs(context).edit().remove(KEY_ALARMS_JSON).apply()
        Log.i(TAG, "Cancelled all native alarms")
    }

    @Synchronized
    fun rescheduleAll(context: Context) {
        val alarms = getSavedAlarms(context)
        val now = System.currentTimeMillis()
        Log.i(TAG, "Rescheduling ${alarms.length()} native alarms...")

        val updatedList = JSONArray()
        for (i in 0 until alarms.length()) {
            val obj = alarms.optJSONObject(i) ?: continue
            val id = obj.optString("id")
            val title = obj.optString("title")
            val body = obj.optString("body")
            val trigger = obj.optLong("triggerAtMillis")
            val sound = obj.optBoolean("sound", true)
            val vibration = obj.optBoolean("vibration", true)
            val soundType = obj.optString("soundType", "Default Ringtone")
            val prayer = if (obj.has("prayerName")) obj.optString("prayerName") else null

            if (trigger > now) {
                scheduleAlarm(context, id, title, body, trigger, sound, vibration, soundType, prayer)
                updatedList.put(obj)
            }
        }
        getPrefs(context).edit().putString(KEY_ALARMS_JSON, updatedList.toString()).apply()
    }

    private fun getSavedAlarms(context: Context): JSONArray {
        val jsonStr = getPrefs(context).getString(KEY_ALARMS_JSON, null) ?: return JSONArray()
        return try {
            JSONArray(jsonStr)
        } catch (e: Exception) {
            JSONArray()
        }
    }

    private fun saveAlarmToStorage(
        context: Context,
        id: String,
        title: String,
        body: String,
        triggerAtMillis: Long,
        sound: Boolean,
        vibration: Boolean,
        soundType: String,
        prayerName: String?
    ) {
        val alarms = getSavedAlarms(context)
        val filtered = JSONArray()
        for (i in 0 until alarms.length()) {
            val item = alarms.optJSONObject(i) ?: continue
            if (item.optString("id") != id) {
                filtered.put(item)
            }
        }
        val newObj = JSONObject().apply {
            put("id", id)
            put("title", title)
            put("body", body)
            put("triggerAtMillis", triggerAtMillis)
            put("sound", sound)
            put("vibration", vibration)
            put("soundType", soundType)
            if (prayerName != null) put("prayerName", prayerName)
        }
        filtered.put(newObj)
        getPrefs(context).edit().putString(KEY_ALARMS_JSON, filtered.toString()).apply()
    }

    private fun removeAlarmFromStorage(context: Context, id: String) {
        val alarms = getSavedAlarms(context)
        val filtered = JSONArray()
        for (i in 0 until alarms.length()) {
            val item = alarms.optJSONObject(i) ?: continue
            if (item.optString("id") != id) {
                filtered.put(item)
            }
        }
        getPrefs(context).edit().putString(KEY_ALARMS_JSON, filtered.toString()).apply()
    }
}
