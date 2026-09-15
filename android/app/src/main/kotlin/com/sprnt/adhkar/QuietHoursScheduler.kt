package com.sprnt.adhkar

import android.app.AlarmManager
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
import java.util.TimeZone

/**
 * Production-ready native Android Quiet Hours scheduling engine for Adhkar.
 *
 * Architecture:
 * AlarmManager -> QuietHoursReceiver -> DndScheduler -> NotificationManager
 *
 * Operates purely on the native Android OS side without requiring an active Flutter engine,
 * widget tree, foreground service, or Dart timers.
 */
object QuietHoursScheduler {
    const val TAG = "AdhkarQuietHours"
    private const val PREFS_NAME = "adhkar_quiet_hours_prefs"
    private const val KEY_SCHEDULES_JSON = "key_schedules_json"
    private const val KEY_SAVED_DND_FILTER = "key_saved_dnd_filter"
    private const val KEY_ADHKAR_OWNS_DND = "key_adhkar_owns_dnd"

    const val ACTION_START_QUIET_HOURS = "com.sprnt.adhkar.ACTION_START_QUIET_HOURS"
    const val ACTION_END_QUIET_HOURS = "com.sprnt.adhkar.ACTION_END_QUIET_HOURS"
    const val ACTION_SET_DND = "com.sprnt.adhkar.ACTION_SET_DND"
    const val EXTRA_SCHEDULE_ID = "extra_schedule_id"
    const val EXTRA_SCHEDULE_TITLE = "extra_schedule_title"

    private const val BASE_REQUEST_CODE = 91000

    private fun getPrefs(context: Context): SharedPreferences {
        return context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    }

    fun saveSchedules(context: Context, schedulesJson: String) {
        getPrefs(context).edit().putString(KEY_SCHEDULES_JSON, schedulesJson).apply()
        Log.d(TAG, "Saved schedules JSON (${schedulesJson.length} chars).")
    }

    fun getSchedules(context: Context): String? {
        return getPrefs(context).getString(KEY_SCHEDULES_JSON, null)
    }

    fun setSavedDndFilter(context: Context, filter: Int) {
        getPrefs(context).edit().putInt(KEY_SAVED_DND_FILTER, filter).apply()
        Log.d(TAG, "Saved pre-quiet-hours DND filter: $filter")
    }

    fun getSavedDndFilter(context: Context): Int {
        return getPrefs(context).getInt(KEY_SAVED_DND_FILTER, NotificationManager.INTERRUPTION_FILTER_ALL)
    }

    fun setAdhkarOwnsDnd(context: Context, owns: Boolean) {
        getPrefs(context).edit().putBoolean(KEY_ADHKAR_OWNS_DND, owns).apply()
        Log.d(TAG, "Set Adhkar DND ownership flag: $owns")
    }

    fun getAdhkarOwnsDnd(context: Context): Boolean {
        return getPrefs(context).getBoolean(KEY_ADHKAR_OWNS_DND, false)
    }

    /**
     * Check if the app currently has Do Not Disturb permission (Notification Policy Access).
     */
    fun hasDndPermission(context: Context): Boolean {
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager ?: return false
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            nm.isNotificationPolicyAccessGranted
        } else {
            true
        }
    }

    /**
     * Check if exact alarms capability is available on Android 12+ (API 31+).
     */
    fun canScheduleExactAlarms(context: Context): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val am = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager
            return am?.canScheduleExactAlarms() ?: true
        }
        return true
    }

    /**
     * Check if Battery Optimization is currently disabled (ignored) for the app.
     */
    fun isBatteryOptimizationIgnored(context: Context): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val pm = context.getSystemService(Context.POWER_SERVICE) as? PowerManager ?: return true
            return pm.isIgnoringBatteryOptimizations(context.packageName)
        }
        return true
    }

    /**
     * Enable or disable Do Not Disturb mode directly via DndScheduler.
     */
    fun applyDndMode(context: Context, enable: Boolean, customFilter: Int? = null) {
        DndScheduler.applyDndMode(context, enable, customFilter)
    }

    // =========================================================================
    // Schedule Calculations (Overnight & Multi-Schedule Safe)
    // =========================================================================

    fun isOvernight(startHour: Int, startMinute: Int, endHour: Int, endMinute: Int): Boolean {
        return (startHour > endHour) || (startHour == endHour && startMinute > endMinute)
    }

    /**
     * Checks whether [nowMillis] falls within the active scheduled window.
     * Weekdays follow Dart standard: 1=Mon, 2=Tue, 3=Wed, 4=Thu, 5=Fri, 6=Sat, 7=Sun.
     */
    fun isInsideSchedule(
        nowMillis: Long,
        startHour: Int,
        startMinute: Int,
        endHour: Int,
        endMinute: Int,
        repeatDaily: Boolean,
        weekdays: List<Int>,
        timeZone: TimeZone = TimeZone.getDefault()
    ): Boolean {
        if (startHour == endHour && startMinute == endMinute) {
            return false
        }

        val cal = Calendar.getInstance(timeZone).apply { timeInMillis = nowMillis }
        val nowMinutes = cal.get(Calendar.HOUR_OF_DAY) * 60 + cal.get(Calendar.MINUTE)
        val currentDartWeekday = toDartWeekday(cal.get(Calendar.DAY_OF_WEEK))

        val startMinutes = startHour * 60 + startMinute
        val endMinutes = endHour * 60 + endMinute
        val overnight = isOvernight(startHour, startMinute, endHour, endMinute)

        return if (!overnight) {
            if (!repeatDaily && !weekdays.contains(currentDartWeekday)) {
                false
            } else {
                nowMinutes in startMinutes until endMinutes
            }
        } else {
            if (nowMinutes >= startMinutes) {
                // Today's evening portion
                repeatDaily || weekdays.contains(currentDartWeekday)
            } else if (nowMinutes < endMinutes) {
                // Yesterday's overnight spillover morning portion
                val prevDartWeekday = if (currentDartWeekday == 1) 7 else currentDartWeekday - 1
                repeatDaily || weekdays.contains(prevDartWeekday)
            } else {
                false
            }
        }
    }

    /**
     * Calculates next start occurrence epoch millis strictly after [fromMillis].
     */
    fun calculateNextStartOccurrence(
        startHour: Int,
        startMinute: Int,
        repeatDaily: Boolean,
        weekdays: List<Int>,
        fromMillis: Long = System.currentTimeMillis(),
        timeZone: TimeZone = TimeZone.getDefault()
    ): Long {
        val candidate = Calendar.getInstance(timeZone).apply {
            timeInMillis = fromMillis
            set(Calendar.HOUR_OF_DAY, startHour)
            set(Calendar.MINUTE, startMinute)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }

        if (candidate.timeInMillis <= fromMillis) {
            candidate.add(Calendar.DAY_OF_YEAR, 1)
        }

        if (!repeatDaily && weekdays.isNotEmpty()) {
            var safetyCount = 0
            while (!weekdays.contains(toDartWeekday(candidate.get(Calendar.DAY_OF_WEEK))) && safetyCount < 14) {
                candidate.add(Calendar.DAY_OF_YEAR, 1)
                safetyCount++
            }
        }

        return candidate.timeInMillis
    }

    /**
     * Calculates the next end occurrence epoch millis strictly corresponding to
     * either the current active session or the next upcoming start session.
     *
     * CRITICAL FIX: For overnight schedules (e.g. 10 PM - 6 AM) repeating on Monday only:
     * - If active Monday evening or Tuesday morning: ends Tuesday 6 AM.
     * - If inactive: the end is paired with the next start (+1 calendar day).
     * This completely prevents the bug where the end was pushed to the following Monday!
     */
    fun calculateNextEndOccurrence(
        startHour: Int,
        startMinute: Int,
        endHour: Int,
        endMinute: Int,
        repeatDaily: Boolean,
        weekdays: List<Int>,
        fromMillis: Long = System.currentTimeMillis(),
        timeZone: TimeZone = TimeZone.getDefault()
    ): Long {
        val overnight = isOvernight(startHour, startMinute, endHour, endMinute)
        val currentlyInside = isInsideSchedule(
            nowMillis = fromMillis,
            startHour = startHour,
            startMinute = startMinute,
            endHour = endHour,
            endMinute = endMinute,
            repeatDaily = repeatDaily,
            weekdays = weekdays,
            timeZone = timeZone
        )

        if (currentlyInside) {
            // Case 1: Inside an ongoing active session. End is imminent for THIS session.
            val candidate = Calendar.getInstance(timeZone).apply {
                timeInMillis = fromMillis
                set(Calendar.HOUR_OF_DAY, endHour)
                set(Calendar.MINUTE, endMinute)
                set(Calendar.SECOND, 0)
                set(Calendar.MILLISECOND, 0)
            }

            if (!overnight) {
                return candidate.timeInMillis
            } else {
                val nowMinutes = Calendar.getInstance(timeZone).apply { timeInMillis = fromMillis }
                    .let { it.get(Calendar.HOUR_OF_DAY) * 60 + it.get(Calendar.MINUTE) }
                val startMinutes = startHour * 60 + startMinute

                if (nowMinutes >= startMinutes) {
                    // Evening portion: end is tomorrow morning
                    candidate.add(Calendar.DAY_OF_YEAR, 1)
                }
                // If nowMinutes < endMinutes: morning portion, candidate is already today morning
                return candidate.timeInMillis
            }
        } else {
            // Case 2: Inactive. Find next start occurrence and pair its corresponding end!
            val nextStartMillis = calculateNextStartOccurrence(
                startHour = startHour,
                startMinute = startMinute,
                repeatDaily = repeatDaily,
                weekdays = weekdays,
                fromMillis = fromMillis,
                timeZone = timeZone
            )

            val candidate = Calendar.getInstance(timeZone).apply {
                timeInMillis = nextStartMillis
                if (overnight) {
                    add(Calendar.DAY_OF_YEAR, 1) // Overnight end is on the calendar day after start
                }
                set(Calendar.HOUR_OF_DAY, endHour)
                set(Calendar.MINUTE, endMinute)
                set(Calendar.SECOND, 0)
                set(Calendar.MILLISECOND, 0)
            }

            return candidate.timeInMillis
        }
    }

    /**
     * Check if any other quiet hours schedule is active, optionally excluding one schedule id.
     */
    fun isAnyOtherQuietHoursActiveNow(
        context: Context,
        excludingScheduleId: String?,
        nowMillis: Long = System.currentTimeMillis()
    ): Boolean {
        val jsonStr = getSchedules(context) ?: return false
        return try {
            val arr = JSONArray(jsonStr)
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
                val repeatDaily = obj.optBoolean("repeatDaily", true)
                val weekdays = parseWeekdays(obj.optJSONArray("weekdays"))

                if (isInsideSchedule(nowMillis, startHour, startMinute, endHour, endMinute, repeatDaily, weekdays)) {
                    return true
                }
            }
            false
        } catch (e: Exception) {
            Log.e(TAG, "Error evaluating other active quiet hours: ${e.message}", e)
            false
        }
    }

    fun isAnyQuietHoursActiveNow(context: Context, nowMillis: Long = System.currentTimeMillis()): Boolean {
        return isAnyOtherQuietHoursActiveNow(context, null, nowMillis)
    }

    // =========================================================================
    // AlarmManager Scheduling
    // =========================================================================

    /**
     * Synchronize and schedule exact alarms in AlarmManager for all enabled schedules.
     */
    @Synchronized
    fun scheduleAll(context: Context, schedulesJson: String) {
        Log.i(TAG, "scheduleAll called with ${schedulesJson.length} characters of schedule data.")
        // Cancel previous alarms before overwriting schedules
        cancelAll(context)
        saveSchedules(context, schedulesJson)

        try {
            val arr = JSONArray(schedulesJson)
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager
            if (alarmManager == null) {
                Log.e(TAG, "AlarmManager system service unavailable.")
                return
            }

            val nowMillis = System.currentTimeMillis()

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
                val repeatDaily = obj.optBoolean("repeatDaily", true)
                val weekdays = parseWeekdays(obj.optJSONArray("weekdays"))

                // 1. Schedule Next Start
                val nextStartMillis = calculateNextStartOccurrence(
                    startHour = startHour,
                    startMinute = startMinute,
                    repeatDaily = repeatDaily,
                    weekdays = weekdays,
                    fromMillis = nowMillis
                )
                setExactAlarm(
                    context = context,
                    alarmManager = alarmManager,
                    triggerAtMillis = nextStartMillis,
                    action = ACTION_START_QUIET_HOURS,
                    scheduleId = scheduleId,
                    title = title,
                    requestCode = getStartRequestCode(scheduleId)
                )

                // 2. Schedule Next End
                val nextEndMillis = calculateNextEndOccurrence(
                    startHour = startHour,
                    startMinute = startMinute,
                    endHour = endHour,
                    endMinute = endMinute,
                    repeatDaily = repeatDaily,
                    weekdays = weekdays,
                    fromMillis = nowMillis
                )
                setExactAlarm(
                    context = context,
                    alarmManager = alarmManager,
                    triggerAtMillis = nextEndMillis,
                    action = ACTION_END_QUIET_HOURS,
                    scheduleId = scheduleId,
                    title = title,
                    requestCode = getEndRequestCode(scheduleId)
                )
            }

            // Immediately synchronize DND with current active state
            val shouldBeActive = isAnyQuietHoursActiveNow(context, nowMillis)
            Log.i(TAG, "Evaluated current active status: shouldBeActive=$shouldBeActive. Applying DND mode.")
            applyDndMode(context, shouldBeActive)

        } catch (e: Exception) {
            Log.e(TAG, "Error scheduling quiet hours alarms: ${e.message}", e)
        }
    }

    /**
     * Reschedule the next occurrence of start or end for a specific schedule after it fires.
     */
    @Synchronized
    fun rescheduleNextOccurrence(context: Context, scheduleId: String, isStart: Boolean) {
        val jsonStr = getSchedules(context) ?: return
        try {
            val arr = JSONArray(jsonStr)
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
            val nowMillis = System.currentTimeMillis()

            for (i in 0 until arr.length()) {
                val obj = arr.getJSONObject(i)
                if (obj.optString("id") != scheduleId) continue
                if (!obj.optBoolean("enabled", true)) continue

                val title = obj.optString("title", "Quiet Hours")
                val startHour = obj.optInt("startHour", 0)
                val startMinute = obj.optInt("startMinute", 0)
                val endHour = obj.optInt("endHour", 0)
                val endMinute = obj.optInt("endMinute", 0)
                val repeatDaily = obj.optBoolean("repeatDaily", true)
                val weekdays = parseWeekdays(obj.optJSONArray("weekdays"))

                val nextMillis = if (isStart) {
                    calculateNextStartOccurrence(startHour, startMinute, repeatDaily, weekdays, nowMillis)
                } else {
                    calculateNextEndOccurrence(startHour, startMinute, endHour, endMinute, repeatDaily, weekdays, nowMillis)
                }

                val action = if (isStart) ACTION_START_QUIET_HOURS else ACTION_END_QUIET_HOURS
                val requestCode = if (isStart) getStartRequestCode(scheduleId) else getEndRequestCode(scheduleId)
                setExactAlarm(context, alarmManager, nextMillis, action, scheduleId, title, requestCode)
                Log.i(TAG, "Re-armed next ${if (isStart) "start" else "end"} for $scheduleId at $nextMillis (rc=$requestCode)")
                break
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error rescheduling next occurrence for $scheduleId: ${e.message}", e)
        }
    }

    /**
     * Cancels all scheduled exact alarms for Quiet Hours.
     */
    @Synchronized
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
            Log.i(TAG, "Cancelled all previously armed AlarmManager alarms.")
        } catch (e: Exception) {
            Log.e(TAG, "Error canceling alarms: ${e.message}", e)
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

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                if (alarmManager.canScheduleExactAlarms()) {
                    alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAtMillis, pendingIntent)
                    Log.i(TAG, "Scheduled setExactAndAllowWhileIdle for $action ($title) at $triggerAtMillis (rc=$requestCode)")
                } else {
                    Log.w(TAG, "canScheduleExactAlarms=false on Android 12+. Using setAndAllowWhileIdle fallback for $action (rc=$requestCode)")
                    alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAtMillis, pendingIntent)
                }
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAtMillis, pendingIntent)
                Log.i(TAG, "Scheduled setExactAndAllowWhileIdle for $action ($title) at $triggerAtMillis (rc=$requestCode)")
            } else {
                alarmManager.setExact(AlarmManager.RTC_WAKEUP, triggerAtMillis, pendingIntent)
                Log.i(TAG, "Scheduled setExact for $action ($title) at $triggerAtMillis (rc=$requestCode)")
            }
        } catch (se: SecurityException) {
            Log.e(TAG, "SecurityException scheduling exact alarm for $action (rc=$requestCode): ${se.message}. Falling back to setAndAllowWhileIdle.")
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAtMillis, pendingIntent)
                } else {
                    alarmManager.set(AlarmManager.RTC_WAKEUP, triggerAtMillis, pendingIntent)
                }
            } catch (fallbackEx: Exception) {
                Log.e(TAG, "Fallback alarm scheduling also failed: ${fallbackEx.message}", fallbackEx)
            }
        } catch (e: Exception) {
            Log.e(TAG, "General exception scheduling alarm for $action (rc=$requestCode): ${e.message}", e)
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
            Log.d(TAG, "Cancelled alarm for $action (rc=$requestCode)")
        }
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

    fun getStartRequestCode(scheduleId: String): Int {
        return BASE_REQUEST_CODE + (Math.abs(scheduleId.hashCode()) % 4000) * 2
    }

    fun getEndRequestCode(scheduleId: String): Int {
        return getStartRequestCode(scheduleId) + 1
    }
}
