package com.sprnt.adhkar

import android.app.AlarmManager
import android.app.AutomaticZenRule
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import android.os.PowerManager
import android.util.Log
import org.json.JSONArray
import org.json.JSONObject
import java.util.Calendar

object QuietHoursScheduler {
    private const val TAG = "QuietHoursScheduler"
    private const val PREFS_NAME = "adhkar_quiet_hours_prefs"
    private const val KEY_SCHEDULES_JSON = "key_schedules_json"
    private const val KEY_SAVED_DND_FILTER = "key_saved_dnd_filter"
    private const val KEY_ADHKAR_OWNS_DND = "key_adhkar_owns_dnd"

    const val ACTION_START_QUIET_HOURS = "com.sprnt.adhkar.ACTION_START_QUIET_HOURS"
    const val ACTION_END_QUIET_HOURS = "com.sprnt.adhkar.ACTION_END_QUIET_HOURS"
    const val EXTRA_SCHEDULE_ID = "extra_schedule_id"
    const val EXTRA_SCHEDULE_TITLE = "extra_schedule_title"

    private fun getPrefs(context: Context): SharedPreferences {
        return context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    }

    fun saveSchedules(context: Context, schedulesJson: String) {
        getPrefs(context).edit().putString(KEY_SCHEDULES_JSON, schedulesJson).apply()
    }

    fun getSchedules(context: Context): String? {
        return getPrefs(context).getString(KEY_SCHEDULES_JSON, null)
    }

    fun setSavedDndFilter(context: Context, filter: Int) {
        getPrefs(context).edit().putInt(KEY_SAVED_DND_FILTER, filter).apply()
    }

    fun getSavedDndFilter(context: Context): Int {
        return getPrefs(context).getInt(KEY_SAVED_DND_FILTER, NotificationManager.INTERRUPTION_FILTER_ALL)
    }

    fun setAdhkarOwnsDnd(context: Context, owns: Boolean) {
        getPrefs(context).edit().putBoolean(KEY_ADHKAR_OWNS_DND, owns).apply()
    }

    fun getAdhkarOwnsDnd(context: Context): Boolean {
        return getPrefs(context).getBoolean(KEY_ADHKAR_OWNS_DND, false)
    }

    /**
     * Check if the app currently has Do Not Disturb permission (Notification Policy Access).
     */
    fun hasDndPermission(context: Context): Boolean {
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager ?: return false
        return nm.isNotificationPolicyAccessGranted
    }

    /**
     * Check if Battery Optimization is currently disabled (ignored) for the app.
     * When disabled, Android power saving mode will NOT kill background alarms or receivers.
     */
    fun isBatteryOptimizationIgnored(context: Context): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val pm = context.getSystemService(Context.POWER_SERVICE) as? PowerManager ?: return true
            return pm.isIgnoringBatteryOptimizations(context.packageName)
        }
        return true
    }

    /**
     * Clean up any old AutomaticZenRule entries previously registered in Android system settings.
     * Real background DND execution is handled directly and reliably via AlarmManager + QuietHoursReceiver.
     */
    fun cleanupAutomaticZenRules(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) return
        try {
            val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager ?: return
            if (!nm.isNotificationPolicyAccessGranted) return

            val existingRules = nm.automaticZenRules ?: emptyMap<String, AutomaticZenRule>()
            for ((ruleId, rule) in existingRules) {
                if (rule.name != null && rule.name.startsWith("Adhkar - ")) {
                    try {
                        nm.removeAutomaticZenRule(ruleId)
                        Log.d(TAG, "Removed obsolete AutomaticZenRule: $ruleId (${rule.name})")
                    } catch (e: Exception) {
                        Log.e(TAG, "Error removing old rule $ruleId", e)
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error cleaning up AutomaticZenRules", e)
        }
    }

    /**
     * Enable or disable Do Not Disturb mode directly via DndScheduler.
     * Respects prior DND state and ownership policy.
     */
    fun applyDndMode(context: Context, enable: Boolean) {
        DndScheduler.applyDndMode(context, enable)
    }

    /**
     * Check if any other quiet hours schedule is active, optionally excluding one schedule id.
     */
    fun isAnyOtherQuietHoursActiveNow(context: Context, excludingScheduleId: String?): Boolean {
        val jsonStr = getSchedules(context) ?: return false
        return try {
            val arr = JSONArray(jsonStr)
            val now = Calendar.getInstance()
            val nowMinutes = now.get(Calendar.HOUR_OF_DAY) * 60 + now.get(Calendar.MINUTE)
            val currentDayOfWeek = toDartWeekday(now.get(Calendar.DAY_OF_WEEK))

            for (i in 0 until arr.length()) {
                val obj = arr.getJSONObject(i)
                val scheduleId = obj.optString("id", "quiet_$i")
                if (excludingScheduleId != null && scheduleId == excludingScheduleId) {
                    continue
                }

                val enabled = obj.optBoolean("enabled", true)
                if (!enabled) continue

                val startHour = obj.optInt("startHour", 0)
                val startMinute = obj.optInt("startMinute", 0)
                val endHour = obj.optInt("endHour", 0)
                val endMinute = obj.optInt("endMinute", 0)
                val startMinutes = startHour * 60 + startMinute
                val endMinutes = endHour * 60 + endMinute

                val weekdays = parseWeekdays(obj.optJSONArray("weekdays"))
                val repeatDaily = obj.optBoolean("repeatDaily", true)
                val isOvernight = (startHour > endHour) || (startHour == endHour && startMinute > endMinute)

                if (!isOvernight) {
                    if (!repeatDaily && !weekdays.contains(currentDayOfWeek)) continue
                    if (nowMinutes in startMinutes until endMinutes) return true
                } else {
                    if (nowMinutes >= startMinutes) {
                        if (!repeatDaily && !weekdays.contains(currentDayOfWeek)) continue
                        return true
                    } else if (nowMinutes < endMinutes) {
                        val prevDay = if (currentDayOfWeek == 1) 7 else currentDayOfWeek - 1
                        if (!repeatDaily && !weekdays.contains(prevDay)) continue
                        return true
                    }
                }
            }
            false
        } catch (e: Exception) {
            Log.e(TAG, "Error evaluating other active quiet hours", e)
            false
        }
    }

    fun isAnyQuietHoursActiveNow(context: Context): Boolean {
        return isAnyOtherQuietHoursActiveNow(context, null)
    }

    /**
     * Synchronize and schedule exact alarms in AlarmManager for all enabled schedules.
     */
    fun scheduleAll(context: Context, schedulesJson: String) {
        // CRITICAL FIX: Cancel old alarms using the previous saved schedules BEFORE overwriting KEY_SCHEDULES_JSON!
        cancelAll(context)
        saveSchedules(context, schedulesJson)
        cleanupAutomaticZenRules(context)

        try {
            val arr = JSONArray(schedulesJson)
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return

            for (i in 0 until arr.length()) {
                val obj = arr.getJSONObject(i)
                val enabled = obj.optBoolean("enabled", true)
                if (!enabled) continue

                val scheduleId = obj.optString("id", "quiet_$i")
                val title = obj.optString("title", "Quiet Hours")
                val startHour = obj.optInt("startHour", 0)
                val startMinute = obj.optInt("startMinute", 0)
                val endHour = obj.optInt("endHour", 0)
                val endMinute = obj.optInt("endMinute", 0)
                val weekdays = parseWeekdays(obj.optJSONArray("weekdays"))
                val repeatDaily = obj.optBoolean("repeatDaily", true)

                // Schedule Next Start
                val nextStartMillis = calculateNextStartOccurrence(
                    startHour = startHour,
                    startMinute = startMinute,
                    endHour = endHour,
                    endMinute = endMinute,
                    repeatDaily = repeatDaily,
                    weekdays = weekdays
                )
                setExactAlarm(context, alarmManager, nextStartMillis, ACTION_START_QUIET_HOURS, scheduleId, title, getStartRequestCode(scheduleId))

                // Schedule Next End
                val nextEndMillis = calculateNextEndOccurrence(
                    startHour = startHour,
                    startMinute = startMinute,
                    endHour = endHour,
                    endMinute = endMinute,
                    repeatDaily = repeatDaily,
                    weekdays = weekdays
                )
                setExactAlarm(context, alarmManager, nextEndMillis, ACTION_END_QUIET_HOURS, scheduleId, title, getEndRequestCode(scheduleId))
            }

            // Evaluate if currently inside an active period
            val shouldBeActive = isAnyQuietHoursActiveNow(context)
            applyDndMode(context, shouldBeActive)

        } catch (e: Exception) {
            Log.e(TAG, "Error scheduling quiet hours alarms", e)
        }
    }

    /**
     * Reschedule the next occurrence of start or end for a specific schedule after it fires.
     */
    fun rescheduleNextOccurrence(context: Context, scheduleId: String, isStart: Boolean) {
        val jsonStr = getSchedules(context) ?: return
        try {
            val arr = JSONArray(jsonStr)
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return

            for (i in 0 until arr.length()) {
                val obj = arr.getJSONObject(i)
                if (obj.optString("id") != scheduleId) continue
                if (!obj.optBoolean("enabled", true)) continue

                val title = obj.optString("title", "Quiet Hours")
                val startHour = obj.optInt("startHour", 0)
                val startMinute = obj.optInt("startMinute", 0)
                val endHour = obj.optInt("endHour", 0)
                val endMinute = obj.optInt("endMinute", 0)
                val weekdays = parseWeekdays(obj.optJSONArray("weekdays"))
                val repeatDaily = obj.optBoolean("repeatDaily", true)

                val nextMillis = if (isStart) {
                    calculateNextStartOccurrence(startHour, startMinute, endHour, endMinute, repeatDaily, weekdays)
                } else {
                    calculateNextEndOccurrence(startHour, startMinute, endHour, endMinute, repeatDaily, weekdays)
                }

                val action = if (isStart) ACTION_START_QUIET_HOURS else ACTION_END_QUIET_HOURS
                val requestCode = if (isStart) getStartRequestCode(scheduleId) else getEndRequestCode(scheduleId)
                setExactAlarm(context, alarmManager, nextMillis, action, scheduleId, title, requestCode)
                break
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error rescheduling next occurrence for $scheduleId", e)
        }
    }

    /**
     * Cancels all scheduled exact alarms for Quiet Hours.
     */
    fun cancelAll(context: Context) {
        val jsonStr = getSchedules(context) ?: return
        try {
            val arr = JSONArray(jsonStr)
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return

            for (i in 0 until arr.length()) {
                val obj = arr.getJSONObject(i)
                val scheduleId = obj.optString("id", "quiet_$i")
                cancelAlarm(context, alarmManager, ACTION_START_QUIET_HOURS, getStartRequestCode(scheduleId))
                cancelAlarm(context, alarmManager, ACTION_END_QUIET_HOURS, getEndRequestCode(scheduleId))
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error canceling alarms", e)
        }
    }

    private fun setExactAlarm(
        context: Context,
        alarmManager: AlarmManager,
        triggerAtMillis: Long,
        action: String,
        scheduleId: String,
        title: String,
        requestCode: Int
    ) {
        val intent = Intent(context, QuietHoursReceiver::class.java).apply {
            this.action = action
            putExtra(EXTRA_SCHEDULE_ID, scheduleId)
            putExtra(EXTRA_SCHEDULE_TITLE, title)
        }
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        val pendingIntent = PendingIntent.getBroadcast(context, requestCode, intent, flags)

        val showIntent = Intent(context, MainActivity::class.java).apply {
            this.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val showPendingIntent = PendingIntent.getActivity(
            context,
            requestCode + 50000,
            showIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                // Use AlarmClockInfo: highest priority in Android OS, immune to Doze mode and task killing
                val alarmClockInfo = AlarmManager.AlarmClockInfo(triggerAtMillis, showPendingIntent)
                alarmManager.setAlarmClock(alarmClockInfo, pendingIntent)
                Log.d(TAG, "Armed setAlarmClock for $action ($title) at $triggerAtMillis (rc=$requestCode)")
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAtMillis, pendingIntent)
            } else {
                alarmManager.setExact(AlarmManager.RTC_WAKEUP, triggerAtMillis, pendingIntent)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Fallback to setExactAndAllowWhileIdle due to: ${e.message}")
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAtMillis, pendingIntent)
                } else {
                    alarmManager.setExact(AlarmManager.RTC_WAKEUP, triggerAtMillis, pendingIntent)
                }
            } catch (e2: Exception) {
                Log.e(TAG, "Failed to schedule exact alarm: ${e2.message}")
            }
        }
    }

    private fun cancelAlarm(context: Context, alarmManager: AlarmManager, action: String, requestCode: Int) {
        val intent = Intent(context, QuietHoursReceiver::class.java).apply {
            this.action = action
        }
        val flags = PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE
        val pendingIntent = PendingIntent.getBroadcast(context, requestCode, intent, flags)
        if (pendingIntent != null) {
            alarmManager.cancel(pendingIntent)
            pendingIntent.cancel()
        }
    }

    fun calculateNextStartOccurrence(
        startHour: Int,
        startMinute: Int,
        endHour: Int,
        endMinute: Int,
        repeatDaily: Boolean,
        weekdays: List<Int>
    ): Long {
        val now = Calendar.getInstance()
        val candidate = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, startHour)
            set(Calendar.MINUTE, startMinute)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }

        // If start time has already passed today, advance to tomorrow
        if (candidate.timeInMillis <= now.timeInMillis) {
            candidate.add(Calendar.DAY_OF_YEAR, 1)
        }

        if (!repeatDaily && weekdays.isNotEmpty()) {
            while (!weekdays.contains(toDartWeekday(candidate.get(Calendar.DAY_OF_WEEK)))) {
                candidate.add(Calendar.DAY_OF_YEAR, 1)
            }
        }

        return candidate.timeInMillis
    }

    fun calculateNextEndOccurrence(
        startHour: Int,
        startMinute: Int,
        endHour: Int,
        endMinute: Int,
        repeatDaily: Boolean,
        weekdays: List<Int>
    ): Long {
        val now = Calendar.getInstance()
        val isOvernight = (startHour > endHour) || (startHour == endHour && startMinute > endMinute)
        val nowMinutes = now.get(Calendar.HOUR_OF_DAY) * 60 + now.get(Calendar.MINUTE)
        val startMinutes = startHour * 60 + startMinute
        val endMinutes = endHour * 60 + endMinute

        val candidate = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, endHour)
            set(Calendar.MINUTE, endMinute)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }

        if (!isOvernight) {
            if (candidate.timeInMillis <= now.timeInMillis) {
                candidate.add(Calendar.DAY_OF_YEAR, 1)
            }
        } else {
            if (nowMinutes >= startMinutes) {
                // Evening portion: end is tomorrow morning
                candidate.add(Calendar.DAY_OF_YEAR, 1)
            } else if (candidate.timeInMillis <= now.timeInMillis) {
                candidate.add(Calendar.DAY_OF_YEAR, 1)
            }
        }

        if (!repeatDaily && weekdays.isNotEmpty()) {
            while (!weekdays.contains(toDartWeekday(candidate.get(Calendar.DAY_OF_WEEK)))) {
                candidate.add(Calendar.DAY_OF_YEAR, 1)
            }
        }

        return candidate.timeInMillis
    }

    private fun parseWeekdays(arr: JSONArray?): List<Int> {
        if (arr == null) return listOf(1, 2, 3, 4, 5, 6, 7)
        val list = mutableListOf<Int>()
        for (i in 0 until arr.length()) {
            list.add(arr.getInt(i))
        }
        return if (list.isEmpty()) listOf(1, 2, 3, 4, 5, 6, 7) else list
    }

    private fun toDartWeekday(calendarDayOfWeek: Int): Int {
        return when (calendarDayOfWeek) {
            Calendar.MONDAY -> 1
            Calendar.TUESDAY -> 2
            Calendar.WEDNESDAY -> 3
            Calendar.THURSDAY -> 4
            Calendar.FRIDAY -> 5
            Calendar.SATURDAY -> 6
            Calendar.SUNDAY -> 7
            else -> 1
        }
    }

    private fun toCalendarDay(dartWeekday: Int): Int {
        return when (dartWeekday) {
            1 -> Calendar.MONDAY
            2 -> Calendar.TUESDAY
            3 -> Calendar.WEDNESDAY
            4 -> Calendar.THURSDAY
            5 -> Calendar.FRIDAY
            6 -> Calendar.SATURDAY
            7 -> Calendar.SUNDAY
            else -> Calendar.MONDAY
        }
    }

    private fun getStartRequestCode(scheduleId: String): Int {
        return 91000 + (Math.abs(scheduleId.hashCode()) % 4000) * 2
    }

    private fun getEndRequestCode(scheduleId: String): Int {
        return getStartRequestCode(scheduleId) + 1
    }
}
