package com.sprnt.adhkar

import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceActivity() {
    private val CHANNEL_DND_SCHEDULER = "com.sprnt.adhkar/dnd_scheduler"
    private val CHANNEL_QUIET_HOURS = "com.sprnt.adhkar/quiet_hours"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val messenger = flutterEngine.dartExecutor.binaryMessenger

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
