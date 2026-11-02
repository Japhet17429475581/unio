package com.example.vgspu_app

import android.content.Context
import org.json.JSONArray
import java.util.UUID

internal data class WidgetSnapshot(
    val generation: String, val kind: String, val value: String, val host: String,
    val lessons: String, val fetchedAt: Long, val failed: Boolean,
)

/** Public timetable only. Never receives a UNIO token or portal credentials. */
internal object ScheduleWidgetStore {
    private fun prefs(context: Context) = context.getSharedPreferences("unio_schedule_widget", Context.MODE_PRIVATE)

    @Synchronized fun read(context: Context): WidgetSnapshot? {
        val p = prefs(context)
        val generation = p.getString("generation", null) ?: return null
        val fetchedAt = p.getLong("fetched_at", 0)
        if (fetchedAt > 0 && System.currentTimeMillis() - fetchedAt > 14L * 24 * 60 * 60 * 1000) {
            p.edit().remove("lessons").remove("fetched_at").apply()
        }
        return WidgetSnapshot(generation, p.getString("kind", "group")!!,
            p.getString("value", "")!!, p.getString("host", "")!!,
            p.getString("lessons", "[]")!!, p.getLong("fetched_at", 0), p.getBoolean("failed", false))
    }

    @Synchronized fun select(context: Context, kind: String, value: String, host: String) {
        val previous = read(context)
        if (previous?.kind == kind && previous.value == value && previous.host == host) return
        check(prefs(context).edit().clear().putString("generation", UUID.randomUUID().toString())
            .putString("kind", kind).putString("value", value).putString("host", host).commit())
    }

    @Synchronized fun save(context: Context, snapshot: WidgetSnapshot, lessons: JSONArray?, failed: Boolean) {
        // A late response from another group or signed-out account must not reappear.
        if (read(context)?.generation != snapshot.generation) return
        val edit = prefs(context).edit().putBoolean("failed", failed)
        if (lessons != null) edit.putString("lessons", lessons.toString()).putLong("fetched_at", System.currentTimeMillis())
        check(edit.commit())
    }

    @Synchronized fun reserveRefresh(context: Context): Boolean {
        val p = prefs(context)
        val now = System.currentTimeMillis()
        val elapsed = now - p.getLong("last_request", 0)
        if (elapsed in 0..29_999) return false
        return p.edit().putLong("last_request", now).commit()
    }

    @Synchronized fun clear(context: Context) { check(prefs(context).edit().clear().commit()) }

    @Synchronized fun releaseRefresh(context: Context) { prefs(context).edit().remove("last_request").apply() }
}
