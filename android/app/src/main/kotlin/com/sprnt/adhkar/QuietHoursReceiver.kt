package com.sprnt.adhkar

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.PowerManager
import android.util.Log

/**
 * BroadcastReceiver triggered by Android AlarmManager for Quiet Hours start/end events.
 * Runs completely independent of Flutter activity or UI lifecycle.
 */
class QuietHoursReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "AdhkarQuietHours"
    }

    override fun onReceive(context: Context, intent: Intent?) {
        if (intent == null) return
        val action = intent.action ?: return
        val scheduleId = intent.getStringExtra(QuietHoursScheduler.EXTRA_SCHEDULE_ID) ?: ""
        val scheduleTitle = intent.getStringExtra(QuietHoursScheduler.EXTRA_SCHEDULE_TITLE) ?: "Quiet Hours"

        Log.i(TAG, "QuietHoursReceiver triggered: action=$action, scheduleId=$scheduleId ($scheduleTitle)")

        val pendingResult = goAsync()
        val powerManager = context.getSystemService(Context.POWER_SERVICE) as? PowerManager
        val wakeLock = powerManager?.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "Adhkar:QuietHoursReceiverWakeLock")?.apply {
            setReferenceCounted(false)
            acquire(10 * 1000L) // 10s maximum safety timeout for DND IPC
        }

        try {
            when (action) {
                QuietHoursScheduler.ACTION_START_QUIET_HOURS -> {
                    Log.i(TAG, "Executing START_QUIET_HOURS for $scheduleId ($scheduleTitle)")
                    // Enable Do Not Disturb mode on device
                    QuietHoursScheduler.applyDndMode(context, true)
                    // Arm the next occurrence of this start trigger
                    if (scheduleId.isNotEmpty()) {
                        QuietHoursScheduler.rescheduleNextOccurrence(context, scheduleId, isStart = true)
                    }
                }

                QuietHoursScheduler.ACTION_END_QUIET_HOURS -> {
                    Log.i(TAG, "Executing END_QUIET_HOURS for $scheduleId ($scheduleTitle)")
                    // Check if any other quiet hours schedule is currently active
                    val otherActive = QuietHoursScheduler.isAnyOtherQuietHoursActiveNow(
                        context,
                        excludingScheduleId = scheduleId
                    )
                    if (!otherActive) {
                        Log.i(TAG, "No other quiet hours window active; restoring normal DND state.")
                        QuietHoursScheduler.applyDndMode(context, false)
                    } else {
                        Log.i(TAG, "Another quiet hours window is currently active; maintaining DND.")
                    }
                    // Arm the next occurrence of this end trigger
                    if (scheduleId.isNotEmpty()) {
                        QuietHoursScheduler.rescheduleNextOccurrence(context, scheduleId, isStart = false)
                    }
                }

                else -> {
                    Log.w(TAG, "Unrecognized action received in QuietHoursReceiver: $action")
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error in QuietHoursReceiver onReceive: ${e.message}", e)
        } finally {
            try {
                if (wakeLock?.isHeld == true) {
                    wakeLock.release()
                }
            } catch (t: Throwable) {
                // Ignore wake-lock release error
            }
            pendingResult.finish()
        }
    }
}
