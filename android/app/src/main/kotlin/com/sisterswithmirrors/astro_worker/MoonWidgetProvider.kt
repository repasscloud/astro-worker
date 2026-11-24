package com.sisterswithmirrors.astro_worker

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.widget.RemoteViews
import org.json.JSONObject
import java.text.NumberFormat

class MoonWidgetProvider : LunarWidgetProvider(R.layout.moon_widget)
class MoonGlanceProvider : LunarWidgetProvider(R.layout.moon_glance)
class LunarReflectionProvider : LunarWidgetProvider(R.layout.lunar_reflection)
class LunarColourProvider : LunarWidgetProvider(R.layout.lunar_colour)

abstract class LunarWidgetProvider(private val layout: Int) : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        if (ids.isNotEmpty()) {
            manager.updateAppWidget(ids, widgetViews(context, layout, currentMoon(context)))
        }
    }

    companion object {
        const val OPEN_MOON = "com.sisterswithmirrors.astroworker.OPEN_MOON"
        const val TARGET = "moon_section"
        private const val TIMELINE = "timeline"

        private val providers = mapOf(
            MoonWidgetProvider::class.java to R.layout.moon_widget,
            MoonGlanceProvider::class.java to R.layout.moon_glance,
            LunarReflectionProvider::class.java to R.layout.lunar_reflection,
            LunarColourProvider::class.java to R.layout.lunar_colour
        )

        private fun storage(context: Context) =
            context.getSharedPreferences("moon_widget", Context.MODE_PRIVATE)

        fun publish(context: Context, timeline: String): Boolean {
            val validated = MoonWidgetTimeline.parse(timeline) ?: return false
            storage(context).edit().putString(TIMELINE, timeline).apply()
            val manager = AppWidgetManager.getInstance(context)
            val entry = validated.at(System.currentTimeMillis())
            for ((type, layout) in providers) {
                val component = ComponentName(context, type)
                if (manager.getAppWidgetIds(component).isNotEmpty()) {
                    manager.updateAppWidget(component, widgetViews(context, layout, entry))
                }
            }
            return true
        }

        private fun widgetViews(context: Context, layout: Int, data: JSONObject?): RemoteViews {
            val section = when (layout) {
                R.layout.lunar_reflection -> "reflection"
                R.layout.lunar_colour -> "colour"
                R.layout.moon_widget -> "calendar"
                else -> "phase"
            }
            val open = Intent(context, MainActivity::class.java)
                .setAction(OPEN_MOON)
                .putExtra(TARGET, section)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            val tap = PendingIntent.getActivity(context, layout, open, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
            return RemoteViews(context.packageName, layout).apply {
                setOnClickPendingIntent(R.id.moon_widget, tap)
                if (data == null) return@apply
                val phase = data.optString("phase")
                val illumination = data.optDouble("illumination")
                when (layout) {
                    R.layout.moon_glance, R.layout.moon_widget -> {
                        if (data.has("waxing")) {
                            setImageViewBitmap(
                                R.id.moon_image,
                                moonArtwork(illumination, data.optBoolean("waxing"), data.optBoolean("south"))
                            )
                            setContentDescription(R.id.moon_image, phase)
                        }
                        if (layout == R.layout.moon_widget) {
                            setTextViewText(R.id.moon_phase, phase)
                            setTextViewText(
                                R.id.moon_detail,
                                context.getString(
                                    R.string.moon_widget_detail,
                                    NumberFormat.getPercentInstance().format(illumination)
                                )
                            )
                            val next = data.optString("nextPhase")
                            setTextViewText(
                                R.id.moon_next,
                                if (next.isBlank()) "" else context.getString(R.string.moon_widget_next, next)
                            )
                        }
                    }
                    R.layout.lunar_reflection -> {
                        if (data.has("reflection")) {
                            setTextViewText(R.id.moon_phase, phase)
                            setTextViewText(R.id.moon_detail, data.optString("reflection"))
                        } else if (data.has("waxing")) {
                            setTextViewText(R.id.moon_phase, phase)
                            setTextViewText(R.id.moon_detail, context.getString(R.string.reflection_disabled))
                        }
                    }
                    R.layout.lunar_colour -> {
                        val name = data.optString("colourName")
                        val ink = data.optLong("colourForeground").toInt()
                        val background = data.optLong("colourBackground").toInt()
                        if (name.isNotBlank() && (ink ushr 24) == 255 && (background ushr 24) == 255) {
                            setImageViewBitmap(R.id.colour_background, colourTile(background, 26f))
                            setImageViewBitmap(R.id.colour_swatch, colourTile(ink, 96f))
                            setTextColor(R.id.moon_phase, ink)
                            setTextColor(R.id.moon_detail, ink)
                            setTextViewText(R.id.moon_phase, name)
                        }
                    }
                }
            }
        }

        private fun colourTile(colour: Int, radius: Float): Bitmap {
            val size = 192
            val image = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
            val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = colour }
            Canvas(image).drawRoundRect(0f, 0f, size.toFloat(), size.toFloat(), radius, radius, paint)
            return image
        }

        private fun currentMoon(context: Context): JSONObject? =
            storage(context).getString(TIMELINE, null)?.let(MoonWidgetTimeline::parse)
                ?.at(System.currentTimeMillis())
    }
}
