package com.sisterswithmirrors.astro_worker

import android.Manifest
import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import org.json.JSONException
import org.json.JSONObject
import java.util.Calendar
import java.util.TimeZone

class AstronomyReminderReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            AstronomyReminders.FIRE -> AstronomyReminders.deliver(context)
            Intent.ACTION_TIME_CHANGED, Intent.ACTION_BOOT_COMPLETED ->
                LunarWidgetProvider.refreshFromCache(context)
        }
        AstronomyReminders.reconcile(context)
    }
}

internal object AstronomyReminders {
    const val FIRE = "com.sisterswithmirrors.astroworker.REMINDER"
    private const val CHANNEL = "astronomy_events"
    private const val PLAN = "plan"
    private const val DELIVERED = "delivered"
    private const val DELIVERY_WINDOW = 2 * 60 * 60 * 1000L

    private data class Event(val id: String, val title: String, val due: Long, val instant: Long)

    private data class Plan(
        val events: List<Event>,
        val zone: String,
        val quietFrom: Int,
        val quietUntil: Int
    ) {
        fun quietAt(time: Long): Boolean {
            if (quietFrom < 0 || quietUntil < 0) return false
            val timezone = if (zone == "device") TimeZone.getDefault() else TimeZone.getTimeZone(zone)
            val calendar = Calendar.getInstance(timezone).apply { timeInMillis = time }
            val minute = calendar.get(Calendar.HOUR_OF_DAY) * 60 + calendar.get(Calendar.MINUTE)
            return if (quietFrom < quietUntil) minute in quietFrom until quietUntil
            else minute >= quietFrom || minute < quietUntil
        }
    }

    private fun prefs(context: Context) =
        context.getSharedPreferences("astronomy_reminders", Context.MODE_PRIVATE)

    fun prepareChannel(context: Context) {
        if (Build.VERSION.SDK_INT >= 26) {
            context.getSystemService(NotificationManager::class.java).createNotificationChannel(
                NotificationChannel(CHANNEL, "Astronomy events", NotificationManager.IMPORTANCE_DEFAULT)
            )
        }
    }

    fun canNotify(context: Context): Boolean {
        if (Build.VERSION.SDK_INT >= 33 &&
            context.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED
        ) return false
        val manager = context.getSystemService(NotificationManager::class.java)
        if (!manager.areNotificationsEnabled()) return false
        return Build.VERSION.SDK_INT < 26 ||
            manager.getNotificationChannel(CHANNEL)?.importance != NotificationManager.IMPORTANCE_NONE
    }

    fun replace(context: Context, source: String): Boolean {
        val plan = parse(source) ?: return false
        val preferences = prefs(context)
        val ids = plan.events.map { it.id }.toSet()
        val retained = preferences.getStringSet(DELIVERED, emptySet()).orEmpty().intersect(ids)
        preferences.edit().putString(PLAN, source).putStringSet(DELIVERED, retained).apply()
        reconcile(context)
        return true
    }

    fun reconcile(context: Context) {
        val alarms = context.getSystemService(AlarmManager::class.java)
        val action = PendingIntent.getBroadcast(
            context, 0, Intent(context, AstronomyReminderReceiver::class.java).setAction(FIRE),
            PendingIntent.FLAG_IMMUTABLE
        )
        val plan = current(context)
        val now = System.currentTimeMillis()
        val delivered = prefs(context).getStringSet(DELIVERED, emptySet()).orEmpty()
        val next = if (plan != null && canNotify(context)) {
            plan.events.firstOrNull { it.due > now && it.id !in delivered && !plan.quietAt(it.due) }
        } else null
        if (next == null) {
            alarms.cancel(action)
        } else {
            alarms.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, next.due, action)
        }
    }

    fun deliver(context: Context) {
        if (!canNotify(context)) return
        val plan = current(context) ?: return
        val now = System.currentTimeMillis()
        val preferences = prefs(context)
        val delivered = preferences.getStringSet(DELIVERED, emptySet()).orEmpty().toMutableSet()
        for (event in plan.events) {
            if (event.due !in (now - DELIVERY_WINDOW)..now || !delivered.add(event.id)) continue
            if (!plan.quietAt(event.due) && !plan.quietAt(now)) post(context, event)
        }
        preferences.edit().putStringSet(DELIVERED, delivered).apply()
    }

    @Suppress("DEPRECATION")
    private fun post(context: Context, event: Event) {
        prepareChannel(context)
        val activity = Intent(context, MainActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        val open = PendingIntent.getActivity(context, 0, activity, PendingIntent.FLAG_IMMUTABLE)
        val builder = if (Build.VERSION.SDK_INT >= 26) Notification.Builder(context, CHANNEL)
            else Notification.Builder(context)
        val notification = builder.setSmallIcon(R.drawable.ic_astronomy_reminder)
            .setContentTitle(event.title)
            .setContentText(if (event.instant == event.due) "Astronomy event" else "Upcoming astronomy event")
            .setContentIntent(open)
            .setAutoCancel(true)
            .setWhen(event.instant)
            .build()
        context.getSystemService(NotificationManager::class.java).notify(event.id, 0, notification)
    }

    private fun current(context: Context): Plan? = prefs(context).getString(PLAN, null)?.let(::parse)

    private fun parse(source: String): Plan? {
        if (source.length > 64 * 1024) return null
        val data = try {
            JSONObject(source)
        } catch (_: JSONException) {
            return null
        }
        val entries = data.optJSONArray("events") ?: return null
        if (entries.length() > 48) return null
        val zone = data.optString("zone")
        val from = data.optInt("quietFrom", -1)
        val until = data.optInt("quietUntil", -1)
        if (zone.length !in 1..128 || from !in -1..1439 || until !in -1..1439) return null
        val events = ArrayList<Event>()
        val seen = mutableSetOf<String>()
        for (index in 0 until entries.length()) {
            val entry = entries.optJSONObject(index) ?: return null
            val id = entry.optString("id")
            val title = entry.optString("title")
            val due = entry.optLong("due")
            val instant = entry.optLong("event")
            if (id.length !in 1..180 || title.length !in 1..120 || due <= 0 || instant < due || !seen.add(id)) {
                return null
            }
            events.add(Event(id, title, due, instant))
        }
        return Plan(events.sortedBy { it.due }, zone, from, until)
    }
}
