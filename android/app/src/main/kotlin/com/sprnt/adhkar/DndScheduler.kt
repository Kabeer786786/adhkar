package com.sprnt.adhkar

import android.app.NotificationManager
import android.content.Context
import android.os.Build
import android.util.Log
import org.json.JSONArray
import org.json.JSONObject
import java.util.TimeZone

/**
 * Native Android Do Not Disturb policy executor for Adhkar.
 *
 * Implements strict ownership semantics:
 * - Only enables DND if Notification Policy Access is granted.
 * - If the user manually enabled DND outside Adhkar, Adhkar does not take ownership
 *   and will never turn off DND when a schedule ends.
 * - If multiple schedules overlap, Adhkar maintains continuous ownership until all
 *   active schedules have concluded.
 */
object DndScheduler {
    const val TAG = "AdhkarQuietHours"

    // =========================================================================
    // Permission & System State Checks
    // =========================================================================

    fun hasDndPermission(context: Context): Boolean {
        return QuietHoursScheduler.hasDndPermission(context)
    }

    fun canScheduleExactAlarms(context: Context): Boolean {
        return QuietHoursScheduler.canScheduleExactAlarms(context)
    }

    fun isBatteryOptimizationIgnored(context: Context): Boolean {
        return QuietHoursScheduler.isBatteryOptimizationIgnored(context)
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
    // DND Mode & Ownership Application
    // =========================================================================

    /**
     * Applies DND mode respecting user ownership semantics.
     */
    @Synchronized
    fun applyDndMode(context: Context, enable: Boolean) {
        if (!hasDndPermission(context)) {
            Log.w(TAG, "Notification Policy Access unavailable. Cannot change DND state.")
            return
        }

        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager ?: return
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return

        try {
            val currentFilter = nm.currentInterruptionFilter
            val isAlreadyDnd = currentFilter != NotificationManager.INTERRUPTION_FILTER_ALL
            val ownsDnd = QuietHoursScheduler.getAdhkarOwnsDnd(context)

            if (enable) {
                if (isAlreadyDnd) {
                    if (ownsDnd) {
                        Log.i(TAG, "DND already active under Adhkar ownership. Keeping ownership active.")
                    } else {
                        Log.i(TAG, "DND was enabled by user outside Adhkar (filter=$currentFilter). Preserving user state; Adhkar will NOT take ownership.")
                        QuietHoursScheduler.setAdhkarOwnsDnd(context, false)
                        QuietHoursScheduler.setSavedDndFilter(context, currentFilter)
                    }
                } else {
                    Log.i(TAG, "DND is currently OFF. Adhkar enabling DND (PRIORITY) and claiming ownership.")
                    QuietHoursScheduler.setSavedDndFilter(context, currentFilter)
                    QuietHoursScheduler.setAdhkarOwnsDnd(context, true)
                    nm.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_PRIORITY)
                    Log.i(TAG, "DND successfully enabled by Adhkar.")
                }
            } else {
                if (ownsDnd) {
                    val savedFilter = QuietHoursScheduler.getSavedDndFilter(context)
                    Log.i(TAG, "Disabling DND. Adhkar owned DND; restoring prior filter ($savedFilter).")
                    nm.setInterruptionFilter(savedFilter)
                    QuietHoursScheduler.setAdhkarOwnsDnd(context, false)
                    Log.i(TAG, "DND successfully restored.")
                } else {
                    Log.i(TAG, "Schedule ended, but Adhkar does not own DND (user enabled it manually). Preserving current DND state.")
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error in applyDndMode(enable=$enable): ${e.message}", e)
        }
    }

    // =========================================================================
    // Multi-Schedule Compatibility & MethodChannel Bridge Helpers
    // =========================================================================

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
        val scheduleObj = JSONObject().apply {
            put("id", scheduleId)
            put("title", title)
            put("startHour", startHour)
            put("startMinute", startMinute)
            put("endHour", endHour)
            put("endMinute", endMinute)
            put("repeatDaily", repeatDaily)
            put("weekdays", JSONArray(weekdays))
            put("enabled", true)
        }
        val array = JSONArray().put(scheduleObj)
        QuietHoursScheduler.scheduleAll(context, array.toString())
    }

    @Synchronized
    fun cancelDnd(context: Context, scheduleId: String = "dnd_primary", restoreDnd: Boolean = true) {
        QuietHoursScheduler.cancelAll(context)
        if (restoreDnd) {
            applyDndMode(context, false)
        }
        Log.i(TAG, "Cancelled DND and alarms via QuietHoursScheduler.")
    }

    @Synchronized
    fun reconcileCurrentState(context: Context, reason: String) {
        Log.i(TAG, "Reconciling schedule state (reason: $reason)...")
        val schedulesJson = QuietHoursScheduler.getSchedules(context)
        if (!schedulesJson.isNullOrEmpty()) {
            QuietHoursScheduler.scheduleAll(context, schedulesJson)
            Log.i(TAG, "Restored and re-armed Quiet Hours schedules.")
        }
    }

    fun getPersistedSchedule(context: Context): Map<String, Any?> {
        val schedulesJson = QuietHoursScheduler.getSchedules(context)
        if (schedulesJson.isNullOrEmpty()) {
            return mapOf("enabled" to false)
        }

        return try {
            val arr = JSONArray(schedulesJson)
            if (arr.length() == 0) return mapOf("enabled" to false)
            val obj = arr.getJSONObject(0)

            val enabled = obj.optBoolean("enabled", true)
            val startHour = obj.optInt("startHour", 0)
            val startMinute = obj.optInt("startMinute", 0)
            val endHour = obj.optInt("endHour", 0)
            val endMinute = obj.optInt("endMinute", 0)
            val repeatDaily = obj.optBoolean("repeatDaily", true)
            val weekdaysArr = obj.optJSONArray("weekdays")
            val weekdays = mutableListOf<Int>()
            if (weekdaysArr != null) {
                for (i in 0 until weekdaysArr.length()) weekdays.add(weekdaysArr.getInt(i))
            } else {
                weekdays.addAll(listOf(1, 2, 3, 4, 5, 6, 7))
            }

            val nextEnable = QuietHoursScheduler.calculateNextStartOccurrence(startHour, startMinute, repeatDaily, weekdays)
            val nextDisable = QuietHoursScheduler.calculateNextEndOccurrence(startHour, startMinute, endHour, endMinute, repeatDaily, weekdays)
            val ownsDnd = QuietHoursScheduler.getAdhkarOwnsDnd(context)

            mapOf(
                "enabled" to enabled,
                "startHour" to startHour,
                "startMinute" to startMinute,
                "endHour" to endHour,
                "endMinute" to endMinute,
                "repeatDaily" to repeatDaily,
                "weekdays" to weekdays,
                "nextEnableTimestamp" to nextEnable,
                "nextDisableTimestamp" to nextDisable,
                "timeZone" to TimeZone.getDefault().id,
                "adhkarOwnsDnd" to ownsDnd
            )
        } catch (e: Exception) {
            Log.e(TAG, "Error getting persisted schedule map: ${e.message}", e)
            mapOf("enabled" to false)
        }
    }

    fun isOvernight(startHour: Int, startMinute: Int, endHour: Int, endMinute: Int): Boolean {
        return QuietHoursScheduler.isOvernight(startHour, startMinute, endHour, endMinute)
    }

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
        return QuietHoursScheduler.isInsideSchedule(nowMillis, startHour, startMinute, endHour, endMinute, repeatDaily, weekdays, timeZone)
    }

    fun calculateNextStart(
        fromMillis: Long,
        startHour: Int,
        startMinute: Int,
        repeatDaily: Boolean,
        weekdays: List<Int>,
        timeZone: TimeZone = TimeZone.getDefault()
    ): Long {
        return QuietHoursScheduler.calculateNextStartOccurrence(startHour, startMinute, repeatDaily, weekdays, fromMillis, timeZone)
    }

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
        return QuietHoursScheduler.calculateNextEndOccurrence(startHour, startMinute, endHour, endMinute, repeatDaily, weekdays, fromMillis, timeZone)
    }
}
