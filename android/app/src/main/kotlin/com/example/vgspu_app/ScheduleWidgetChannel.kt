package com.example.vgspu_app

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.os.Build
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.net.URI

internal class ScheduleWidgetChannel(private val activity: MainActivity, messenger: BinaryMessenger) {
    private val channel = MethodChannel(messenger, "unio/home_widget")

    init {
        channel.setMethodCallHandler { call, result ->
            try {
                val manager = AppWidgetManager.getInstance(activity)
                when (call.method) {
                    "select" -> {
                        val kind = call.argument<String>("kind") ?: ""
                        val value = call.argument<String>("value")?.trim() ?: ""
                        val host = call.argument<String>("host") ?: ""
                        val uri = URI("https://$host")
                        require(kind in listOf("group", "teacher") && value.isNotEmpty() && value.length <= 255)
                        require(uri.host != null && uri.rawAuthority == host && uri.rawUserInfo == null && uri.rawPath.isNullOrEmpty() && uri.rawQuery == null && uri.rawFragment == null)
                        ScheduleWidgetStore.select(activity, kind, value, host)
                        ScheduleWidgetProvider.renderAll(activity)
                        ScheduleWidgetJob.ensureScheduled(activity)
                        ScheduleWidgetJob.request(activity)
                        result.success(null)
                    }
                    "clear" -> {
                        ScheduleWidgetStore.clear(activity)
                        ScheduleWidgetJob.cancel(activity)
                        ScheduleWidgetProvider.cancelBoundary(activity)
                        ScheduleWidgetProvider.renderAll(activity)
                        result.success(null)
                    }
                    "capabilities" -> result.success(mapOf("pinSupported" to
                        (Build.VERSION.SDK_INT >= 26 && manager.isRequestPinAppWidgetSupported)))
                    "pin" -> result.success(if (Build.VERSION.SDK_INT >= 26 && manager.isRequestPinAppWidgetSupported)
                        manager.requestPinAppWidget(ComponentName(activity, ScheduleWidgetProvider::class.java), null, null)
                        else false)
                    else -> result.notImplemented()
                }
            } catch (_: Exception) { result.error("widget_unavailable", "Widget operation unavailable", null) }
        }
    }

    fun openSchedule() { channel.invokeMethod("openSchedule", null) }
}
