package com.sprnt.adhkar

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * Dedicated native BroadcastReceiver triggered when the system clock or timezone changes.
 * Ensures the DND schedule remains aligned with the user's intended local clock time.
 */
class DndTimeChangeReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "DND_SCHEDULER"
    }

    override fun onReceive(context: Context, intent: Intent?) {
        val action = intent?.action ?: return
        Log.i(TAG, "DND_SCHEDULER: Time or timezone change detected: $action. Recalculating schedule occurrences...")

        val pendingResult = goAsync()
        try {
            DndScheduler.reconcileCurrentState(context, "TIME_CHANGE: $action")
        } catch (e: Exception) {
            Log.e(TAG, "Error handling time change in DndTimeChangeReceiver: ${e.message}", e)
        } finally {
            pendingResult.finish()
        }
    }
}
