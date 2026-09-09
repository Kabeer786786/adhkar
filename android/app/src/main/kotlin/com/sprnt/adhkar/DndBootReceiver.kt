package com.sprnt.adhkar

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * Dedicated native BroadcastReceiver triggered when the device boots or app package is replaced.
 * Reconciles schedule state and restores AlarmManager alarms without requiring the user to launch the app.
 */
class DndBootReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "DND_SCHEDULER"
    }

    override fun onReceive(context: Context, intent: Intent?) {
        val action = intent?.action ?: return
        Log.i(TAG, "DND_SCHEDULER: Boot received: $action. Restoring schedule...")

        val pendingResult = goAsync()
        try {
            DndScheduler.reconcileCurrentState(context, "BOOT_OR_PACKAGE_EVENT: $action")
        } catch (e: Exception) {
            Log.e(TAG, "Error restoring schedule on boot: ${e.message}", e)
        } finally {
            pendingResult.finish()
        }
    }
}
