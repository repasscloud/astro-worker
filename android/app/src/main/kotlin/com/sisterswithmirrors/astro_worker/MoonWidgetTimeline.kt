package com.sisterswithmirrors.astro_worker

import org.json.JSONArray
import org.json.JSONException
import org.json.JSONObject
import java.text.ParsePosition
import java.text.SimpleDateFormat
import java.util.Locale
import java.util.TimeZone

internal class MoonWidgetTimeline private constructor(private val entries: List<Entry>) {
    private data class Entry(val from: Long, val until: Long, val data: JSONObject)

    fun at(now: Long): JSONObject? =
        entries.firstOrNull { now >= it.from && now < it.until }?.data

    companion object {
        private const val HOUR = 3_600_000L
        private val phases = setOf(
            "New Moon", "Waxing Crescent", "First Quarter", "Waxing Gibbous",
            "Full Moon", "Waning Gibbous", "Last Quarter", "Waning Crescent"
        )
        private val majorPhases = setOf("New Moon", "First Quarter", "Full Moon", "Last Quarter")

        fun parse(source: String): MoonWidgetTimeline? {
            if (source.length > 128 * 1024) return null
            val array = try {
                JSONArray(source)
            } catch (_: JSONException) {
                return null
            }
            if (array.length() > 64) return null

            val format = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.ROOT).apply {
                timeZone = TimeZone.getTimeZone("UTC")
                isLenient = false
            }
            fun instant(value: Any?): Long? {
                if (value !is String || value.length != 24) return null
                val position = ParsePosition(0)
                val date = format.parse(value, position) ?: return null
                return date.time.takeIf { position.index == value.length }
            }

            val entries = ArrayList<Entry>(array.length())
            for (index in 0 until array.length()) {
                val entry = array.optJSONObject(index) ?: return null
                if (entry.optInt("schema") != 1 || entry.optString("zodiac") != "tropical") return null
                val from = instant(entry.opt("generatedAt")) ?: return null
                val until = instant(entry.opt("validUntil")) ?: return null
                if (until - from !in 1..HOUR) return null
                val previous = entries.lastOrNull()
                if (previous != null && previous.until != from) return null
                val fraction = entry.opt("illumination") as? Number ?: return null
                if (fraction.toDouble() !in 0.0..1.0 || entry.optString("phase") !in phases) return null
                if (entry.optString("zone").length !in 1..128) return null
                if (!validArtworkFields(entry)) return null
                entries.add(Entry(from, until, entry))
            }
            if (entries.isNotEmpty() && entries.last().until - entries.first().from > 48 * HOUR) {
                return null
            }
            return MoonWidgetTimeline(entries)
        }

        private fun validArtworkFields(entry: JSONObject): Boolean {
            // Older app builds published phase and illumination only.
            if (!entry.has("waxing")) return true
            if (entry.opt("waxing") !is Boolean || entry.opt("south") !is Boolean) return false
            if (entry.optString("colourName").length !in 1..64) return false
            for (key in listOf("colourBackground", "colourForeground")) {
                val colour = entry.opt(key) as? Number ?: return false
                if (colour.toLong() !in 0xff000000L..0xffffffffL) return false
            }
            if (entry.has("reflection") && entry.optString("reflection").length !in 1..180) return false
            return !entry.has("nextPhase") || entry.optString("nextPhase") in majorPhases
        }
    }
}
