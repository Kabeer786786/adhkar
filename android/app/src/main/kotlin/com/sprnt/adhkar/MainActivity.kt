package com.sprnt.adhkar

import android.app.KeyguardManager
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.view.WindowManager
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceActivity() {
    companion object {
        var pendingAlarmData: Map<String, Any?>? = null
        var alarmMethodChannel: MethodChannel? = null
    }

    private val CHANNEL_DND_SCHEDULER = "com.sprnt.adhkar/dnd_scheduler"
    private val CHANNEL_QUIET_HOURS = "com.sprnt.adhkar/quiet_hours"
    private val CHANNEL_ALARM_SCHEDULER = "com.sprnt.adhkar/alarm_scheduler"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        showOverLockscreen()
        handleAlarmIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        showOverLockscreen()
        handleAlarmIntent(intent)
    }

    private fun handleAlarmIntent(intent: Intent?) {
        if (intent == null) return
        val reminderId = intent.getStringExtra("reminder_id")
        val prayerName = intent.getStringExtra("prayer_name")
        if (!reminderId.isNullOrEmpty() || !prayerName.isNullOrEmpty()) {
            val data = mapOf(
                "reminder_id" to reminderId,
                "prayer_name" to prayerName,
                "alarm_title" to intent.getStringExtra("alarm_title"),
                "alarm_body" to intent.getStringExtra("alarm_body"),
                "sound_type" to intent.getStringExtra("sound_type"),
                "notif_id" to intent.getIntExtra("notif_id", 0),
                "sound" to intent.getBooleanExtra("sound", true),
                "vibration" to intent.getBooleanExtra("vibration", true)
            )
            pendingAlarmData = data
            AlarmStateManager.onAlarmStarted(this, data)
            alarmMethodChannel?.invokeMethod("onAlarmTriggered", data)
        }
    }

    override fun dispatchKeyEvent(event: android.view.KeyEvent): Boolean {
        if (AlarmStateManager.isAlarmActive()) {
            when (event.keyCode) {
                android.view.KeyEvent.KEYCODE_VOLUME_DOWN,
                android.view.KeyEvent.KEYCODE_VOLUME_UP,
                android.view.KeyEvent.KEYCODE_VOLUME_MUTE -> {
                    val volumeAction = AlarmInteractionSettings.getVolumeButtonAction(this)
                    if (volumeAction != VolumeButtonAction.DO_NOTHING) {
                        if (event.action == android.view.KeyEvent.ACTION_DOWN && event.repeatCount == 0) {
                            when (volumeAction) {
                                VolumeButtonAction.STOP_ALARM -> {
                                    AlarmStateManager.stopActiveAlarm(this, "VolumeButton")
                                }
                                VolumeButtonAction.SNOOZE_ALARM -> {
                                    AlarmStateManager.snoozeActiveAlarm(this, "VolumeButton")
                                }
                                VolumeButtonAction.DO_NOTHING -> {}
                            }
                        }
                        // Consume both ACTION_DOWN and ACTION_UP to prevent volume slider UI
                        return true
                    }
                }
            }
        }
        return super.dispatchKeyEvent(event)
    }

    override fun onKeyDown(keyCode: Int, event: android.view.KeyEvent?): Boolean {
        if (AlarmStateManager.isAlarmActive()) {
            when (keyCode) {
                android.view.KeyEvent.KEYCODE_VOLUME_DOWN,
                android.view.KeyEvent.KEYCODE_VOLUME_UP,
                android.view.KeyEvent.KEYCODE_VOLUME_MUTE -> {
                    val volumeAction = AlarmInteractionSettings.getVolumeButtonAction(this)
                    when (volumeAction) {
                        VolumeButtonAction.STOP_ALARM -> {
                            AlarmStateManager.stopActiveAlarm(this, "VolumeButton")
                            return true
                        }
                        VolumeButtonAction.SNOOZE_ALARM -> {
                            AlarmStateManager.snoozeActiveAlarm(this, "VolumeButton")
                            return true
                        }
                        VolumeButtonAction.DO_NOTHING -> {
                            return super.onKeyDown(keyCode, event)
                        }
                    }
                }
            }
        }
        return super.onKeyDown(keyCode, event)
    }

    private fun showOverLockscreen() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
            )
        }
        window.addFlags(
            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
            WindowManager.LayoutParams.FLAG_ALLOW_LOCK_WHILE_SCREEN_ON
        )
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val messenger = flutterEngine.dartExecutor.binaryMessenger

        // Dedicated Native Alarm Scheduler MethodChannel
        val alarmChannel = MethodChannel(messenger, CHANNEL_ALARM_SCHEDULER)
        alarmMethodChannel = alarmChannel
        alarmChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "scheduleAlarm" -> {
                    val id = call.argument<String>("id") ?: ""
                    val title = call.argument<String>("title") ?: "Reminder"
                    val body = call.argument<String>("body") ?: ""
                    val triggerAtMillis = (call.argument<Number>("triggerAtMillis"))?.toLong() ?: 0L
                    val sound = call.argument<Boolean>("sound") ?: true
                    val vibration = call.argument<Boolean>("vibration") ?: true
                    val soundType = call.argument<String>("soundType") ?: "Default Ringtone"
                    val prayerName = call.argument<String>("prayerName")
                    AlarmScheduler.scheduleAlarm(this, id, title, body, triggerAtMillis, sound, vibration, soundType, prayerName)
                    result.success(true)
                }
                "cancelAlarm" -> {
                    val id = call.argument<String>("id") ?: ""
                    AlarmScheduler.cancelAlarm(this, id)
                    result.success(true)
                }
                "cancelAllAlarms" -> {
                    AlarmScheduler.cancelAllAlarms(this)
                    result.success(true)
                }
                "cancelNotification" -> {
                    val reminderId = call.argument<String>("reminderId")
                    val prayerName = call.argument<String>("prayerName")
                    val notifId = (call.argument<Number>("notifId"))?.toInt()
                    val nm = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
                    if (!reminderId.isNullOrEmpty()) {
                        val id = Math.abs(reminderId.hashCode()) % 100000000
                        nm?.cancel(id)
                    }
                    if (!prayerName.isNullOrEmpty()) {
                        val id = Math.abs(prayerName.hashCode()) % 100000000
                        nm?.cancel(id)
                    }
                    if (notifId != null && notifId != 0) {
                        nm?.cancel(notifId)
                    }
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && nm != null) {
                        try {
                            for (activeNotif in nm.activeNotifications) {
                                if (activeNotif.notification.channelId == AlarmReceiver.CHANNEL_ID ||
                                    (notifId != null && notifId != 0 && activeNotif.id == notifId)) {
                                    nm.cancel(activeNotif.tag, activeNotif.id)
                                }
                            }
                        } catch (_: Exception) {}
                    }
                    result.success(true)
                }
                "getPendingAlarm" -> {
                    val pending = pendingAlarmData
                    pendingAlarmData = null
                    result.success(pending)
                }
                "canUseFullScreenIntent" -> {
                    val nm = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE && nm != null) {
                        result.success(nm.canUseFullScreenIntent())
                    } else {
                        result.success(true)
                    }
                }
                "openFullScreenIntentSettings" -> {
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                            val settingsIntent = Intent(Settings.ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT).apply {
                                data = android.net.Uri.parse("package:$packageName")
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            startActivity(settingsIntent)
                            result.success(true)
                        } else {
                            result.success(true)
                        }
                    } catch (e: Exception) {
                        result.error("FULL_SCREEN_INTENT_ERROR", e.message, null)
                    }
                }
                "isDeviceLocked" -> {
                    val km = getSystemService(Context.KEYGUARD_SERVICE) as? KeyguardManager
                    result.success(km?.isKeyguardLocked ?: false)
                }
                "getAlarmInteractionSettings" -> {
                    result.success(AlarmInteractionSettings.getAllSettings(this))
                }
                "saveAlarmInteractionSettings" -> {
                    val volumeAction = call.argument<String>("volumeButtonAction")
                    val screenOffAction = call.argument<String>("screenOffAction")
                    AlarmInteractionSettings.saveAllSettings(this, volumeAction, screenOffAction)
                    result.success(true)
                }
                "stopActiveAlarm" -> {
                    val reason = call.argument<String>("reason") ?: "UserStop"
                    val stopped = AlarmStateManager.stopActiveAlarm(this, reason)
                    result.success(stopped)
                }
                "snoozeActiveAlarm" -> {
                    val reason = call.argument<String>("reason") ?: "UserSnooze"
                    val minutes = (call.argument<Number>("minutes"))?.toInt() ?: 10
                    val snoozed = AlarmStateManager.snoozeActiveAlarm(this, reason, minutes)
                    result.success(snoozed)
                }
                "isAlarmActive" -> {
                    result.success(AlarmStateManager.isAlarmActive())
                }
                "notifyAlarmStarted" -> {
                    val reminderId = call.argument<String>("reminderId")
                    val title = call.argument<String>("title") ?: "Reminder"
                    val soundType = call.argument<String>("soundType") ?: "Default Ringtone"
                    val prayerName = call.argument<String>("prayerName")
                    val notifId = (call.argument<Number>("notifId"))?.toInt() ?: 0
                    val data = mapOf(
                        "reminder_id" to reminderId,
                        "alarm_title" to title,
                        "sound_type" to soundType,
                        "prayer_name" to prayerName,
                        "notif_id" to notifId
                    )
                    AlarmStateManager.onAlarmStarted(this, data)
                    result.success(true)
                }
                "notifyAlarmStopped" -> {
                    val reason = call.argument<String>("reason") ?: "FlutterAlarmStopped"
                    AlarmStateManager.stopActiveAlarm(this, reason)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        // Dedicated DND Scheduler MethodChannel (Requirement 13)
        MethodChannel(messenger, CHANNEL_DND_SCHEDULER).setMethodCallHandler { call, result ->
            when (call.method) {
                "isDndAccessGranted" -> {
                    result.success(DndScheduler.hasDndPermission(this))
                }

                "openDndAccessSettings" -> {
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            val intent = Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS).apply {
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            startActivity(intent)
                            result.success(true)
                        } else {
                            result.success(false)
                        }
                    } catch (e: Exception) {
                        result.error("DND_SETTINGS_ERROR", e.message, null)
                    }
                }

                "isNotificationAccessGranted" -> {
                    result.success(MyNotificationListener.isNotificationListenerAccessGranted(this))
                }

                "openNotificationAccess", "openNotificationAccessSettings" -> {
                    try {
                        val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS).apply {
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("NOTIFICATION_ACCESS_ERROR", e.message, null)
                    }
                }

                "setDndMode" -> {
                    try {
                        val enable = call.argument<Boolean>("enable") ?: false
                        val filter = call.argument<Int>("filter")
                        QuietHoursScheduler.applyDndMode(this, enable, filter)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("SET_DND_ERROR", e.message, null)
                    }
                }

                "setInterruptionFilter" -> {
                    try {
                        val filter = call.argument<Int>("filter") ?: NotificationManager.INTERRUPTION_FILTER_ALL
                        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && nm != null) {
                            if (nm.isNotificationPolicyAccessGranted) {
                                nm.setInterruptionFilter(filter)
                                result.success(true)
                            } else {
                                result.error("PERMISSION_DENIED", "Notification Policy Access not granted", null)
                            }
                        } else {
                            result.success(false)
                        }
                    } catch (e: Exception) {
                        result.error("SET_FILTER_ERROR", e.message, null)
                    }
                }

                "scheduleDnd" -> {
                    try {
                        val startHour = call.argument<Int>("startHour") ?: 22
                        val startMinute = call.argument<Int>("startMinute") ?: 0
                        val endHour = call.argument<Int>("endHour") ?: 6
                        val endMinute = call.argument<Int>("endMinute") ?: 0
                        val repeatDaily = call.argument<Boolean>("repeatDaily") ?: true
                        val weekdays = call.argument<List<Int>>("weekdays") ?: listOf(1, 2, 3, 4, 5, 6, 7)
                        val scheduleId = call.argument<String>("scheduleId") ?: "dnd_primary"
                        val title = call.argument<String>("title") ?: "Quiet Hours"

                        DndScheduler.scheduleDnd(
                            context = this,
                            startHour = startHour,
                            startMinute = startMinute,
                            endHour = endHour,
                            endMinute = endMinute,
                            repeatDaily = repeatDaily,
                            weekdays = weekdays,
                            scheduleId = scheduleId,
                            title = title
                        )
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("SCHEDULE_DND_ERROR", e.message, null)
                    }
                }

                "cancelDnd" -> {
                    try {
                        val scheduleId = call.argument<String>("scheduleId") ?: "dnd_primary"
                        val restoreDnd = call.argument<Boolean>("restoreDnd") ?: true
                        DndScheduler.cancelDnd(this, scheduleId, restoreDnd)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("CANCEL_DND_ERROR", e.message, null)
                    }
                }

                "getDndSchedule" -> {
                    try {
                        result.success(DndScheduler.getPersistedSchedule(this))
                    } catch (e: Exception) {
                        result.error("GET_SCHEDULE_ERROR", e.message, null)
                    }
                }

                "getCurrentDndState" -> {
                    try {
                        val filter = DndScheduler.getCurrentInterruptionFilter(this)
                        val isDndActive = filter != NotificationManager.INTERRUPTION_FILTER_ALL
                        val schedule = DndScheduler.getPersistedSchedule(this)
                        val adhkarOwnsDnd = schedule["adhkarOwnsDnd"] as? Boolean ?: false

                        result.success(
                            mapOf(
                                "filter" to filter,
                                "isDndActive" to isDndActive,
                                "adhkarOwnsDnd" to adhkarOwnsDnd
                            )
                        )
                    } catch (e: Exception) {
                        result.error("GET_DND_STATE_ERROR", e.message, null)
                    }
                }

                "canScheduleExactAlarms" -> {
                    result.success(DndScheduler.canScheduleExactAlarms(this))
                }

                "openExactAlarmSettings" -> {
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                            val intent = Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM).apply {
                                data = android.net.Uri.parse("package:$packageName")
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            startActivity(intent)
                            result.success(true)
                        } else {
                            result.success(true)
                        }
                    } catch (e: Exception) {
                        result.error("EXACT_ALARM_ERROR", e.message, null)
                    }
                }

                "isBatteryOptimizationIgnored" -> {
                    result.success(DndScheduler.isBatteryOptimizationIgnored(this))
                }

                "requestIgnoreBatteryOptimization" -> {
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                                data = android.net.Uri.parse("package:$packageName")
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            startActivity(intent)
                            result.success(true)
                        } else {
                            result.success(true)
                        }
                    } catch (e: Exception) {
                        try {
                            val intent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS).apply {
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            startActivity(intent)
                            result.success(true)
                        } catch (e2: Exception) {
                            result.error("BATTERY_OPT_ERROR", e2.message, null)
                        }
                    }
                }

                "isAutoStartSupported" -> {
                    result.success(AutoStartHelper.isAutoStartSupported())
                }

                "openAutoStartSettings" -> {
                    result.success(AutoStartHelper.openAutoStartSettings(this))
                }

                "getDeviceManufacturer" -> {
                    result.success(AutoStartHelper.getManufacturer())
                }

                else -> result.notImplemented()
            }
        }

        // Backward-compatible Quiet Hours MethodChannel
        MethodChannel(messenger, CHANNEL_QUIET_HOURS)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isDndPermissionGranted" -> {
                        result.success(DndScheduler.hasDndPermission(this))
                    }

                    "openDndSettings" -> {
                        try {
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                                val intent = Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS).apply {
                                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                }
                                startActivity(intent)
                                result.success(true)
                            } else {
                                result.success(false)
                            }
                        } catch (e: Exception) {
                            result.error("DND_SETTINGS_ERROR", e.message, null)
                        }
                    }

                    "openDndSchedulesSettings" -> {
                        try {
                            var intent = Intent("android.settings.ZEN_MODE_AUTOMATION_SETTINGS").apply {
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            if (packageManager.resolveActivity(intent, 0) != null) {
                                startActivity(intent)
                                result.success(true)
                            } else {
                                intent = Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS).apply {
                                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                }
                                startActivity(intent)
                                result.success(true)
                            }
                        } catch (e: Exception) {
                            val intent = Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS).apply {
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            startActivity(intent)
                            result.success(true)
                        }
                    }

                    "scheduleQuietHours" -> {
                        val schedulesJson = call.argument<String>("schedulesJson") ?: "[]"
                        QuietHoursScheduler.scheduleAll(this, schedulesJson)
                        result.success(true)
                    }

                    "cancelAllQuietHours" -> {
                        QuietHoursScheduler.cancelAll(this)
                        QuietHoursScheduler.applyDndMode(this, false)
                        result.success(true)
                    }

                    "setDndMode" -> {
                        try {
                            val enable = call.argument<Boolean>("enable") ?: false
                            val filter = call.argument<Int>("filter")
                            QuietHoursScheduler.applyDndMode(this, enable, filter)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("SET_DND_ERROR", e.message, null)
                        }
                    }

                    "setInterruptionFilter" -> {
                        try {
                            val filter = call.argument<Int>("filter") ?: NotificationManager.INTERRUPTION_FILTER_ALL
                            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && nm != null) {
                                if (nm.isNotificationPolicyAccessGranted) {
                                    nm.setInterruptionFilter(filter)
                                    result.success(true)
                                } else {
                                    result.error("PERMISSION_DENIED", "Notification Policy Access not granted", null)
                                }
                            } else {
                                result.success(false)
                            }
                        } catch (e: Exception) {
                            result.error("SET_FILTER_ERROR", e.message, null)
                        }
                    }

                    "isQuietHoursActive" -> {
                        val active = QuietHoursScheduler.isAnyQuietHoursActiveNow(this)
                        result.success(active)
                    }

                    "getDndFilter" -> {
                        result.success(DndScheduler.getCurrentInterruptionFilter(this))
                    }

                    "isBatteryOptimizationIgnored" -> {
                        result.success(DndScheduler.isBatteryOptimizationIgnored(this))
                    }

                    "requestIgnoreBatteryOptimization" -> {
                        try {
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                                val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                                    data = android.net.Uri.parse("package:$packageName")
                                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                }
                                startActivity(intent)
                                result.success(true)
                            } else {
                                result.success(true)
                            }
                        } catch (e: Exception) {
                            try {
                                val intent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS).apply {
                                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                }
                                startActivity(intent)
                                result.success(true)
                            } catch (e2: Exception) {
                                result.error("BATTERY_OPT_ERROR", e2.message, null)
                            }
                        }
                    }

                    "canScheduleExactAlarms" -> {
                        result.success(DndScheduler.canScheduleExactAlarms(this))
                    }

                    "openExactAlarmSettings" -> {
                        try {
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                                val intent = Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM).apply {
                                    data = android.net.Uri.parse("package:$packageName")
                                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                }
                                startActivity(intent)
                                result.success(true)
                            } else {
                                result.success(true)
                            }
                        } catch (e: Exception) {
                            result.error("EXACT_ALARM_ERROR", e.message, null)
                        }
                    }

                    "isAutoStartSupported" -> {
                        result.success(AutoStartHelper.isAutoStartSupported())
                    }

                    "openAutoStartSettings" -> {
                        result.success(AutoStartHelper.openAutoStartSettings(this))
                    }

                    "getDeviceManufacturer" -> {
                        result.success(AutoStartHelper.getManufacturer())
                    }

                    else -> result.notImplemented()
                }
            }

        // Generic / Example settings channel handler
        MethodChannel(messenger, "com.example/settings").setMethodCallHandler { call, result ->
            when (call.method) {
                "openNotificationAccess", "openNotificationAccessSettings" -> {
                    try {
                        val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS).apply {
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("NOTIFICATION_ACCESS_ERROR", e.message, null)
                    }
                }
                "isNotificationAccessGranted" -> {
                    result.success(MyNotificationListener.isNotificationListenerAccessGranted(this))
                }
                else -> result.notImplemented()
            }
        }
    }
}
