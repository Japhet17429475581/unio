package com.example.vgspu_app

import android.app.ActivityManager
import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.os.Process
import android.util.AtomicFile
import java.io.File
import java.util.UUID

/** The SDK has no stop API. It runs only in a disposable, non-exported process. */
object AnalyticsRuntime {
    private fun grantFile(context: Context) = AtomicFile(File(context.noBackupFilesDir, "analytics-grant"))
    fun grant(context: Context): String? = try {
        String(grantFile(context).readFully(), Charsets.UTF_8)
            .takeIf { it.startsWith(AnalyticsLegalVersion.current + "|") }
    } catch (_: Exception) { null }

    fun allow(context: Context, version: String) {
        require(version == AnalyticsLegalVersion.current)
        if (grant(context) != null) return
        val file = grantFile(context)
        val stream = file.startWrite()
        try {
            stream.write((version + "|" + UUID.randomUUID()).toByteArray(Charsets.UTF_8))
            file.finishWrite(stream)
        } catch (error: Exception) {
            file.failWrite(stream)
            throw error
        }
    }

    fun send(context: Context, name: String? = null, params: Map<String, String> = emptyMap()) {
        val grant = grant(context) ?: return
        val intent = Intent(context, AnalyticsProcessService::class.java)
            .putExtra("grant", grant)
        if (name != null) {
            intent.putExtra("event", name)
            intent.putExtra("params", android.os.Bundle().apply {
                params.forEach { (key, value) -> putString(key, value) }
            })
        }
        context.startService(intent)
    }

    private fun processes(context: Context) =
        (context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager)
            .runningAppProcesses.orEmpty().filter {
                it.uid == Process.myUid() && it.processName == context.packageName + ":analytics"
            }

    fun revoke(context: Context, complete: (Boolean) -> Unit) {
        grantFile(context).delete() // Deny before stopping, including queued service starts.
        val denied = grant(context) == null
        context.stopService(Intent(context, AnalyticsProcessService::class.java))
        val handler = Handler(Looper.getMainLooper())
        var attempts = 0
        fun stop() {
            val running = processes(context)
            running.forEach { Process.killProcess(it.pid) }
            if (running.isEmpty()) {
                complete(clearBuffer(context) && denied)
            } else if (++attempts < 80) {
                handler.postDelayed({ stop() }, 25)
            } else complete(false)
        }
        stop()
    }

    /** Names verified against pinned SDK 3.5.0, including pre-consent old builds. */
    fun clearBuffer(context: Context): Boolean = try {
        var cleared = true
        for (name in context.databaseList().filter { it.startsWith("mytracker_") }) {
            // deleteDatabase also removes WAL/journal files listed by databaseList.
            // An already removed companion is success, not a failed revocation.
            if (context.getDatabasePath(name).exists() &&
                !context.deleteDatabase(name) && context.getDatabasePath(name).exists()) cleared = false
        }
        for (file in File(context.applicationInfo.dataDir, "shared_prefs").listFiles().orEmpty()) {
            if (file.name.startsWith("mytracker_")) {
                if (!context.deleteSharedPreferences(file.name.removeSuffix(".bak").removeSuffix(".xml"))) {
                    if (file.exists() && !file.delete()) cleared = false
                }
            }
        }
        for (dir in listOf(context.filesDir, context.cacheDir)) {
            for (file in dir.listFiles().orEmpty().filter { it.name.startsWith("mytracker_") }) {
                if (!file.deleteRecursively()) cleared = false
            }
        }
        cleared
    } catch (_: Exception) { false }
}
