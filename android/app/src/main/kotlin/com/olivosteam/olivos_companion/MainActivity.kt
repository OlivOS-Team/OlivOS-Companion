package com.olivosteam.olivos_companion

import android.os.Build
import android.view.Display
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlin.math.roundToInt

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "olivos_companion/window",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getRefreshRate" -> {
                    val display = currentDisplay()
                    if (display == null) {
                        result.error("unavailable", "Could not read display", null)
                        return@setMethodCallHandler
                    }
                    val hz =
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                            display.mode.refreshRate
                        } else {
                            @Suppress("DEPRECATION")
                            display.refreshRate
                        }
                    if (hz.isNaN() || hz <= 1f || hz > 1000f) {
                        result.error(
                            "unavailable",
                            "Display refresh rate is unknown",
                            null,
                        )
                    } else {
                        result.success(hz.roundToInt())
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun currentDisplay(): Display? {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            display
        } else {
            @Suppress("DEPRECATION")
            windowManager.defaultDisplay
        }
    }
}
