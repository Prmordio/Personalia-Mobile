package com.personalia.personalia_app

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.Manifest
import android.os.Build
import android.app.AlarmManager
import android.content.Intent
import android.net.Uri
import android.provider.Settings

// FragmentActivity: exigido pelo local_auth (login por biometria).
class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "personalia/workout_live")
            .setMethodCallHandler { call, result ->
                try {
                    val state = when (call.method) {
                        "requestExactAlarm" -> {
                            if (Build.VERSION.SDK_INT >= 31 && !getSystemService(AlarmManager::class.java).canScheduleExactAlarms()) {
                                startActivity(Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM,
                                    Uri.parse("package:$packageName")))
                            }
                            result.success(null)
                            return@setMethodCallHandler
                        }
                        "read" -> WorkoutLive.read(this)
                        "weight" -> WorkoutLive.weight(this, call.argument<String>("id")!!,
                            call.argument<String>("name")!!, call.argument<String>("value")!!)
                        "localize" -> WorkoutLive.localize(this, call.argument<String>("json")!!)
                        "prepare" -> WorkoutLive.prepare(this, call.argument<String>("json")!!)
                        "action" -> {
                            val preferences = getSharedPreferences("workout_live", MODE_PRIVATE)
                            if (call.argument<String>("action") == "rest" && Build.VERSION.SDK_INT >= 33 &&
                                !preferences.getBoolean("permissionAsked", false) &&
                                checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != android.content.pm.PackageManager.PERMISSION_GRANTED) {
                                preferences.edit().putBoolean("permissionAsked", true).apply()
                                requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 73140)
                            }
                            WorkoutLive.action(this, call.argument<String>("action")!!,
                                call.argument<String>("id")!!, call.argument<Number>("revision")!!.toLong())
                        }
                        "end" -> { WorkoutLive.end(this); null }
                        else -> { result.notImplemented(); return@setMethodCallHandler }
                    }
                    result.success(state?.toString())
                } catch (e: Exception) { result.error("workout_live", e.message, null) }
            }
    }

    override fun onResume() {
        super.onResume()
        WorkoutLive.restore(this)
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == 73140 && grantResults.firstOrNull() == android.content.pm.PackageManager.PERMISSION_GRANTED) {
            WorkoutLive.read(this)?.let { WorkoutLive.show(this, it) }
        }
    }
}
