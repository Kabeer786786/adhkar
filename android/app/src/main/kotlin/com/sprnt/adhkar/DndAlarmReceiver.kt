package com.sprnt.adhkar

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.PowerManager
import android.util.Log

/**
 * Dedicated native BroadcastReceiver triggered by AlarmManager for DND enable/disable actions.
 *
 * Runs purely on native Android; does NOT launch Flutter or require any background isolate.
 */
class DndAlarmReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "DND_SCHEDULER"
        private const val WAKELOCK_TIMEOUT_MS = 10 * 1000L // 10 seconds max
    }

    override fun onReceive(context: Context, intent: Intent?) {
        if (intent == null) return
        val action = intent.action ?: return
        val scheduleId = intent.getStringExtra(DndScheduler.EXTRA_SCHEDULE_ID) ?: "dnd_primary"
        val scheduleTitle = intent.getStringExtra(DndScheduler.EXTRA_SCHEDULE_TITLE) ?: "Quiet Hours"

        Log.d(TAG, "DndAlarmReceiver received action=$action for schedule=$scheduleId ($scheduleTitle)")

        val pendingResult = goAsync()
        val powerManager = context.getSystemService(Context.POWER_SERVICE) as? PowerManager
        val wakeLock = powerManager?.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "Adhkar:DndAlarmWakeLock")?.apply {
            setReferenceCounted(false)
            acquire(WAKELOCK_TIMEOUT_MS)
        }

        try {
            when (action) {
                DndScheduler.ACTION_ENABLE_DND -> {
                    DndScheduler.onEnableAlarmTriggered(context, scheduleId, scheduleTitle)
                }

                DndScheduler.ACTION_DISABLE_DND -> {
                    DndScheduler.onDisableAlarmTriggered(context, scheduleId, scheduleTitle)
                }

                else -> {
                    Log.w(TAG, "DndAlarmReceiver received unknown action: $action")
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error handling alarm intent in DndAlarmReceiver: ${e.message}", e)
        } finally {
            try {
                if (wakeLock?.isHeld == true) {
                    wakeLock.release()
                }
            } catch (t: Throwable) {
                // Ignore wake lock release errors
            }
            pendingResult.finish()
        }
    }
}
