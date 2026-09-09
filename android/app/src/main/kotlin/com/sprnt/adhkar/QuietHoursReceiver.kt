package com.sprnt.adhkar

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.PowerManager
import android.util.Log

class QuietHoursReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "QuietHoursReceiver"
    }

    override fun onReceive(context: Context, intent: Intent?) {
        if (intent == null) return
        val action = intent.action ?: return
        val scheduleId = intent.getStringExtra(QuietHoursScheduler.EXTRA_SCHEDULE_ID) ?: ""
        val scheduleTitle = intent.getStringExtra(QuietHoursScheduler.EXTRA_SCHEDULE_TITLE) ?: "Quiet Hours"

        Log.d(TAG, "QuietHoursReceiver triggered: action=$action, scheduleId=$scheduleId ($scheduleTitle)")

        val pendingResult = goAsync()
        val powerManager = context.getSystemService(Context.POWER_SERVICE) as? PowerManager
        val wakeLock = powerManager?.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "Adhkar:QuietHoursWakeLock")?.apply {
            setReferenceCounted(false)
            acquire(15 * 1000L) // Hold CPU awake for 15 seconds to finish IPC with system_server
        }

        try {
            when (action) {
                QuietHoursScheduler.ACTION_START_QUIET_HOURS -> {
                    // Silently enable Do Not Disturb mode on device
                    QuietHoursScheduler.applyDndMode(context, true)
                    // Arm the next occurrence of this start trigger
                    if (scheduleId.isNotEmpty()) {
                        QuietHoursScheduler.rescheduleNextOccurrence(context, scheduleId, isStart = true)
                    }
                }

                QuietHoursScheduler.ACTION_END_QUIET_HOURS -> {
                    // Check if any other quiet hours schedule is currently overlapping (excluding this schedule)
                    val otherActive = QuietHoursScheduler.isAnyOtherQuietHoursActiveNow(context, excludingScheduleId = scheduleId)
                    if (!otherActive) {
                        // Silently disable Do Not Disturb and restore normal system state
                        QuietHoursScheduler.applyDndMode(context, false)
                    } else {
                        Log.d(TAG, "Another quiet hours window is currently active; keeping DND enabled.")
                    }
                    // Arm the next occurrence of this end trigger
                    if (scheduleId.isNotEmpty()) {
                        QuietHoursScheduler.rescheduleNextOccurrence(context, scheduleId, isStart = false)
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error in QuietHoursReceiver onReceive", e)
        } finally {
            try {
                if (wakeLock?.isHeld == true) {
                    wakeLock.release()
                }
            } catch (t: Throwable) {}
            pendingResult.finish()
        }
    }
}
