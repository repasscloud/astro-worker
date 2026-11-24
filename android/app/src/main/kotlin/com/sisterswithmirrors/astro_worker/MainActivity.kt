package com.sisterswithmirrors.astro_worker

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var widgetChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
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
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
