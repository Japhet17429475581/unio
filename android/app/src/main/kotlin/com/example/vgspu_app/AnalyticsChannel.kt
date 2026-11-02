package com.example.vgspu_app

import android.content.pm.ApplicationInfo
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/** Only product events with bounded categorical values cross this bridge. */
object AnalyticsChannel {
    private val events = setOf(
        "screen_view", "onboarding_started", "onboarding_finished", "role_selected",
        "login_attempt", "login_result", "logout", "week_changed", "note_saved",
        "request_create", "request_submit", "template_saved", "guide_opened",
        "guide_completed", "news_story_opened", "news_full_opened", "teacher_selected",
        "rooms_search", "setting_changed", "notification_opened"
    )
    private val values = mapOf(
        "screen" to setOf("schedule", "gradebook", "university", "settings", "news", "news_article", "requests", "request_form", "lesson_notes", "teacher_search", "teacher_schedule", "free_rooms"),
        "role" to setOf("student", "teacher"),
        "method" to setOf("guest", "portal"),
        "outcome" to setOf("attempt", "success", "failed", "unconfirmed", "rejected"),
        "action" to setOf("completed", "skipped", "next", "previous", "enabled", "disabled"),
        "setting" to setOf("dark_theme", "push"),
        "has_photos" to setOf("true", "false")
    )

    fun valid(name: String, params: Map<String, String>) =
        name in events && params.all { (key, value) -> value in values[key].orEmpty() }

    fun register(messenger: BinaryMessenger, app: UnioApplication) {
        MethodChannel(messenger, "unio/analytics").setMethodCallHandler { call, result ->
            val debuggable = app.applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE != 0
            val enabled = BuildConfig.MYTRACKER_ENABLED && (!debuggable || BuildConfig.MYTRACKER_DEBUG)
            when (call.method) {
                "initialize" -> result.success(enabled && AnalyticsRuntime.grant(app) != null)
                "setConsent" -> {
                    if (call.argument<Boolean>("accepted") != true) {
                        AnalyticsRuntime.revoke(app) { ok ->
                            if (ok) result.success(false)
                            else result.error("cleanup_pending", "Analytics cleanup must be retried", null)
                        }
                    } else {
                        try {
                            val version = call.argument<String>("version").orEmpty()
                            if (enabled) {
                                AnalyticsRuntime.allow(app, version)
                                AnalyticsRuntime.send(app)
                            }
                            result.success(enabled)
                        } catch (_: Exception) {
                            AnalyticsRuntime.revoke(app) { result.error("unavailable", "Analytics unavailable", null) }
                        }
                    }
                }
                "trackEvent" -> {
                    val name = call.argument<String>("name").orEmpty()
                    val params = call.argument<Map<String, String>>("params") ?: emptyMap()
                    if (!valid(name, params)) {
                        result.error("invalid_event", "Unknown analytics category", null)
                    } else {
                        try { if (enabled) AnalyticsRuntime.send(app, name, params) } catch (_: Exception) { }
                        result.success(null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
