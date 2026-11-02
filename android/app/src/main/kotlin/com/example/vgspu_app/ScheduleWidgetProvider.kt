package com.example.vgspu_app

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.os.Build
import android.util.TypedValue
import android.view.View
import android.widget.RemoteViews
import org.json.JSONArray
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.LocalTime
import java.time.ZoneOffset
import java.time.format.DateTimeFormatter
import java.util.Locale

internal data class WidgetLesson(val date: LocalDate, val start: LocalTime,
    val end: LocalTime, val subject: String, val room: String, val detail: String) {
    val begins: LocalDateTime get() = date.atTime(start)
    val finishes: LocalDateTime get() = date.atTime(end).let { if (end < start) it.plusDays(1) else it }
}

class ScheduleWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        renderAll(context)
        ScheduleWidgetJob.ensureScheduled(context)
        ScheduleWidgetJob.request(context)
    }

    override fun onAppWidgetOptionsChanged(context: Context, manager: AppWidgetManager, id: Int, options: Bundle) {
        renderAll(context)
    }

    override fun onDisabled(context: Context) { ScheduleWidgetJob.cancel(context); cancelBoundary(context) }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        when (intent.action) {
            REFRESH -> { renderAll(context); ScheduleWidgetJob.request(context, force = true) }
            BOUNDARY, Intent.ACTION_TIME_CHANGED, Intent.ACTION_TIMEZONE_CHANGED, Intent.ACTION_DATE_CHANGED -> renderAll(context)
            Intent.ACTION_BOOT_COMPLETED, Intent.ACTION_MY_PACKAGE_REPLACED -> {
                renderAll(context); ScheduleWidgetJob.ensureScheduled(context); ScheduleWidgetJob.request(context)
            }
        }
    }

    companion object {
        const val REFRESH = "com.example.vgspu_app.WIDGET_REFRESH"
        const val BOUNDARY = "com.example.vgspu_app.WIDGET_BOUNDARY"
        const val OPEN_SCHEDULE = "unio_widget_schedule"
        val universityZone: ZoneOffset = ZoneOffset.ofHours(3)
        private val time = DateTimeFormatter.ofPattern("H:mm")
        private val displayTime = DateTimeFormatter.ofPattern("HH:mm")
        private val shortDate = DateTimeFormatter.ofPattern("d MMM", Locale.forLanguageTag("ru"))

        fun ids(context: Context): IntArray = AppWidgetManager.getInstance(context)
            .getAppWidgetIds(ComponentName(context, ScheduleWidgetProvider::class.java))

        internal fun parse(source: String, kind: String): List<WidgetLesson> {
            val array = JSONArray(source)
            return (0 until minOf(array.length(), 500)).mapNotNull { index ->
                runCatching {
                    val item = array.getJSONObject(index)
                    val subject = item.getString("subject").take(300)
                    if (subject.isBlank()) return@runCatching null
                    WidgetLesson(LocalDate.parse(item.getString("date")),
                        LocalTime.parse(item.getString("start").trim(), time),
                        LocalTime.parse(item.getString("end").trim(), time), subject,
                        item.optString("room", "").take(100),
                        item.optString(if (kind == "teacher") "group" else "teacher", "").take(150))
                }.getOrNull()
            }.sortedBy { it.begins }
        }

        fun renderAll(context: Context) {
            // Serialize rendering with channel-driven clear/select on the main thread.
            if (android.os.Looper.myLooper() != android.os.Looper.getMainLooper()) {
                android.os.Handler(android.os.Looper.getMainLooper()).post { renderAll(context) }
                return
            }
            val manager = AppWidgetManager.getInstance(context)
            val snapshot = ScheduleWidgetStore.read(context)
            val now = LocalDateTime.now(universityZone)
            val lessons = runCatching { parse(snapshot?.lessons ?: "[]", snapshot?.kind ?: "group") }.getOrDefault(emptyList())
                .filter { it.finishes > now && it.date <= now.toLocalDate().plusDays(7) }
            val next = lessons.firstOrNull()
            val freshEnough = snapshot != null && System.currentTimeMillis() - snapshot.fetchedAt < 14L * 24 * 60 * 60 * 1000
            val visible = if (freshEnough) next else null
            for (id in ids(context)) {
                val compact = manager.getAppWidgetOptions(id).getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 180) < 220
                val views = RemoteViews(context.packageName, R.layout.schedule_widget)
                val open = Intent(context, MainActivity::class.java).apply {
                    putExtra(OPEN_SCHEDULE, true)
                    flags = Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
                }
                views.setOnClickPendingIntent(R.id.widget_root, PendingIntent.getActivity(context, 8100, open,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE))
                val refresh = Intent(context, ScheduleWidgetProvider::class.java).setAction(REFRESH)
                views.setOnClickPendingIntent(R.id.widget_refresh, PendingIntent.getBroadcast(context, 8101, refresh,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE))
                views.setTextViewText(R.id.widget_group, snapshot?.value ?: "РАСПИСАНИЕ")
                views.setTextViewText(R.id.widget_eyebrow, when {
                    snapshot == null -> "ТВОЙ УЧЕБНЫЙ ДЕНЬ"
                    visible == null -> "${now.toLocalDate().format(shortDate)} · РАСПИСАНИЕ"
                    visible.begins <= now -> "СЕЙЧАС НА ПАРЕ"
                    visible.date == now.toLocalDate() -> "СЛЕДУЮЩАЯ ПАРА · СЕГОДНЯ"
                    visible.date == now.toLocalDate().plusDays(1) -> "БЛИЖАЙШАЯ ПАРА · ЗАВТРА"
                    else -> "БЛИЖАЙШАЯ ПАРА · ${visible.date.format(shortDate)}"
                })
                views.setTextViewText(R.id.widget_time, visible?.let { "${it.start.format(displayTime)}–${it.end.format(displayTime)}" } ?: "")
                views.setViewVisibility(R.id.widget_time, if (visible == null) View.GONE else View.VISIBLE)
                views.setTextViewText(R.id.widget_subject, visible?.subject ?: when {
                    snapshot == null -> "Открой UNIO"
                    snapshot.fetchedAt == 0L && snapshot.failed -> "Не удалось загрузить"
                    snapshot.fetchedAt == 0L -> "Загружаем расписание…"
                    snapshot.failed -> "Не удалось обновить"
                    else -> "Расписание не найдено"
                })
                views.setTextViewText(R.id.widget_details, visible?.let {
                    listOfNotNull(it.room.takeIf { room -> room.isNotBlank() }?.let { room -> "Ауд. $room" },
                        it.detail.takeIf { detail -> detail.isNotBlank() }).joinToString(" · ")
                } ?: if (snapshot == null) "Войди и выбери своё расписание" else "Нажми, чтобы открыть расписание")
                val following = lessons.drop(1).firstOrNull()
                views.setTextViewText(R.id.widget_following, following?.let {
                    "Затем ${if (it.date == now.toLocalDate()) "" else it.date.format(shortDate) + " · "}${it.start.format(displayTime)} · ${it.subject}"
                } ?: "Твой день — в твоём ритме")
                views.setViewVisibility(R.id.widget_following, if (compact || visible == null) View.GONE else View.VISIBLE)
                val synced = snapshot?.fetchedAt?.takeIf { it > 0 }?.let {
                    val date = java.time.Instant.ofEpochMilli(it).atOffset(universityZone)
                    "${if (date.toLocalDate() == now.toLocalDate()) "" else date.format(shortDate) + " · "}${date.format(displayTime)}"
                }
                views.setTextViewText(R.id.widget_freshness, when {
                    snapshot == null -> "Расписание под рукой"
                    synced == null -> "Обновление без открытия приложения"
                    snapshot.failed -> "Сохранённая копия · $synced"
                    else -> "Синхр. $synced"
                })
                if (compact) {
                    val density = context.resources.displayMetrics.density
                    views.setViewPadding(R.id.widget_root, (14 * density).toInt(), (10 * density).toInt(), (14 * density).toInt(), (8 * density).toInt())
                    views.setTextViewTextSize(R.id.widget_time, TypedValue.COMPLEX_UNIT_SP, 22f)
                    views.setTextViewTextSize(R.id.widget_subject, TypedValue.COMPLEX_UNIT_SP, 14f)
                    views.setInt(R.id.widget_subject, "setMaxLines", 1)
                }
                manager.updateAppWidget(id, views)
            }
            cancelBoundary(context)
            if (snapshot != null && ids(context).isNotEmpty()) {
                val boundary = lessons.flatMap { listOf(it.begins, it.finishes) }
                    .filter { it > now }.minOrNull() ?: now.toLocalDate().plusDays(1).atStartOfDay()
                val alarm = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
                val at = boundary.toInstant(universityZone).toEpochMilli()
                if (Build.VERSION.SDK_INT >= 23) alarm.setAndAllowWhileIdle(AlarmManager.RTC, at, boundaryIntent(context))
                else alarm.set(AlarmManager.RTC, at, boundaryIntent(context))
            }
        }

        private fun boundaryIntent(context: Context) = PendingIntent.getBroadcast(context, 8102,
            Intent(context, ScheduleWidgetProvider::class.java).setAction(BOUNDARY),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)

        fun cancelBoundary(context: Context) = (context.getSystemService(Context.ALARM_SERVICE) as AlarmManager).cancel(boundaryIntent(context))
    }
}
