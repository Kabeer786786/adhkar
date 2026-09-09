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
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale
import java.util.TimeZone

/**
 * Native Android DND Scheduling engine for Adhkar.
 *
 * Architecture:
 * AlarmManager -> DndAlarmReceiver -> DndScheduler -> NotificationManager
 *
 * Operates purely on the native Android side without requiring an active Flutter engine,
 * foreground service, or polling.
 */
object DndScheduler {
    const val TAG = "DND_SCHEDULER"

    private const val PREFS_NAME = "adhkar_dnd_prefs"

    // Persisted schedule properties
    const val KEY_SCHEDULE_ENABLED = "schedule_enabled"
    const val KEY_START_HOUR = "start_hour"
    const val KEY_START_MINUTE = "start_minute"
    const val KEY_END_HOUR = "end_hour"
    const val KEY_END_MINUTE = "end_minute"
    const val KEY_REPEAT_DAILY = "repeat_daily"
    const val KEY_WEEKDAYS_JSON = "weekdays_json"
    const val KEY_SCHEDULE_ID = "schedule_id"
    const val KEY_SCHEDULE_TITLE = "schedule_title"
    const val KEY_NEXT_ENABLE_MILLIS = "next_enable_millis"
    const val KEY_NEXT_DISABLE_MILLIS = "next_disable_millis"
    const val KEY_TIMEZONE_ID = "timezone_id"
    const val KEY_ADHKAR_OWNS_DND = "adhkar_owns_dnd"
    const val KEY_SAVED_DND_FILTER = "saved_dnd_filter"
    const val KEY_LAST_KNOWN_DND_STATE = "last_known_dnd_state" // "ENABLED", "DISABLED", "UNKNOWN"
    const val KEY_SCHEDULES_LIST_JSON = "key_schedules_list_json" // For multi-schedule compatibility

    const val ACTION_ENABLE_DND = "com.sprnt.adhkar.ACTION_ENABLE_DND"
    const val ACTION_DISABLE_DND = "com.sprnt.adhkar.ACTION_DISABLE_DND"
    const val EXTRA_SCHEDULE_ID = "extra_schedule_id"
    const val EXTRA_SCHEDULE_TITLE = "extra_schedule_title"

    private const val BASE_ENABLE_REQUEST_CODE = 92000
    private const val BASE_DISABLE_REQUEST_CODE = 93000

    private val logDateFormat = SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.US)

    private fun getPrefs(context: Context): SharedPreferences {
        return context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    }

    private fun formatTimestamp(millis: Long): String {
        return try {
            logDateFormat.format(Date(millis))
        } catch (e: Exception) {
            millis.toString()
        }
    }

    // =========================================================================
    // Permission & System Checks
    // =========================================================================

    fun hasDndPermission(context: Context): Boolean {
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager ?: return false
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            nm.isNotificationPolicyAccessGranted
        } else {
            true
        }
    }

    fun canScheduleExactAlarms(context: Context): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager
            return alarmManager?.canScheduleExactAlarms() ?: true
        }
        return true
    }

    fun isBatteryOptimizationIgnored(context: Context): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val pm = context.getSystemService(Context.POWER_SERVICE) as? PowerManager ?: return true
            return pm.isIgnoringBatteryOptimizations(context.packageName)
        }
        return true
    }

    fun getCurrentInterruptionFilter(context: Context): Int {
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
            ?: return NotificationManager.INTERRUPTION_FILTER_ALL
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            nm.currentInterruptionFilter
        } else {
            NotificationManager.INTERRUPTION_FILTER_ALL
        }
    }

    // =========================================================================
    // Schedule Calculation Logic (Deterministic & Testable)
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
     * Calculates next start occurrence epoch millis strictly strictly after [fromMillis].
     */
    fun calculateNextStart(
        fromMillis: Long,
        startHour: Int,
        startMinute: Int,
        repeatDaily: Boolean,
        weekdays: List<Int>,
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
     * Calculates the upcoming end occurrence corresponding to the current or next active session.
     */
    fun calculateNextEnd(
        fromMillis: Long,
        startHour: Int,
        startMinute: Int,
        endHour: Int,
        endMinute: Int,
        repeatDaily: Boolean,
        weekdays: List<Int>,
        timeZone: TimeZone = TimeZone.getDefault()
    ): Long {
        val overnight = isOvernight(startHour, startMinute, endHour, endMinute)
        val cal = Calendar.getInstance(timeZone).apply { timeInMillis = fromMillis }
        val nowMinutes = cal.get(Calendar.HOUR_OF_DAY) * 60 + cal.get(Calendar.MINUTE)
        val startMinutes = startHour * 60 + startMinute

        val candidate = Calendar.getInstance(timeZone).apply {
            timeInMillis = fromMillis
            set(Calendar.HOUR_OF_DAY, endHour)
            set(Calendar.MINUTE, endMinute)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }

        if (!overnight) {
            if (candidate.timeInMillis <= fromMillis) {
                candidate.add(Calendar.DAY_OF_YEAR, 1)
            }
        } else {
            if (nowMinutes >= startMinutes) {
                // We are in the evening; end is tomorrow morning
                candidate.add(Calendar.DAY_OF_YEAR, 1)
            } else if (candidate.timeInMillis <= fromMillis) {
                // Passed morning end; roll forward
                candidate.add(Calendar.DAY_OF_YEAR, 1)
            }
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

    // =========================================================================
    // DND Interruption Filter / Policy Management
    // =========================================================================

    /**
     * Applies DND mode respecting previous state ownership (Requirement 15).
     */
    @Synchronized
    fun applyDndMode(context: Context, enable: Boolean) {
        if (!hasDndPermission(context)) {
            Log.w(TAG, "DND_SCHEDULER: Notification Policy Access unavailable. Cannot change DND state.")
            return
        }

        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager ?: return
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return

        try {
            val prefs = getPrefs(context)
            if (enable) {
                val currentFilter = nm.currentInterruptionFilter
                val alreadyDnd = currentFilter != NotificationManager.INTERRUPTION_FILTER_ALL

                if (alreadyDnd) {
                    // DND is already active (user manually enabled it or another schedule did)
                    Log.d(TAG, "DND_SCHEDULER: DND was already active (filter=$currentFilter). Preserving user state; not claiming ownership.")
                    prefs.edit()
                        .putBoolean(KEY_ADHKAR_OWNS_DND, false)
                        .putInt(KEY_SAVED_DND_FILTER, currentFilter)
                        .putString(KEY_LAST_KNOWN_DND_STATE, "ENABLED")
                        .apply()
                } else {
                    // DND was OFF. Adhkar claims ownership.
                    Log.d(TAG, "DND_SCHEDULER: Enabling DND (INTERRUPTION_FILTER_PRIORITY). Adhkar claiming ownership.")
                    prefs.edit()
                        .putBoolean(KEY_ADHKAR_OWNS_DND, true)
                        .putInt(KEY_SAVED_DND_FILTER, currentFilter)
                        .putString(KEY_LAST_KNOWN_DND_STATE, "ENABLED")
                        .apply()

                    nm.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_PRIORITY)
                    Log.i(TAG, "DND_SCHEDULER: DND enabled successfully.")
                }
            } else {
                val ownsDnd = prefs.getBoolean(KEY_ADHKAR_OWNS_DND, false)
                val savedFilter = prefs.getInt(KEY_SAVED_DND_FILTER, NotificationManager.INTERRUPTION_FILTER_ALL)

                if (ownsDnd) {
                    Log.d(TAG, "DND_SCHEDULER: Disabling DND. Adhkar owned DND; restoring prior filter ($savedFilter).")
                    nm.setInterruptionFilter(savedFilter)
                    prefs.edit()
                        .putBoolean(KEY_ADHKAR_OWNS_DND, false)
                        .putString(KEY_LAST_KNOWN_DND_STATE, "DISABLED")
                        .apply()
                    Log.i(TAG, "DND_SCHEDULER: DND disabled successfully.")
                } else {
                    Log.d(TAG, "DND_SCHEDULER: Schedule ended, but Adhkar did NOT own DND at start. Leaving current DND state untouched.")
                    prefs.edit()
                        .putString(KEY_LAST_KNOWN_DND_STATE, "DISABLED")
                        .apply()
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "DND_SCHEDULER: Error applying DND mode (enable=$enable): ${e.message}", e)
        }
    }

    // =========================================================================
    // AlarmManager Scheduling
    // =========================================================================

    /**
     * Schedules a primary DND schedule with exact AlarmManager alarms.
     */
    @Synchronized
    fun scheduleDnd(
        context: Context,
        startHour: Int,
        startMinute: Int,
        endHour: Int,
        endMinute: Int,
        repeatDaily: Boolean = true,
        weekdays: List<Int> = listOf(1, 2, 3, 4, 5, 6, 7),
        scheduleId: String = "dnd_primary",
        title: String = "Quiet Hours"
    ) {
        val now = System.currentTimeMillis()
        val tz = TimeZone.getDefault()

        // 1. Cancel previous alarms first to prevent accumulation
        cancelAlarms(context, scheduleId)

        // 2. Compute occurrences
        val isCurrentlyInside = isInsideSchedule(
            nowMillis = now,
            startHour = startHour,
            startMinute = startMinute,
            endHour = endHour,
            endMinute = endMinute,
            repeatDaily = repeatDaily,
            weekdays = weekdays,
            timeZone = tz
        )

        val nextStart = calculateNextStart(
            fromMillis = now,
            startHour = startHour,
            startMinute = startMinute,
            repeatDaily = repeatDaily,
            weekdays = weekdays,
            timeZone = tz
        )

        val nextEnd = calculateNextEnd(
            fromMillis = now,
            startHour = startHour,
            startMinute = startMinute,
            endHour = endHour,
            endMinute = endMinute,
            repeatDaily = repeatDaily,
            weekdays = weekdays,
            timeZone = tz
        )

        // 3. Persist to SharedPreferences
        val weekdaysJson = JSONArray(weekdays).toString()
        getPrefs(context).edit()
            .putBoolean(KEY_SCHEDULE_ENABLED, true)
            .putInt(KEY_START_HOUR, startHour)
            .putInt(KEY_START_MINUTE, startMinute)
            .putInt(KEY_END_HOUR, endHour)
            .putInt(KEY_END_MINUTE, endMinute)
            .putBoolean(KEY_REPEAT_DAILY, repeatDaily)
            .putString(KEY_WEEKDAYS_JSON, weekdaysJson)
            .putString(KEY_SCHEDULE_ID, scheduleId)
            .putString(KEY_SCHEDULE_TITLE, title)
            .putLong(KEY_NEXT_ENABLE_MILLIS, nextStart)
            .putLong(KEY_NEXT_DISABLE_MILLIS, nextEnd)
            .putString(KEY_TIMEZONE_ID, tz.id)
            .apply()

        // 4. Arm alarms in AlarmManager
        armAlarm(context, nextStart, ACTION_ENABLE_DND, scheduleId, title, getEnableRequestCode(scheduleId))
        Log.i(TAG, "DND_SCHEDULER: Scheduling enable alarm: ${formatTimestamp(nextStart)} (rc=${getEnableRequestCode(scheduleId)})")

        armAlarm(context, nextEnd, ACTION_DISABLE_DND, scheduleId, title, getDisableRequestCode(scheduleId))
        Log.i(TAG, "DND_SCHEDULER: Scheduling disable alarm: ${formatTimestamp(nextEnd)} (rc=${getDisableRequestCode(scheduleId)})")

        // 5. Apply immediately if already inside schedule window
        if (isCurrentlyInside) {
            Log.i(TAG, "DND_SCHEDULER: Current time is inside the scheduled window. Enabling DND immediately.")
            applyDndMode(context, true)
        }
    }

    /**
     * Cancels scheduled DND alarms and optionally restores system state.
     */
    @Synchronized
    fun cancelDnd(context: Context, scheduleId: String = "dnd_primary", restoreDnd: Boolean = true) {
        cancelAlarms(context, scheduleId)

        getPrefs(context).edit()
            .putBoolean(KEY_SCHEDULE_ENABLED, false)
            .remove(KEY_NEXT_ENABLE_MILLIS)
            .remove(KEY_NEXT_DISABLE_MILLIS)
            .apply()

        if (restoreDnd) {
            applyDndMode(context, false)
        }
        Log.i(TAG, "DND_SCHEDULER: DND schedule cancelled and alarms removed.")
    }

    private fun armAlarm(
        context: Context,
        triggerAtMillis: Long,
        action: String,
        scheduleId: String,
        title: String,
        requestCode: Int
    ) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
        val intent = Intent(context, DndAlarmReceiver::class.java).apply {
            this.action = action
            putExtra(EXTRA_SCHEDULE_ID, scheduleId)
            putExtra(EXTRA_SCHEDULE_TITLE, title)
        }

        val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        val pendingIntent = PendingIntent.getBroadcast(context, requestCode, intent, flags)

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                if (canScheduleExactAlarms(context)) {
                    alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAtMillis, pendingIntent)
                } else {
                    Log.w(TAG, "DND_SCHEDULER: canScheduleExactAlarms=false. Fallback to setAndAllowWhileIdle.")
                    alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAtMillis, pendingIntent)
                }
            } else {
                alarmManager.setExact(AlarmManager.RTC_WAKEUP, triggerAtMillis, pendingIntent)
            }
        } catch (e: SecurityException) {
            Log.w(TAG, "DND_SCHEDULER: SecurityException scheduling exact alarm. Fallback to inexact: ${e.message}")
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAtMillis, pendingIntent)
                } else {
                    alarmManager.set(AlarmManager.RTC_WAKEUP, triggerAtMillis, pendingIntent)
                }
            } catch (e2: Exception) {
                Log.e(TAG, "DND_SCHEDULER: Failed to schedule fallback alarm: ${e2.message}", e2)
            }
        } catch (e: Exception) {
            Log.e(TAG, "DND_SCHEDULER: Unexpected error setting alarm: ${e.message}", e)
        }
    }

    private fun cancelAlarms(context: Context, scheduleId: String) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return

        fun cancelSpecific(action: String, rc: Int) {
            val intent = Intent(context, DndAlarmReceiver::class.java).apply { this.action = action }
            val flags = PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE
            val pi = PendingIntent.getBroadcast(context, rc, intent, flags)
            if (pi != null) {
                alarmManager.cancel(pi)
                pi.cancel()
            }
        }

        cancelSpecific(ACTION_ENABLE_DND, getEnableRequestCode(scheduleId))
        cancelSpecific(ACTION_DISABLE_DND, getDisableRequestCode(scheduleId))
    }

    // =========================================================================
    // AlarmReceiver Callbacks
    // =========================================================================

    /**
     * Called when ACTION_ENABLE_DND triggers.
     */
    fun onEnableAlarmTriggered(context: Context, scheduleId: String, title: String) {
        Log.i(TAG, "DND_SCHEDULER: Enable alarm received for $scheduleId ($title)")
        applyDndMode(context, true)

        // Reschedule next enable occurrence
        val prefs = getPrefs(context)
        if (!prefs.getBoolean(KEY_SCHEDULE_ENABLED, false)) return

        val startHour = prefs.getInt(KEY_START_HOUR, 0)
        val startMinute = prefs.getInt(KEY_START_MINUTE, 0)
        val repeatDaily = prefs.getBoolean(KEY_REPEAT_DAILY, true)
        val weekdays = parseWeekdaysJson(prefs.getString(KEY_WEEKDAYS_JSON, null))

        val nextStart = calculateNextStart(
            fromMillis = System.currentTimeMillis(),
            startHour = startHour,
            startMinute = startMinute,
            repeatDaily = repeatDaily,
            weekdays = weekdays
        )

        prefs.edit().putLong(KEY_NEXT_ENABLE_MILLIS, nextStart).apply()
        armAlarm(context, nextStart, ACTION_ENABLE_DND, scheduleId, title, getEnableRequestCode(scheduleId))
        Log.i(TAG, "DND_SCHEDULER: Scheduling next enable alarm: ${formatTimestamp(nextStart)}")
    }

    /**
     * Called when ACTION_DISABLE_DND triggers.
     */
    fun onDisableAlarmTriggered(context: Context, scheduleId: String, title: String) {
        Log.i(TAG, "DND_SCHEDULER: Disable alarm received for $scheduleId ($title)")
        applyDndMode(context, false)

        // Reschedule next disable occurrence
        val prefs = getPrefs(context)
        if (!prefs.getBoolean(KEY_SCHEDULE_ENABLED, false)) return

        val startHour = prefs.getInt(KEY_START_HOUR, 0)
        val startMinute = prefs.getInt(KEY_START_MINUTE, 0)
        val endHour = prefs.getInt(KEY_END_HOUR, 0)
        val endMinute = prefs.getInt(KEY_END_MINUTE, 0)
        val repeatDaily = prefs.getBoolean(KEY_REPEAT_DAILY, true)
        val weekdays = parseWeekdaysJson(prefs.getString(KEY_WEEKDAYS_JSON, null))

        val nextEnd = calculateNextEnd(
            fromMillis = System.currentTimeMillis(),
            startHour = startHour,
            startMinute = startMinute,
            endHour = endHour,
            endMinute = endMinute,
            repeatDaily = repeatDaily,
            weekdays = weekdays
        )

        prefs.edit().putLong(KEY_NEXT_DISABLE_MILLIS, nextEnd).apply()
        armAlarm(context, nextEnd, ACTION_DISABLE_DND, scheduleId, title, getDisableRequestCode(scheduleId))
        Log.i(TAG, "DND_SCHEDULER: Scheduling next disable alarm: ${formatTimestamp(nextEnd)}")
    }

    // =========================================================================
    // System Event Reconciler (Boot / Time Change / Missed Alarms - Req 8 & 18)
    // =========================================================================

    /**
     * Reconciles current device state and re-registers alarms.
     * Evaluates current time vs schedule window and corrects state if device was off.
     */
    @Synchronized
    fun reconcileCurrentState(context: Context, reason: String) {
        Log.i(TAG, "DND_SCHEDULER: Reconciling schedule state (reason: $reason)...")

        // First check multi-schedule JSON if present (from Quiet Hours)
        val multiJson = prefsGetSchedulesList(context)
        if (!multiJson.isNullOrEmpty()) {
            QuietHoursScheduler.scheduleAll(context, multiJson)
            Log.i(TAG, "DND_SCHEDULER: Restored multi-schedule Quiet Hours.")
            return
        }

        val prefs = getPrefs(context)
        if (!prefs.getBoolean(KEY_SCHEDULE_ENABLED, false)) {
            Log.d(TAG, "DND_SCHEDULER: No active DND schedule found to restore.")
            return
        }

        val startHour = prefs.getInt(KEY_START_HOUR, 0)
        val startMinute = prefs.getInt(KEY_START_MINUTE, 0)
        val endHour = prefs.getInt(KEY_END_HOUR, 0)
        val endMinute = prefs.getInt(KEY_END_MINUTE, 0)
        val repeatDaily = prefs.getBoolean(KEY_REPEAT_DAILY, true)
        val weekdays = parseWeekdaysJson(prefs.getString(KEY_WEEKDAYS_JSON, null))
        val scheduleId = prefs.getString(KEY_SCHEDULE_ID, "dnd_primary") ?: "dnd_primary"
        val title = prefs.getString(KEY_SCHEDULE_TITLE, "Quiet Hours") ?: "Quiet Hours"

        val now = System.currentTimeMillis()
        val isInside = isInsideSchedule(
            nowMillis = now,
            startHour = startHour,
            startMinute = startMinute,
            endHour = endHour,
            endMinute = endMinute,
            repeatDaily = repeatDaily,
            weekdays = weekdays
        )

        Log.i(TAG, "DND_SCHEDULER: Schedule evaluation at ${formatTimestamp(now)}: isInside=$isInside")

        if (isInside) {
            // Device booted or time shifted inside the active window.
            applyDndMode(context, true)
        } else {
            // Outside window. If Adhkar previously owned DND, ensure it's cleared now.
            if (prefs.getBoolean(KEY_ADHKAR_OWNS_DND, false)) {
                Log.i(TAG, "DND_SCHEDULER: Outside scheduled window, but Adhkar owned DND (missed end alarm while off). Restoring normal filter.")
                applyDndMode(context, false)
            }
        }

        // Re-calculate and re-arm next alarms
        val nextStart = calculateNextStart(now, startHour, startMinute, repeatDaily, weekdays)
        val nextEnd = calculateNextEnd(now, startHour, startMinute, endHour, endMinute, repeatDaily, weekdays)

        prefs.edit()
            .putLong(KEY_NEXT_ENABLE_MILLIS, nextStart)
            .putLong(KEY_NEXT_DISABLE_MILLIS, nextEnd)
            .putString(KEY_TIMEZONE_ID, TimeZone.getDefault().id)
            .apply()

        armAlarm(context, nextStart, ACTION_ENABLE_DND, scheduleId, title, getEnableRequestCode(scheduleId))
        armAlarm(context, nextEnd, ACTION_DISABLE_DND, scheduleId, title, getDisableRequestCode(scheduleId))

        Log.i(TAG, "DND_SCHEDULER: Schedule re-armed successfully: enable=${formatTimestamp(nextStart)}, disable=${formatTimestamp(nextEnd)}")
    }

    // =========================================================================
    // Schedule Inspection for MethodChannel
    // =========================================================================

    fun getPersistedSchedule(context: Context): Map<String, Any?> {
        val prefs = getPrefs(context)
        val enabled = prefs.getBoolean(KEY_SCHEDULE_ENABLED, false)
        val startHour = prefs.getInt(KEY_START_HOUR, 0)
        val startMinute = prefs.getInt(KEY_START_MINUTE, 0)
        val endHour = prefs.getInt(KEY_END_HOUR, 0)
        val endMinute = prefs.getInt(KEY_END_MINUTE, 0)
        val repeatDaily = prefs.getBoolean(KEY_REPEAT_DAILY, true)
        val weekdays = parseWeekdaysJson(prefs.getString(KEY_WEEKDAYS_JSON, null))
        val nextEnable = prefs.getLong(KEY_NEXT_ENABLE_MILLIS, 0L)
        val nextDisable = prefs.getLong(KEY_NEXT_DISABLE_MILLIS, 0L)
        val timeZone = prefs.getString(KEY_TIMEZONE_ID, TimeZone.getDefault().id) ?: TimeZone.getDefault().id
        val lastState = prefs.getString(KEY_LAST_KNOWN_DND_STATE, "UNKNOWN") ?: "UNKNOWN"
        val ownsDnd = prefs.getBoolean(KEY_ADHKAR_OWNS_DND, false)

        return mapOf(
            "enabled" to enabled,
            "startHour" to startHour,
            "startMinute" to startMinute,
            "endHour" to endHour,
            "endMinute" to endMinute,
            "repeatDaily" to repeatDaily,
            "weekdays" to weekdays,
            "nextEnableTimestamp" to nextEnable,
            "nextDisableTimestamp" to nextDisable,
            "timeZone" to timeZone,
            "lastKnownDndState" to lastState,
            "adhkarOwnsDnd" to ownsDnd
        )
    }

    // =========================================================================
    // Helpers
    // =========================================================================

    fun prefsSaveSchedulesList(context: Context, json: String) {
        getPrefs(context).edit().putString(KEY_SCHEDULES_LIST_JSON, json).apply()
    }

    fun prefsGetSchedulesList(context: Context): String? {
        return getPrefs(context).getString(KEY_SCHEDULES_LIST_JSON, null)
    }

    private fun getEnableRequestCode(scheduleId: String): Int {
        return BASE_ENABLE_REQUEST_CODE + (Math.abs(scheduleId.hashCode()) % 400) * 2
    }

    private fun getDisableRequestCode(scheduleId: String): Int {
        return getEnableRequestCode(scheduleId) + 1
    }

    private fun parseWeekdaysJson(json: String?): List<Int> {
        if (json.isNullOrEmpty()) return listOf(1, 2, 3, 4, 5, 6, 7)
        return try {
            val arr = JSONArray(json)
            val list = mutableListOf<Int>()
            for (i in 0 until arr.length()) {
                list.add(arr.getInt(i))
            }
            if (list.isEmpty()) listOf(1, 2, 3, 4, 5, 6, 7) else list
        } catch (e: Exception) {
            listOf(1, 2, 3, 4, 5, 6, 7)
        }
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
}
