package com.example.vgspu_app

import android.app.job.JobInfo
import android.app.job.JobParameters
import android.app.job.JobScheduler
import android.app.job.JobService
import android.content.ComponentName
import android.content.Context
import org.json.JSONArray
import org.json.JSONObject
import java.net.URL
import java.net.URLEncoder
import java.time.LocalDate
import java.util.concurrent.atomic.AtomicBoolean
import javax.net.ssl.HttpsURLConnection

/** Android-managed background work; independent of push and portal authentication. */
class ScheduleWidgetJob : JobService() {
    private var worker: Thread? = null
    @Volatile private var stopped = false

    override fun onStartJob(params: JobParameters): Boolean {
        val snapshot = ScheduleWidgetStore.read(this) ?: return false
        if (ScheduleWidgetProvider.ids(this).isEmpty() || !running.compareAndSet(false, true)) return false
        stopped = false
        worker = Thread {
            try {
                val today = LocalDate.now(ScheduleWidgetProvider.universityZone)
                val combined = JSONArray()
                val current = fetch(snapshot, today)
                // A failure on an unpublished future week must not hide today's lessons.
                val following = try { fetch(snapshot, today.plusWeeks(1)) } catch (error: Exception) {
                    val now = java.time.LocalDateTime.now(ScheduleWidgetProvider.universityZone)
                    if (ScheduleWidgetProvider.parse(current.toString(), snapshot.kind).none { it.finishes > now }) throw error
                    null
                }
                for (data in listOfNotNull(current, following)) {
                    for (i in 0 until minOf(data.length(), 500)) combined.put(data.getJSONObject(i))
                }
                if (!stopped) ScheduleWidgetStore.save(this, snapshot, combined, false)
            } catch (_: Exception) {
                if (!stopped) runCatching { ScheduleWidgetStore.save(this, snapshot, null, true) }
            } finally {
                running.set(false)
                mainExecutorCompat {
                    ScheduleWidgetProvider.renderAll(this)
                    if (!stopped) jobFinished(params, false)
                    val current = ScheduleWidgetStore.read(this)
                    if (current != null && current.generation != snapshot.generation) {
                        ScheduleWidgetStore.releaseRefresh(this)
                        request(this, force = true)
                    }
                }
            }
        }.apply { name = "unio-widget"; start() }
        return true
    }

    override fun onStopJob(params: JobParameters): Boolean {
        stopped = true
        worker?.interrupt()
        return false
    }

    private fun mainExecutorCompat(action: () -> Unit) {
        android.os.Handler(mainLooper).post(action)
    }

    private fun fetch(snapshot: WidgetSnapshot, day: LocalDate): JSONArray {
        val path = if (snapshot.kind == "teacher") "/api/v1/teachers/schedule" else "/api/v1/schedule"
        val key = if (snapshot.kind == "teacher") "fio" else "group"
        val value = URLEncoder.encode(snapshot.value, "UTF-8")
        val connection = URL("https://${snapshot.host}$path?$key=$value&date=$day&week=true").openConnection() as HttpsURLConnection
        try {
            connection.connectTimeout = 10_000
            connection.readTimeout = 12_000
            connection.instanceFollowRedirects = false
            connection.setRequestProperty("Accept", "application/json")
            if (connection.responseCode != 200) error("widget_request_failed")
            val bytes = connection.inputStream.use { input ->
                val out = java.io.ByteArrayOutputStream()
                val buffer = ByteArray(8192)
                while (true) {
                    val count = input.read(buffer)
                    if (count < 0) break
                    if (out.size() + count > 1_048_576) error("widget_payload_too_large")
                    out.write(buffer, 0, count)
                }
                out.toByteArray()
            }
            val result = JSONObject(String(bytes, Charsets.UTF_8)).getJSONArray("lessons")
            // Reject unreadable nonempty payloads rather than showing a false empty state.
            if (result.length() > 0 && ScheduleWidgetProvider.parse(result.toString(), snapshot.kind).isEmpty()) {
                error("widget_schedule_invalid")
            }
            return result
        } finally { connection.disconnect() }
    }

    companion object {
        private const val PERIODIC_ID = 8120
        private const val REFRESH_ID = 8121
        private val running = AtomicBoolean(false)
        private fun scheduler(context: Context) = context.getSystemService(Context.JOB_SCHEDULER_SERVICE) as JobScheduler
        private fun builder(context: Context, id: Int) = JobInfo.Builder(id, ComponentName(context, ScheduleWidgetJob::class.java))
            .setRequiredNetworkType(JobInfo.NETWORK_TYPE_ANY)

        fun ensureScheduled(context: Context) {
            if (ScheduleWidgetStore.read(context) == null || ScheduleWidgetProvider.ids(context).isEmpty()) return
            val scheduler = scheduler(context)
            if (scheduler.allPendingJobs.none { it.id == PERIODIC_ID }) {
                scheduler.schedule(builder(context, PERIODIC_ID).setPeriodic(30 * 60 * 1000L).build())
            }
        }

        fun request(context: Context, force: Boolean = false) {
            if (ScheduleWidgetStore.read(context) == null || ScheduleWidgetProvider.ids(context).isEmpty()) return
            ensureScheduled(context)
            val snapshot = ScheduleWidgetStore.read(context) ?: return
            val elapsed = System.currentTimeMillis() - snapshot.fetchedAt
            if (!force && !snapshot.failed && elapsed in 0 until 15 * 60 * 1000L) return
            if (ScheduleWidgetStore.reserveRefresh(context)) {
                scheduler(context).schedule(builder(context, REFRESH_ID).setMinimumLatency(0).build())
            }
        }

        fun cancel(context: Context) {
            scheduler(context).cancel(PERIODIC_ID)
            scheduler(context).cancel(REFRESH_ID)
        }
    }
}
