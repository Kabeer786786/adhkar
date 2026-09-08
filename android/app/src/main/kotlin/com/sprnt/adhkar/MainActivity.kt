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
    private val CHANNEL_QUIET_HOURS = "com.sprnt.adhkar/quiet_hours"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_QUIET_HOURS)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isDndPermissionGranted" -> {
                        val granted = QuietHoursScheduler.hasDndPermission(this)
                        result.success(granted)
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
                            // Try opening Android's native Do Not Disturb automation/schedules page
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
                        val enable = call.argument<Boolean>("enable") ?: false
                        QuietHoursScheduler.applyDndMode(this, enable)
                        result.success(true)
                    }

                    "isQuietHoursActive" -> {
                        val active = QuietHoursScheduler.isAnyQuietHoursActiveNow(this)
                        result.success(active)
                    }

                    "getDndFilter" -> {
                        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
                        if (nm != null && Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            result.success(nm.currentInterruptionFilter)
                        } else {
                            result.success(1) // INTERRUPTION_FILTER_ALL
                        }
                    }

                    else -> result.notImplemented()
                }
            }
    }
}
