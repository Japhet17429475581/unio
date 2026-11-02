package com.example.vgspu_app

import io.flutter.embedding.android.FlutterActivity
import android.app.Activity
import android.content.Intent
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var widgetChannel: ScheduleWidgetChannel? = null
    private var exportResult: MethodChannel.Result? = null
    private var exportBytes: ByteArray? = null
    private val exportRequestCode = 7431

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        widgetChannel = ScheduleWidgetChannel(this, flutterEngine.dartExecutor.binaryMessenger)
        AnalyticsChannel.register(flutterEngine.dartExecutor.binaryMessenger, application as UnioApplication)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "unio/document_export")
            .setMethodCallHandler { call, result ->
                if (call.method != "saveDocument") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                if (exportResult != null) {
                    result.error("busy", "A save dialog is already open", null)
                    return@setMethodCallHandler
                }
                val name = call.argument<String>("name")
                val bytes = call.argument<ByteArray>("bytes")
                if (name.isNullOrBlank() || name.contains('/') || name.contains('\\') || bytes == null) {
                    result.error("invalid", "Invalid document", null)
                    return@setMethodCallHandler
                }
                exportResult = result
                exportBytes = bytes
                try {
                    val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                        addCategory(Intent.CATEGORY_OPENABLE)
                        type = "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
                        putExtra(Intent.EXTRA_TITLE, name)
                    }
                    startActivityForResult(intent, exportRequestCode)
                } catch (_: Exception) {
                    exportResult = null
                    exportBytes = null
                    result.error("unavailable", "Could not open save dialog", null)
                }
            }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != exportRequestCode) return
        val result = exportResult ?: return
        val bytes = exportBytes
        exportResult = null
        exportBytes = null
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null || bytes == null) {
            result.success(false)
            return
        }
        Thread {
            try {
                val stream = contentResolver.openOutputStream(uri, "w")
                    ?: throw java.io.IOException("No output stream")
                stream.use { it.write(bytes) }
                runOnUiThread { result.success(true) }
            } catch (_: Exception) {
                runOnUiThread { result.error("write_failed", "Could not save document", null) }
            }
        }.start()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        if (intent.getBooleanExtra(ScheduleWidgetProvider.OPEN_SCHEDULE, false)) {
            widgetChannel?.openSchedule()
        }
    }

    override fun onDestroy() {
        exportResult?.success(false)
        exportResult = null
        exportBytes = null
        super.onDestroy()
    }
}
