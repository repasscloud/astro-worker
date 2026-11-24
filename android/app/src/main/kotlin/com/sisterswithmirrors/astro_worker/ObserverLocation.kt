package com.sisterswithmirrors.astro_worker

import android.Manifest
import android.app.Activity
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

internal class ObserverLocation(
    private val activity: Activity,
    messenger: BinaryMessenger
) {
    private val channel = MethodChannel(messenger, "astro_worker/observer_location")
    private val manager = activity.getSystemService(LocationManager::class.java)
    private val main = Handler(Looper.getMainLooper())
    private var pending: MethodChannel.Result? = null
    private var listening = false
    private val timeout = Runnable {
        finish { it.error("location_timeout", "No GPS fix was available.", null) }
    }

    private val listener = object : LocationListener {
        override fun onLocationChanged(location: Location) = complete(location)
        override fun onProviderDisabled(provider: String) = unavailable()
        override fun onProviderEnabled(provider: String) {}
        @Suppress("DEPRECATION")
        override fun onStatusChanged(provider: String?, status: Int, extras: Bundle?) {}
    }

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "gpsFix" -> request(result)
                "cancel" -> {
                    closeRequest()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun request(result: MethodChannel.Result) {
        if (pending != null) {
            result.error("location_busy", "A location request is in progress.", null)
            return
        }
        pending = result
        if (hasPrecisePermission()) {
            start()
        } else {
            activity.requestPermissions(
                arrayOf(Manifest.permission.ACCESS_FINE_LOCATION, Manifest.permission.ACCESS_COARSE_LOCATION),
                PERMISSION_REQUEST
            )
        }
    }

    fun onPermissionsResult(requestCode: Int) {
        if (requestCode != PERMISSION_REQUEST || pending == null) return
        if (hasPrecisePermission()) start() else denied()
    }

    private fun start() {
        try {
            if (!manager.isProviderEnabled(LocationManager.GPS_PROVIDER)) {
                unavailable()
                return
            }
            val cached = manager.getLastKnownLocation(LocationManager.GPS_PROVIDER)
            if (cached != null &&
                SystemClock.elapsedRealtimeNanos() - cached.elapsedRealtimeNanos in 0..300_000_000_000L
            ) {
                complete(cached)
                return
            }
            manager.requestLocationUpdates(LocationManager.GPS_PROVIDER, 0, 0f, listener, Looper.getMainLooper())
            listening = true
            main.postDelayed(timeout, 18_000)
        } catch (_: SecurityException) {
            denied()
        } catch (_: IllegalArgumentException) {
            unavailable()
        }
    }

    private fun hasPrecisePermission() =
        activity.checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED

    private fun complete(location: Location) = finish {
        it.success(mapOf("latitude" to location.latitude, "longitude" to location.longitude))
    }

    private fun unavailable() = finish {
        it.error("location_unavailable", "GPS is unavailable.", null)
    }

    private fun denied() = finish {
        it.error("location_denied", "Precise GPS permission was not granted.", null)
    }

    private fun finish(complete: (MethodChannel.Result) -> Unit) {
        main.removeCallbacks(timeout)
        if (listening) {
            listening = false
            try {
                manager.removeUpdates(listener)
            } catch (_: SecurityException) {
                // Permission can be revoked during a request.
            }
        }
        val result = pending
        pending = null
        if (result != null) complete(result)
    }

    private fun closeRequest() = finish { it.error("location_cancelled", "Location request cancelled.", null) }

    fun dispose() {
        channel.setMethodCallHandler(null)
        closeRequest()
    }

    companion object {
        private const val PERMISSION_REQUEST = 2502
    }
}
