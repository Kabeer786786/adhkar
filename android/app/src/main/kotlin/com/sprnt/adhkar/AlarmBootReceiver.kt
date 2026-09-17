package com.sprnt.adhkar

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * Reschedules alarms upon system boot, time updates, or app package updates.
 */
class AlarmBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        val action = intent?.action ?: return
        Log.i("AdhkarAlarmBoot", "System broadcast received in AlarmBootReceiver: $action. Rescheduling alarms...")
        AlarmScheduler.rescheduleAll(context)
    }
}
