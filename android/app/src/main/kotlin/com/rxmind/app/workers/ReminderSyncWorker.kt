package com.rxmind.app.workers

import android.content.Context
import android.app.KeyguardManager
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel

/**
 * Reschedules neutral wellness reminders when device is unlocked.
 * No network access; duration target under 30 seconds.
 */
class ReminderSyncWorker(
    appContext: Context,
    params: WorkerParameters,
) : CoroutineWorker(appContext, params) {

    override suspend fun doWork(): Result {
        val keyguard = applicationContext.getSystemService(Context.KEYGUARD_SERVICE)
            as KeyguardManager
        if (keyguard.isKeyguardLocked) {
            return Result.success()
        }

        // Worker signals Dart layer via shared preferences flag;
        // full reschedule runs on next foreground resume.
        val prefs = applicationContext.getSharedPreferences(
            PREFS_NAME,
            Context.MODE_PRIVATE,
        )
        prefs.edit().putBoolean(KEY_PENDING_SYNC, true).apply()
        return Result.success()
    }

    companion object {
        const val WORK_NAME = "rxmind_reminder_sync"
        const val PREFS_NAME = "rxmind_worker"
        const val KEY_PENDING_SYNC = "pending_reminder_sync"
    }
}
