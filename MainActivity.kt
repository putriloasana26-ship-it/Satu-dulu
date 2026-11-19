// Salin ke android/app/src/main/kotlin/<package_anda>/MainActivity.kt (sesuaikan baris package)
package com.example.satu_dulu

import android.app.AppOpsManager
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Intent
import android.os.Process
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var lastPkg = ""

    override fun configureFlutterEngine(engine: FlutterEngine) {
        super.configureFlutterEngine(engine)
        MethodChannel(engine.dartExecutor.binaryMessenger, "satudulu/focus").setMethodCallHandler { call, res ->
            when (call.method) {
                "hasUsagePermission" -> {
                    val ops = getSystemService(APP_OPS_SERVICE) as AppOpsManager
                    res.success(ops.checkOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, Process.myUid(), packageName) == AppOpsManager.MODE_ALLOWED)
                }
                "openUsageSettings" -> { startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)); res.success(null) }
                "foregroundPackage" -> {
                    val usm = getSystemService(USAGE_STATS_SERVICE) as UsageStatsManager
                    val now = System.currentTimeMillis()
                    val ev = usm.queryEvents(now - 10_000, now)
                    val e = UsageEvents.Event()
                    while (ev.hasNextEvent()) {
                        ev.getNextEvent(e)
                        if (e.eventType == UsageEvents.Event.ACTIVITY_RESUMED) lastPkg = e.packageName
                    }
                    res.success(lastPkg)
                }
                "bringToFront" -> {
                    startActivity(Intent(this, MainActivity::class.java)
                        .addFlags(Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or Intent.FLAG_ACTIVITY_NEW_TASK))
                    res.success(null)
                }
                else -> res.notImplemented()
            }
        }
    }
}
