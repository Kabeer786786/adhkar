package com.sprnt.adhkar

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.util.Log

object AutoStartHelper {
    private const val TAG = "AutoStartHelper"

    fun getManufacturer(): String {
        return Build.MANUFACTURER.lowercase()
    }

    fun isAutoStartSupported(): Boolean {
        val m = getManufacturer()
        return m.contains("xiaomi") ||
                m.contains("redmi") ||
                m.contains("poco") ||
                m.contains("oppo") ||
                m.contains("realme") ||
                m.contains("vivo") ||
                m.contains("iqoo") ||
                m.contains("oneplus") ||
                m.contains("huawei") ||
                m.contains("honor") ||
                m.contains("samsung")
    }

    fun openAutoStartSettings(context: Context): Boolean {
        val packageName = context.packageName
        val m = getManufacturer()
        val candidateIntents = mutableListOf<Intent>()

        when {
            m.contains("xiaomi") || m.contains("redmi") || m.contains("poco") -> {
                candidateIntents.add(
                    Intent().setComponent(
                        ComponentName(
                            "com.miui.securitycenter",
                            "com.miui.permcenter.autostart.AutoStartManagementActivity"
                        )
                    )
                )
                candidateIntents.add(Intent("miui.intent.action.OP_AUTO_START").addCategory(Intent.CATEGORY_DEFAULT))
            }

            m.contains("oppo") || m.contains("realme") -> {
                candidateIntents.add(
                    Intent().setComponent(
                        ComponentName(
                            "com.coloros.safecenter",
                            "com.coloros.safecenter.permission.startup.StartupAppListActivity"
                        )
                    )
                )
                candidateIntents.add(
                    Intent().setComponent(
                        ComponentName(
                            "com.coloros.safecenter",
                            "com.coloros.safecenter.startupapp.StartupAppListActivity"
                        )
                    )
                )
                candidateIntents.add(
                    Intent().setComponent(
                        ComponentName(
                            "com.oppo.safe",
                            "com.oppo.safe.permission.startup.StartupAppListActivity"
                        )
                    )
                )
                candidateIntents.add(
                    Intent().setComponent(
                        ComponentName(
                            "com.coloros.safecenter",
                            "com.coloros.safecenter.permission.startupApp.StartupAppListActivity"
                        )
                    )
                )
            }

            m.contains("vivo") || m.contains("iqoo") -> {
                candidateIntents.add(
                    Intent().setComponent(
                        ComponentName(
                            "com.iqoo.secure",
                            "com.iqoo.secure.ui.phoneoptimize.AddWhiteListActivity"
                        )
                    )
                )
                candidateIntents.add(
                    Intent().setComponent(
                        ComponentName(
                            "com.vivo.permissionmanager",
                            "com.vivo.permissionmanager.activity.BgStartUpManagerActivity"
                        )
                    )
                )
                candidateIntents.add(
                    Intent().setComponent(
                        ComponentName(
                            "com.iqoo.secure",
                            "com.iqoo.secure.ui.phoneoptimize.BgStartUpManager"
                        )
                    )
                )
            }

            m.contains("oneplus") -> {
                candidateIntents.add(
                    Intent().setComponent(
                        ComponentName(
                            "com.oneplus.security",
                            "com.oneplus.security.chainlaunch.view.ChainLaunchAppListActivity"
                        )
                    )
                )
            }

            m.contains("huawei") || m.contains("honor") -> {
                candidateIntents.add(
                    Intent().setComponent(
                        ComponentName(
                            "com.huawei.systemmanager",
                            "com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity"
                        )
                    )
                )
                candidateIntents.add(
                    Intent().setComponent(
                        ComponentName(
                            "com.huawei.systemmanager",
                            "com.huawei.systemmanager.optimize.bootstart.BootStartActivity"
                        )
                    )
                )
            }

            m.contains("samsung") -> {
                candidateIntents.add(
                    Intent().setComponent(
                        ComponentName(
                            "com.samsung.android.lool",
                            "com.samsung.android.sm.ui.battery.BatteryActivity"
                        )
                    )
                )
                candidateIntents.add(
                    Intent().setComponent(
                        ComponentName(
                            "com.samsung.android.sm",
                            "com.samsung.android.sm.ui.battery.BatteryActivity"
                        )
                    )
                )
                candidateIntents.add(
                    Intent().setComponent(
                        ComponentName(
                            "com.samsung.android.sm",
                            "com.samsung.android.sm.ui.AppListActivity"
                        )
                    )
                )
            }
        }

        // Generic fallback to application details settings
        candidateIntents.add(
            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.parse("package:$packageName")
            }
        )

        for (intent in candidateIntents) {
            try {
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                if (intent.resolveActivity(context.packageManager) != null) {
                    context.startActivity(intent)
                    Log.d(TAG, "Launched autostart intent: ${intent.component ?: intent.action}")
                    return true
                }
            } catch (e: Exception) {
                Log.w(TAG, "Failed launching intent: ${e.message}")
            }
        }

        return false
    }
}
