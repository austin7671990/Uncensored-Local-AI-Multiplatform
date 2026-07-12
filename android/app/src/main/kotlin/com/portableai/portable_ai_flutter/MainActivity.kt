package com.portableai.portable_ai_flutter

import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        private const val CHANNEL = "com.portableai.portable_ai_flutter/accessibility"
    }

    private var methodChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel!!.setMethodCallHandler { call, result ->
            val service = AgentAccessibilityService.instance

            when (call.method) {
                "isReady" -> {
                    result.success(service?.isReady() ?: false)
                }

                "readScreen" -> {
                    if (service == null) {
                        result.error("NO_SERVICE", "Accessibility service not running. Enable it in Settings > Accessibility > Agentic AI.", null)
                        return@setMethodCallHandler
                    }
                    try {
                        val content = service.readScreenContent()
                        result.success(content)
                    } catch (e: Exception) {
                        result.error("READ_ERROR", e.message, null)
                    }
                }

                "tap" -> {
                    if (service == null) {
                        result.error("NO_SERVICE", "Accessibility service not running.", null)
                        return@setMethodCallHandler
                    }
                    val x = call.argument<Int>("x") ?: 0
                    val y = call.argument<Int>("y") ?: 0
                    try {
                        val response = service.tap(x, y)
                        result.success(response)
                    } catch (e: Exception) {
                        result.error("TAP_ERROR", e.message, null)
                    }
                }

                "swipe" -> {
                    if (service == null) {
                        result.error("NO_SERVICE", "Accessibility service not running.", null)
                        return@setMethodCallHandler
                    }
                    val x1 = call.argument<Int>("x1") ?: 0
                    val y1 = call.argument<Int>("y1") ?: 0
                    val x2 = call.argument<Int>("x2") ?: 0
                    val y2 = call.argument<Int>("y2") ?: 0
                    try {
                        val response = service.swipe(x1, y1, x2, y2)
                        result.success(response)
                    } catch (e: Exception) {
                        result.error("SWIPE_ERROR", e.message, null)
                    }
                }

                "typeText" -> {
                    if (service == null) {
                        result.error("NO_SERVICE", "Accessibility service not running.", null)
                        return@setMethodCallHandler
                    }
                    val text = call.argument<String>("text") ?: ""
                    try {
                        val response = service.typeText(text)
                        result.success(response)
                    } catch (e: Exception) {
                        result.error("TYPE_ERROR", e.message, null)
                    }
                }

                "pressKey" -> {
                    if (service == null) {
                        result.error("NO_SERVICE", "Accessibility service not running.", null)
                        return@setMethodCallHandler
                    }
                    val key = call.argument<String>("key") ?: ""
                    try {
                        val response = service.pressKey(key)
                        result.success(response)
                    } catch (e: Exception) {
                        result.error("KEY_ERROR", e.message, null)
                    }
                }

                "takeScreenshot" -> {
                    if (service == null) {
                        result.error("NO_SERVICE", "Accessibility service not running.", null)
                        return@setMethodCallHandler
                    }
                    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) {
                        result.error("UNSUPPORTED", "Screenshots require Android 12+.", null)
                        return@setMethodCallHandler
                    }
                    try {
                        val response = service.takeScreenshot()
                        result.success(response)
                    } catch (e: Exception) {
                        result.error("SCREENSHOT_ERROR", e.message, null)
                    }
                }

                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onDestroy() {
        methodChannel?.setMethodCallHandler(null)
        methodChannel = null
        super.onDestroy()
    }
}
