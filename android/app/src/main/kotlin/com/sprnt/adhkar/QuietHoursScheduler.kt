package com.sprnt.adhkar

import android.app.AlarmManager
import android.app.AutomaticZenRule
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.os.Build
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
     * Synchronize schedules directly with Android's system AutomaticZenRule (OS Do Not Disturb Schedules).
     * This creates native rules visible in Android's Do Not Disturb system settings.
     */
    fun syncAutomaticZenRules(context: Context, schedulesJson: String) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) return
        try {
            val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager ?: return
            if (!nm.isNotificationPolicyAccessGranted) return

            val existingRules = nm.automaticZenRules
            val arr = JSONArray(schedulesJson)
            val currentScheduleIds = mutableSetOf<String>()

            for (i in 0 until arr.length()) {
                val obj = arr.getJSONObject(i)
                val scheduleId = obj.optString("id", "quiet_$i")
                val title = obj.optString("title", "Adhkar Quiet Hours")
                val enabled = obj.optBoolean("enabled", true)
                currentScheduleIds.add(scheduleId)

                val conditionUri = Uri.parse("adhkar://quiet_hours/$scheduleId")

                val existingEntry = existingRules.entries.firstOrNull {
                    it.value.conditionId == conditionUri || it.value.name == title
                }

                val componentName = ComponentName(context.packageName, MainActivity::class.java.name)

                if (existingEntry != null) {
                    val rule = existingEntry.value
                    rule.name = title
                    rule.isEnabled = enabled
                    rule.interruptionFilter = NotificationManager.INTERRUPTION_FILTER_PRIORITY
                    nm.updateAutomaticZenRule(existingEntry.key, rule)
                    Log.d(TAG, "Updated AutomaticZenRule in Android system: ${existingEntry.key} ($title, enabled=$enabled)")
                } else {
                    val rule = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        AutomaticZenRule(
                            title,
                            componentName,
                            componentName,
                            conditionUri,
                            null,
                            NotificationManager.INTERRUPTION_FILTER_PRIORITY,
                            enabled
                        )
                    } else {
                        AutomaticZenRule(
                            title,
                            componentName,
                            conditionUri,
                            NotificationManager.INTERRUPTION_FILTER_PRIORITY,
                            enabled
                        )
                    }
                    val newRuleId = nm.addAutomaticZenRule(rule)
                    Log.d(TAG, "Added AutomaticZenRule to Android system: $newRuleId ($title)")
                }
            }

            // Remove any rules no longer present in Adhkar
            for ((ruleId, rule) in existingRules) {
                val uriStr = rule.conditionId?.toString() ?: ""
                if (uriStr.startsWith("adhkar://quiet_hours/")) {
                    val id = uriStr.substring("adhkar://quiet_hours/".length)
                    if (!currentScheduleIds.contains(id)) {
                        nm.removeAutomaticZenRule(ruleId)
                        Log.d(TAG, "Removed obsolete AutomaticZenRule: $ruleId")
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error syncing AutomaticZenRules", e)
        }
    }

    /**
     * Enable or disable Do Not Disturb mode directly.
     * Silent operation: no sound, no notification, no alarm.
     */
    fun applyDndMode(context: Context, enable: Boolean) {
        try {
            val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager ?: return
            if (!nm.isNotificationPolicyAccessGranted) {
                Log.w(TAG, "Notification policy access not granted. Cannot toggle DND.")
                return
            }

            if (enable) {
                val currentFilter = nm.currentInterruptionFilter
                setSavedDndFilter(context, currentFilter)
                setAdhkarOwnsDnd(context, true)
                nm.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_PRIORITY)
                Log.d(TAG, "Quiet Hours: DND Enabled (INTERRUPTION_FILTER_PRIORITY). Prior filter: $currentFilter")
            } else {
                // Always unconditionally disable DND and restore INTERRUPTION_FILTER_ALL when quiet hours ends
                nm.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_ALL)
                setAdhkarOwnsDnd(context, false)
                Log.d(TAG, "Quiet Hours: DND Disabled. Successfully restored INTERRUPTION_FILTER_ALL")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error toggling DND mode", e)
        }
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
        saveSchedules(context, schedulesJson)
        cancelAll(context)
        syncAutomaticZenRules(context, schedulesJson)

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
                val nextStartMillis = calculateNextOccurrence(
                    targetHour = startHour,
                    targetMinute = startMinute,
                    repeatDaily = repeatDaily,
                    weekdays = weekdays
                )
                setExactAlarm(context, alarmManager, nextStartMillis, ACTION_START_QUIET_HOURS, scheduleId, title, getStartRequestCode(scheduleId))

                // Schedule Next End
                val nextEndMillis = calculateNextOccurrence(
                    targetHour = endHour,
                    targetMinute = endMinute,
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

                val targetHour = if (isStart) startHour else endHour
                val targetMinute = if (isStart) startMinute else endMinute

                val nextMillis = calculateNextOccurrence(
                    targetHour = targetHour,
                    targetMinute = targetMinute,
                    repeatDaily = repeatDaily,
                    weekdays = weekdays
                )

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

    private fun calculateNextOccurrence(
        targetHour: Int,
        targetMinute: Int,
        repeatDaily: Boolean,
        weekdays: List<Int>
    ): Long {
        val now = Calendar.getInstance()
        val candidate = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, targetHour)
            set(Calendar.MINUTE, targetMinute)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }

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

    private fun getStartRequestCode(scheduleId: String): Int {
        return 91000 + (Math.abs(scheduleId.hashCode()) % 4000) * 2
    }

    private fun getEndRequestCode(scheduleId: String): Int {
        return getStartRequestCode(scheduleId) + 1
    }
}
