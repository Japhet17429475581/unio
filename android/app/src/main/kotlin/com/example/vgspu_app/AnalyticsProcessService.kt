package com.example.vgspu_app

import android.app.Service
import android.content.Intent
import android.os.IBinder
import android.os.Process
import com.my.tracker.MyTracker
import com.my.tracker.MyTrackerConfig
import com.my.tracker.config.AntiFraudConfig

class AnalyticsProcessService : Service() {
    private var ready = false
    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val activeGrant = AnalyticsRuntime.grant(this)
        if (activeGrant == null || intent?.getStringExtra("grant") != activeGrant) {
            stopSelf()
            return START_NOT_STICKY
        }
        try {
            if (!ready) {
                // Even a debug build never prints SDK identifiers or payloads.
                MyTracker.setDebugMode(false)
                MyTracker.getTrackerConfig().apply {
                    setTrackingLaunchEnabled(true)
                    setTrackingEnvironmentEnabled(false)
                    setLocationTrackingMode(MyTrackerConfig.LocationTrackingMode.NONE)
                    setAntiFraudConfig(AntiFraudConfig.newBuilder()
                        .useLightSensor(false).useMagneticFieldSensor(false)
                        .useGyroscopeSensor(false).usePressureSensor(false)
                        .useProximitySensor(false).build())
                    setAutotrackingPurchaseEnabled(false)
                    setTrackingPreinstallEnabled(false)
                    setTrackingPreinstallThirdPartyEnabled(false)
                    setBufferingPeriod(300)
                }
                initializeTracker()
                ready = true
            }
            val event = intent?.getStringExtra("event")
            val bundle = intent?.getBundleExtra("params")
            val params = bundle?.keySet()?.associateWith { bundle.getString(it).orEmpty() } ?: emptyMap()
            if (event != null && AnalyticsChannel.valid(event, params) && AnalyticsRuntime.grant(this) == activeGrant) {
                MyTracker.trackEvent(event, params)
            }
        } catch (_: Exception) {
            stopSelf()
        } catch (_: LinkageError) {
            stopSelf()
        }
        return START_NOT_STICKY
    }

    private fun initializeTracker() = MyTracker.initTracker(AnalyticsSdkKey.value, application)

    override fun onDestroy() {
        // Do not flush: revocation must discard buffered events.
        super.onDestroy()
        Process.killProcess(Process.myPid())
    }
}
