package com.sisterswithmirrors.astro_worker

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var widgetChannel: MethodChannel? = null
    private var remindersChannel: MethodChannel? = null
    private var permissionResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        remindersChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger, "astro_worker/reminders"
        ).also { channel ->
            channel.setMethodCallHandler { call, result ->
                when (call.method) {
                    "requestPermission" -> requestReminderPermission(result)
                    "replace" -> {
                        val source = call.arguments as? String
                        if (source != null && AstronomyReminders.replace(this, source)) {
                            result.success(null)
                        } else {
                            result.error("invalid_reminders", "The reminders could not be replaced.", null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
        }
        widgetChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "astro_worker/moon_widget"
        ).also { channel ->
            channel.setMethodCallHandler { call, result ->
                when (call.method) {
                    "consumeOpenMoon" -> {
                        val open = intent.action == LunarWidgetProvider.OPEN_MOON
                        val target = if (open) widgetTarget(intent) else null
                        if (open) intent.action = null
                        result.success(target)
                    }
                    "publish" -> {
                        val timeline = call.arguments as? String
                        if (timeline != null && LunarWidgetProvider.publish(this, timeline)) {
                            result.success(null)
                        } else {
                            result.error("invalid_timeline", "The Moon widget timeline is invalid.", null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    private fun requestReminderPermission(result: MethodChannel.Result) {
        AstronomyReminders.prepareChannel(this)
        if (Build.VERSION.SDK_INT >= 33 &&
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED
        ) {
            if (permissionResult != null) {
                result.success(false)
                return
            }
            permissionResult = result
            requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), REMINDER_PERMISSION)
        } else {
            result.success(AstronomyReminders.canNotify(this))
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int, permissions: Array<out String>, grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == REMINDER_PERMISSION) {
            permissionResult?.success(AstronomyReminders.canNotify(this))
            permissionResult = null
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        if (intent.action == LunarWidgetProvider.OPEN_MOON) {
            widgetChannel?.invokeMethod("openMoon", widgetTarget(intent), object : MethodChannel.Result {
                override fun success(result: Any?) {
                    intent.action = null
                }
                override fun error(code: String, message: String?, details: Any?) {}
                override fun notImplemented() {}
            })
        }
    }

    private fun widgetTarget(intent: Intent): String =
        intent.getStringExtra(LunarWidgetProvider.TARGET) ?: "phase"

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        widgetChannel?.setMethodCallHandler(null)
        widgetChannel = null
        remindersChannel?.setMethodCallHandler(null)
        remindersChannel = null
        permissionResult?.success(false)
        permissionResult = null
        super.cleanUpFlutterEngine(flutterEngine)
    }

    companion object {
        private const val REMINDER_PERMISSION = 2501
    }
}
