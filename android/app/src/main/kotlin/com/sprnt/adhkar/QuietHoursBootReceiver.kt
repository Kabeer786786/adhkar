package com.sprnt.adhkar

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class QuietHoursBootReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "QuietHoursBootReceiver"
    }

    override fun onReceive(context: Context, intent: Intent?) {
        val action = intent?.action ?: return
        Log.i(TAG, "System event received: $action. Re-evaluating and re-arming Quiet Hours alarms.")

        val savedJson = QuietHoursScheduler.getSchedules(context)
        if (!savedJson.isNullOrEmpty()) {
            QuietHoursScheduler.scheduleAll(context, savedJson)
            Log.i(TAG, "Successfully re-armed Quiet Hours exact alarms after $action.")
        }
    }
}
