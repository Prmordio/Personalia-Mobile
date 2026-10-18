package com.personalia.personalia_app

import android.app.Service
import android.content.Intent
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import kotlin.math.max

/** Runs only during an explicitly started rest, including without exact alarms. */
class WorkoutRestService : Service() {
    private val handler = Handler(Looper.getMainLooper())
    private var wakeLock: PowerManager.WakeLock? = null
    private val tick = object : Runnable {
        override fun run() {
            // read persists expiry and sends the next-series alert exactly once.
            val state = WorkoutLive.read(this@WorkoutRestService)
            if (state == null || state.getString("phase") != "rest" || !state.getBoolean("running")) {
                stopForeground(STOP_FOREGROUND_DETACH)
                stopSelf()
                return
            }
            WorkoutLive.show(this@WorkoutRestService, state)
            val deadline = state.getLong("anchor") + state.getInt("seconds") * 1000L
            handler.postDelayed(this, (deadline - System.currentTimeMillis()).coerceIn(1L, 1000L))
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        handler.removeCallbacks(tick)
        val state = WorkoutLive.read(this)
        if (state == null) {
            stopSelf()
            return START_NOT_STICKY
        }
        startForeground(WorkoutLive.ID, WorkoutLive.notification(this, state))
        if (state.getString("phase") != "rest" || !state.getBoolean("running")) {
            stopForeground(STOP_FOREGROUND_DETACH)
            stopSelf()
            return START_NOT_STICKY
        }
        wakeLock?.let { if (it.isHeld) it.release() }
        val deadline = state.getLong("anchor") + state.getInt("seconds") * 1000L
        // Bounded to this rest, released immediately on pause, expiry or finish.
        wakeLock = getSystemService(PowerManager::class.java)
            .newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "personalia:workoutRest").apply {
                acquire(max(1L, deadline - System.currentTimeMillis()) + 5000L)
            }
        handler.post(tick)
        return START_STICKY
    }

    override fun onDestroy() {
        handler.removeCallbacks(tick)
        wakeLock?.let { if (it.isHeld) it.release() }
        wakeLock = null
        stopForeground(STOP_FOREGROUND_DETACH)
        super.onDestroy()
    }
}
