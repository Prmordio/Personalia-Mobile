package com.personalia.personalia_app

import android.app.*
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.widget.RemoteViews
import org.json.JSONObject
import kotlin.math.max
import kotlin.math.min

/** Native state shared by Flutter, notification actions and the rest service. */
object WorkoutLive {
    const val ID = 73140
    private const val ALERT_ID = 73141
    private const val CHANNEL = "workout_execution_controls"
    private fun prefs(c: Context) = c.getSharedPreferences("workout_live", Context.MODE_PRIVATE)
    private fun manager(c: Context) = c.getSystemService(NotificationManager::class.java)
    private fun exactAllowed(c: Context) = Build.VERSION.SDK_INT < 31 ||
        c.getSystemService(AlarmManager::class.java).canScheduleExactAlarms()

    @Synchronized fun read(c: Context): JSONObject? {
        val raw = prefs(c).getString("state", null) ?: return null
        val state = try { JSONObject(raw) } catch (_: Exception) { end(c); return null }
        val today = java.text.SimpleDateFormat("yyyy-MM-dd", java.util.Locale.US).format(java.util.Date())
        if (state.optString("date") != today) { end(c); return null }
        val migrated = migrateRestFlow(state)
        if (finishRest(state)) {
            save(c, state)
            c.getSystemService(AlarmManager::class.java).cancel(alarmIntent(c))
            show(c, state, alert = true)
        } else if (migrated) {
            save(c, state)
            show(c, state)
        }
        state.put("exactAlarmAvailable", exactAllowed(c))
        return state
    }

    private fun migrateRestFlow(s: JSONObject): Boolean {
        if (s.optInt("flowVersion") == 2) return false
        val phase = s.getString("phase")
        if (phase == "awaitRest") s.put("pendingRestCounted", true)
        if (phase == "exercise" || phase == "awaitRest") s.put("phase", "ready").put("running", false).put("seconds", 0)
        s.put("flowVersion", 2).put("revision", s.getLong("revision") + 1)
        return true
    }

    /** Persist the terminal state instead of only repainting an expired timer. */
    private fun finishRest(s: JSONObject): Boolean {
        if (s.getString("phase") != "rest" || !s.getBoolean("running") ||
            System.currentTimeMillis() < s.getLong("anchor") + s.getInt("seconds") * 1000L) return false
        s.put("restExpiredFromRevision", s.getLong("revision"))
        val completed = s.getJSONArray("completed").getInt(s.getInt("index"))
        val sets = s.getJSONArray("exercises").getJSONObject(s.getInt("index")).getInt("sets")
        s.put("phase", if (completed >= sets) "done" else "ready").put("running", false).put("seconds", 0)
            .put("revision", s.getLong("revision") + 1)
        return true
    }

    fun restore(c: Context) {
        manager(c).cancel(ALERT_ID)
        val s = read(c) ?: return
        schedule(c, s)
        show(c, s)
    }

    @Synchronized fun prepare(c: Context, raw: String): JSONObject {
        end(c)
        val state = JSONObject(raw).put("flowVersion", 2)
        save(c, state)
        schedule(c, state)
        show(c, state)
        return read(c) ?: state
    }

    @Synchronized fun localize(c: Context, raw: String): JSONObject? {
        val state = read(c) ?: return null
        state.put("labels", JSONObject(raw))
        save(c, state)
        show(c, state)
        return state
    }

    private fun hasWeight(s: JSONObject): Boolean {
        val name = s.getJSONArray("exercises").getJSONObject(s.getInt("index")).getString("name")
        return !s.optJSONObject("weights")?.optString(name, "").isNullOrBlank()
    }

    @Synchronized fun weight(c: Context, id: String, name: String, value: String): JSONObject? {
        val s = read(c) ?: return null
        if (s.getString("id") != id) return s
        val exercises = s.getJSONArray("exercises")
        if (!(0 until exercises.length()).any { exercises.getJSONObject(it).getString("name") == name }) return s
        val weights = s.optJSONObject("weights") ?: JSONObject()
        weights.put(name, value)
        s.put("weights", weights)
        save(c, s)
        show(c, s)
        return s
    }

    private fun save(c: Context, s: JSONObject) {
        // commit before returning: a following receiver/process must see the new revision.
        prefs(c).edit().putString("state", s.toString()).commit()
    }

    private fun alarmIntent(c: Context) = PendingIntent.getBroadcast(c, ALERT_ID,
        Intent(c, WorkoutLiveReceiver::class.java).setAction("restEnded"),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)

    @Synchronized fun end(c: Context) {
        c.stopService(Intent(c, WorkoutRestService::class.java))
        c.getSystemService(AlarmManager::class.java).cancel(alarmIntent(c))
        manager(c).cancel(ID); manager(c).cancel(ALERT_ID)
        prefs(c).edit().remove("state").commit()
    }

    @Synchronized fun action(c: Context, action: String, id: String, revision: Long): JSONObject? {
        val s = read(c) ?: return null
        if (s.getString("id") != id || (s.getLong("revision") != revision &&
            !(action == "rest" && s.optLong("restExpiredFromRevision", -1) == revision))) return s
        val index = s.getInt("index")
        val exercises = s.getJSONArray("exercises")
        val exercise = exercises.getJSONObject(index)
        val completed = s.getJSONArray("completed")
        val count = completed.getInt(index)
        val phase = s.getString("phase")
        val running = s.getBoolean("running")
        val now = System.currentTimeMillis()
        var seconds = s.getInt("seconds")
        if (running) {
            val delta = ((now - s.getLong("anchor")) / 1000).toInt()
            seconds = if (phase == "rest") max(0, seconds - delta) else seconds + delta
        }
        s.put("seconds", seconds).put("anchor", now)
        when {
            action == "rest" && phase == "ready" && count < exercise.getInt("sets") -> {
                if (s.isNull("startedAt")) s.put("startedAt", now)
                if (!s.optBoolean("pendingRestCounted")) completed.put(index, count + 1)
                s.remove("pendingRestCounted")
                s.put("phase", "rest").put("running", true).put("seconds", exercise.getInt("restSeconds"))
            }
            action == "toggle" && phase == "rest" -> s.put("running", !running)
            action == "add" && phase == "rest" -> s.put("seconds", seconds + 30)
            action == "skip" && phase == "rest" -> s.put("phase", if (count >= exercise.getInt("sets")) "done" else "ready").put("running", false).put("seconds", 0)
            action == "next" && phase == "done" && hasWeight(s) && index + 1 < exercises.length() -> s.put("index", index + 1).put("phase", "ready").put("running", false).put("seconds", 0)
            else -> return s
        }
        s.put("revision", s.getLong("revision") + 1)
        s.remove("restExpiredFromRevision")
        finishRest(s)
        save(c, s)
        manager(c).cancel(ALERT_ID)
        schedule(c, s)
        show(c, s)
        return s
    }

    private fun schedule(c: Context, s: JSONObject) {
        val alarm = c.getSystemService(AlarmManager::class.java)
        val intent = alarmIntent(c)
        alarm.cancel(intent)
        if (s.getString("phase") != "rest" || !s.getBoolean("running")) {
            c.stopService(Intent(c, WorkoutRestService::class.java))
            return
        }
        val service = Intent(c, WorkoutRestService::class.java)
        if (Build.VERSION.SDK_INT >= 26) c.startForegroundService(service) else c.startService(service)
        val at = s.getLong("anchor") + s.getInt("seconds") * 1000L
        if (Build.VERSION.SDK_INT < 31 || alarm.canScheduleExactAlarms()) {
            alarm.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, intent)
        } else {
            alarm.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, intent)
        }
    }

    fun restEnded(c: Context) {
        // read performs the transition and alerts once, including after a late
        // inexact alarm or a process restart. A duplicate alarm does nothing.
        read(c)
    }

    private fun openApp(c: Context) = PendingIntent.getActivity(c, ID,
        Intent(c, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)

    fun show(c: Context, s: JSONObject, alert: Boolean = false) {
        try { manager(c).notify(ID, notification(c, s, alert)) } catch (_: SecurityException) { }
    }

    fun notification(c: Context, s: JSONObject, alert: Boolean = false): Notification {
        val nm = manager(c)
        fun text(key: String, fallback: String) = s.optJSONObject("labels")?.optString(key, fallback) ?: fallback
        // LOW is hidden on lock screens that filter ambient notifications. Keep
        // these active workout controls visible without playing a sound.
        if (Build.VERSION.SDK_INT >= 26) nm.createNotificationChannel(
            NotificationChannel(CHANNEL, text("workout", "Workout"), NotificationManager.IMPORTANCE_DEFAULT).apply {
                setSound(null, null)
                enableVibration(false)
                setShowBadge(false)
            })
        // Keep the end-of-rest alert on the SAME notification ID. A separate
        // notification makes Android group the cards and hide the action button.
        val channel = if (alert) "workout_rest_end" else CHANNEL
        if (alert && Build.VERSION.SDK_INT >= 26) nm.createNotificationChannel(
            NotificationChannel(channel, text("restFinished", "Rest finished!"), NotificationManager.IMPORTANCE_HIGH))
        val b = if (Build.VERSION.SDK_INT >= 26) Notification.Builder(c, channel) else Notification.Builder(c)
        val index = s.getInt("index")
        val exercises = s.getJSONArray("exercises")
        val e = exercises.getJSONObject(index)
        val phase = s.getString("phase")
        val running = s.getBoolean("running") && phase == "rest"
        val done = s.getJSONArray("completed").getInt(index)
        val series = min(if (phase == "rest" || s.optBoolean("pendingRestCounted")) max(1, done) else done + 1, e.getInt("sets"))
        val deadline = s.getLong("anchor") + s.getInt("seconds") * 1000L
        val remaining = if (running) max(0, ((deadline - System.currentTimeMillis() + 999) / 1000).toInt()) else s.getInt("seconds")
        val clock = "%02d:%02d".format(remaining / 60, remaining % 60)
        val label = when (phase) {
            "rest" -> if (!running) text("paused", "Rest paused") else text("rest", "Rest")
            "done" -> if (hasWeight(s)) text("done", "Exercise completed!") else text("weightRequired", "Enter weight to finish")
            else -> if (done > 0) text("nextSet", "Next set") else text("betweenSets", "Rest between sets")
        }
        b.setSmallIcon(R.drawable.ic_workout_notification).setContentTitle(e.getString("name"))
            .setContentText("$label \u00b7 ${text("sets", "Sets")} $series/${e.getInt("sets")} \u00b7 ${e.getString("reps")} ${text("reps", "Reps")}")
            .setContentIntent(openApp(c)).setOngoing(true).setOnlyAlertOnce(!alert)
            .setVisibility(Notification.VISIBILITY_PUBLIC).setCategory(Notification.CATEGORY_PROGRESS)
            .setShowWhen(false)
        if (Build.VERSION.SDK_INT >= 26) b.setTimeoutAfter(12 * 60 * 60 * 1000L)
        fun pendingAction(action: String): PendingIntent {
            val intent = Intent(c, WorkoutLiveReceiver::class.java).setAction(action)
                .putExtra("id", s.getString("id")).putExtra("revision", s.getLong("revision"))
            return PendingIntent.getBroadcast(c, action.hashCode(), intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        }
        fun button(action: String, title: String) {
            b.addAction(Notification.Action.Builder(null, title, pendingAction(action)).build())
        }
        when (phase) {
            "ready" -> button("rest", text("startRest", "Start rest"))
            "rest" -> { button("toggle", if (running) text("pause", "Pause") else text("resume", "Resume")); button("add", "+30 s"); button("skip", text("endRest", "End rest")) }
            "done" -> if (hasWeight(s) && index + 1 < exercises.length()) button("next", text("nextExercise", "Next exercise"))
        }
        val primary = when (phase) {
            "ready" -> "rest" to text("startRest", "Start rest")
            "rest" -> "toggle" to clock
            "done" -> if (hasWeight(s) && index + 1 < exercises.length()) "next" to text("nextExercise", "Next exercise") else null
            else -> null
        }
        val compact = RemoteViews(c.packageName, R.layout.workout_notification_compact)
        compact.setTextViewText(R.id.workout_name, e.getString("name"))
        compact.setTextViewText(R.id.workout_status, "$label \u00b7 ${text("sets", "Sets")} $series/${e.getInt("sets")} \u00b7 ${e.getString("reps")} ${text("reps", "Reps")}")
        if (primary != null) {
            compact.setTextViewText(R.id.workout_action_label, primary.second)
            compact.setTextViewTextSize(R.id.workout_action_label,
                android.util.TypedValue.COMPLEX_UNIT_SP, if (phase == "rest") 18f else 12f)
            compact.setOnClickPendingIntent(R.id.workout_action, pendingAction(primary.first))
        } else compact.setViewVisibility(R.id.workout_action, android.view.View.GONE)
        b.setCustomContentView(compact).setStyle(Notification.DecoratedCustomViewStyle())
        return b.build()
    }
}

class WorkoutLiveReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == "restEnded") WorkoutLive.restEnded(context)
        else WorkoutLive.action(context, intent.action ?: return,
            intent.getStringExtra("id") ?: return, intent.getLongExtra("revision", -1))
    }
}
