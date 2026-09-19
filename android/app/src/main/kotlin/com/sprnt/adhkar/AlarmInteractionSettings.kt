package com.sprnt.adhkar

import android.content.Context
import android.content.SharedPreferences

enum class VolumeButtonAction(val value: String) {
    STOP_ALARM("stopAlarm"),
    SNOOZE_ALARM("snoozeAlarm"),
    DO_NOTHING("doNothing");

    companion object {
        fun fromValue(value: String?): VolumeButtonAction {
            return entries.firstOrNull { it.value.equals(value, ignoreCase = true) }
                ?: STOP_ALARM
        }
    }
}

enum class ScreenOffAction(val value: String) {
    STOP_ALARM("stopAlarm"),
    CONTINUE_ALARM("continueAlarm");

    companion object {
        fun fromValue(value: String?): ScreenOffAction {
            return entries.firstOrNull { it.value.equals(value, ignoreCase = true) }
                ?: STOP_ALARM
        }
    }
}

object AlarmInteractionSettings {
    private const val PREFS_NAME = "adhkar_alarm_interaction_prefs"
    private const val KEY_VOLUME_BUTTON_ACTION = "volume_button_action"
    private const val KEY_SCREEN_OFF_ACTION = "screen_off_action"

    private fun getPrefs(context: Context): SharedPreferences {
        return context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    }

    fun getVolumeButtonAction(context: Context): VolumeButtonAction {
        val str = getPrefs(context).getString(KEY_VOLUME_BUTTON_ACTION, VolumeButtonAction.STOP_ALARM.value)
        return VolumeButtonAction.fromValue(str)
    }

    fun setVolumeButtonAction(context: Context, action: VolumeButtonAction) {
        getPrefs(context).edit().putString(KEY_VOLUME_BUTTON_ACTION, action.value).apply()
    }

    fun getScreenOffAction(context: Context): ScreenOffAction {
        val str = getPrefs(context).getString(KEY_SCREEN_OFF_ACTION, ScreenOffAction.STOP_ALARM.value)
        return ScreenOffAction.fromValue(str)
    }

    fun setScreenOffAction(context: Context, action: ScreenOffAction) {
        getPrefs(context).edit().putString(KEY_SCREEN_OFF_ACTION, action.value).apply()
    }

    fun getAllSettings(context: Context): Map<String, String> {
        return mapOf(
            "volumeButtonAction" to getVolumeButtonAction(context).value,
            "screenOffAction" to getScreenOffAction(context).value
        )
    }

    fun saveAllSettings(context: Context, volumeAction: String?, screenOffAction: String?) {
        val editor = getPrefs(context).edit()
        if (volumeAction != null) {
            editor.putString(KEY_VOLUME_BUTTON_ACTION, VolumeButtonAction.fromValue(volumeAction).value)
        }
        if (screenOffAction != null) {
            editor.putString(KEY_SCREEN_OFF_ACTION, ScreenOffAction.fromValue(screenOffAction).value)
        }
        editor.apply()
    }
}
