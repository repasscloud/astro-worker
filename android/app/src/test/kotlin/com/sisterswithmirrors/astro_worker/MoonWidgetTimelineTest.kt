package com.sisterswithmirrors.astro_worker

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Test

class MoonWidgetTimelineTest {
    private val entry = """
        {"schema":1,"generatedAt":"2025-01-01T00:00:00.000Z",
        "validUntil":"2025-01-01T01:00:00.000Z","zone":"UTC",
        "zodiac":"tropical","phase":"New Moon","illumination":0.01,
        "waxing":true,"south":false,"colourName":"Midnight Plum",
        "colourBackground":4281803327,"colourForeground":4294379007}
    """.trimIndent()
    private val start = 1735689600000L

    @Test
    fun returnsDataOnlyWithinTheValidInterval() {
        val timeline = MoonWidgetTimeline.parse("[$entry]")!!
        assertNull(timeline.at(start - 1))
        assertEquals("New Moon", timeline.at(start)?.optString("phase"))
        assertNotNull(timeline.at(start + 3_599_999))
        assertNull(timeline.at(start + 3_600_000))
        assertNull(MoonWidgetTimeline.parse("[]")!!.at(start))
    }

    @Test
    fun rejectsCorruptOrPartialReplacement() {
        assertNull(MoonWidgetTimeline.parse("{ invalid"))
        assertNull(MoonWidgetTimeline.parse("[$entry, $entry]"))
        assertNull(MoonWidgetTimeline.parse("[$entry, null]"))
        assertNull(MoonWidgetTimeline.parse("[${entry.replace("0.01", "1.25")}]"))
        assertNull(MoonWidgetTimeline.parse("[${entry.replace("01:00:00.000Z", "00:00:00.000Z")}]"))
        assertNull(MoonWidgetTimeline.parse("[${entry.replace("New Moon", "Unknown Phase")}]"))
    }
}
