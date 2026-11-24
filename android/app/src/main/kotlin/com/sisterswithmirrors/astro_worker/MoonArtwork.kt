package com.sisterswithmirrors.astro_worker

import android.graphics.Bitmap
import android.graphics.Color
import kotlin.math.exp
import kotlin.math.hypot
import kotlin.math.sqrt

private data class Crater(val x: Double, val y: Double, val radius: Double, val depth: Double)

private val craters = listOf(
    Crater(-.43, -.38, .20, .30), Crater(.33, .17, .24, .32),
    Crater(.21, -.36, .32, .38), Crater(-.21, .26, .30, .26),
    Crater(-.50, .41, .12, .27), Crater(.46, -.25, .11, .24),
    Crater(.10, .56, .16, .25), Crater(.56, .51, .14, .25)
)

internal fun moonArtwork(illumination: Double, waxing: Boolean, south: Boolean): Bitmap {
    val size = 192
    val radius = size * .46
    val pixels = IntArray(size * size)
    val sunZ = 2 * illumination - 1
    val sunX = sqrt((1 - sunZ * sunZ).coerceAtLeast(0.0)) * if (waxing) 1 else -1
    val orientation = if (south) -1 else 1
    for (row in 0 until size) {
        for (column in 0 until size) {
            val x = orientation * (column + .5 - size / 2) / radius
            val y = orientation * (row + .5 - size / 2) / radius
            val radialSquared = x * x + y * y
            if (radialSquared > 1) continue
            val z = sqrt(1 - radialSquared)
            val sunlight = x * sunX + z * sunZ
            val terrain = craters.fold(.97) { shade, crater ->
                val d = hypot(x - crater.x, y - crater.y) / crater.radius
                val rim = d - 1
                shade - crater.depth * exp(-d * d * 2) + .06 * exp(-rim * rim * 22)
            }
            val grain = .94 + .12 * ((column * 47 + row * 71 + column * row * 11) % 97) / 97
            val brightness = if (sunlight > 0) 55 + 200 * sqrt(sunlight) else 16 + 10 * z
            val light = brightness * terrain * grain
            pixels[row * size + column] = Color.rgb(
                (light * 1.02).toInt().coerceIn(0, 255),
                light.toInt().coerceIn(0, 255),
                (light * 1.09).toInt().coerceIn(0, 255)
            )
        }
    }
    return Bitmap.createBitmap(pixels, size, size, Bitmap.Config.ARGB_8888)
}
