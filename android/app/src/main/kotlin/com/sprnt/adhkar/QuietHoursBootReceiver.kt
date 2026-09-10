package com.sprnt.adhkar

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.PowerManager
import android.util.Log

/**
 * System event receiver for Device Boot, Clock changes, Timezone transitions, and Package Updates.
 * Reschedules exact alarms and synchronizes DND state purely natively without requiring Flutter.
 */
class QuietHoursBootReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "AdhkarQuietHours"
    }

    override fun onReceive(context: Context, intent: Intent?) {
        val action = intent?.action ?: return
        Log.i(TAG, "System event received in QuietHoursBootReceiver: $action. Reconciling alarms and DND state.")

        val pendingResult = goAsync()
        val powerManager = context.getSystemService(Context.POWER_SERVICE) as? PowerManager
        val wakeLock = powerManager?.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "Adhkar:QuietHoursBootWakeLock")?.apply {
            setReferenceCounted(false)
            acquire(15 * 1000L) // 15s max safety timeout for boot re-arm
        }

        try {
            val savedJson = QuietHoursScheduler.getSchedules(context)
            if (!savedJson.isNullOrEmpty()) {
                QuietHoursScheduler.scheduleAll(context, savedJson)
                Log.i(TAG, "Successfully re-armed Quiet Hours exact alarms and reconciled DND state after $action.")
            } else {
                Log.d(TAG, "No persisted Quiet Hours schedules found during $action.")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error reconciling Quiet Hours on $action: ${e.message}", e)
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
