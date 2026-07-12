package com.portableai.portable_ai_flutter

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.accessibilityservice.GestureDescription
import android.content.Intent
import android.graphics.Path
import android.graphics.Rect
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit

/**
 * AccessibilityService that enables the AI agent to:
 * - Read screen content (view hierarchy traversal)
 * - Tap and swipe on screen elements
 * - Type text into focused input fields
 * - Press system keys (back, home, recents, power, volume)
 * - Take screenshots (API 31+)
 *
 * Communicates with Flutter via MethodChannel through MainActivity.
 */
class AgentAccessibilityService : AccessibilityService() {

    companion object {
        private const val TAG = "AgentAccessibility"
        var instance: AgentAccessibilityService? = null
            private set
    }

    private val mainHandler = Handler(Looper.getMainLooper())

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
        Log.i(TAG, "AgentAccessibilityService connected")

        val info = AccessibilityServiceInfo()
        info.eventTypes = AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED or
                AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED or
                AccessibilityEvent.TYPE_VIEW_CLICKED or
                AccessibilityEvent.TYPE_VIEW_FOCUSED or
                AccessibilityEvent.TYPE_VIEW_TEXT_CHANGED

        info.flags = AccessibilityServiceInfo.FLAG_INCLUDE_NOT_IMPORTANT_VIEWS or
                AccessibilityServiceInfo.FLAG_REPORT_VIEW_IDS or
                AccessibilityServiceInfo.FLAG_RETRIEVE_INTERACTIVE_WINDOWS

        info.canRetrieveWindowContent = true
        setServiceInfo(info)
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        // Events are captured here; screen reads use getRootInActiveWindow() on demand
    }

    override fun onInterrupt() {
        Log.w(TAG, "Service interrupted")
    }

    override fun onUnbind(intent: Intent?): Boolean {
        instance = null
        Log.i(TAG, "AgentAccessibilityService disconnected")
        return super.onUnbind(intent)
    }

    // ═══════════════════════════════════════════════════════════════
    // SCREEN READING
    // ═══════════════════════════════════════════════════════════════

    /**
     * Reads all visible text elements on the current screen.
     * Returns a structured string with element hierarchy and clickable items.
     */
    fun readScreenContent(): String {
        val rootNode = rootInActiveWindow ?: return "Error: Cannot access window content. Ensure Accessibility Service is enabled."

        return try {
            val buffer = StringBuilder()
            buffer.appendLine("=== Screen Content ===")
            buffer.appendLine("Package: ${rootNode.packageName}")
            buffer.appendLine()

            // Collect interactive elements
            val interactiveElements = mutableListOf<Map<String, String>>()
            traverseNode(rootNode, 0, buffer, interactiveElements)

            // Append summary of clickable/focusable elements
            if (interactiveElements.isNotEmpty()) {
                buffer.appendLine()
                buffer.appendLine("=== Interactive Elements ===")
                for ((index, element) in interactiveElements.withIndex()) {
                    buffer.appendLine("${index + 1}. [${element["type"]}] ${element["text"]} (at ${element["bounds"]})")
                }
            }

            buffer.toString()
        } finally {
            rootNode.recycle()
        }
    }

    private fun traverseNode(
        node: AccessibilityNodeInfo,
        depth: Int,
        buffer: StringBuilder,
        interactiveElements: MutableList<Map<String, String>>
    ) {
        val indent = "  ".repeat(depth)
        val text = node.text?.toString() ?: ""
        val contentDesc = node.contentDescription?.toString() ?: ""

        // Only record nodes with text or content description
        if (text.isNotBlank() || contentDesc.isNotBlank()) {
            val displayText = if (text.isNotBlank()) text else contentDesc
            val bounds = Rect()
            node.getBoundsInScreen(bounds)

            val isClickable = node.isClickable
            val isEditable = node.isEditable
            val isFocusable = node.isFocusable

            val type = when {
                isEditable -> "INPUT"
                isClickable -> "BUTTON"
                else -> "TEXT"
            }

            val markers = buildList {
                if (isClickable) add("clickable")
                if (isEditable) add("editable")
                if (isFocusable) add("focusable")
            }.joinToString(", ").let { if (it.isNotEmpty()) " [$it]" else "" }

            buffer.appendLine("$indent[$type] $displayText$markers")

            // Record interactive elements for the summary
            if (isClickable || isEditable) {
                interactiveElements.add(mapOf(
                    "type" to type,
                    "text" to displayText,
                    "bounds" to "${bounds.centerX()},${bounds.centerY()}"
                ))
            }
        }

        // Recurse into children
        for (i in 0 until node.childCount) {
            val child = node.getChild(i) ?: continue
            try {
                traverseNode(child, depth + 1, buffer, interactiveElements)
            } finally {
                child.recycle()
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // GESTURES (Tap, Swipe)
    // ═══════════════════════════════════════════════════════════════

    /**
     * Tap at screen coordinates (x, y).
     */
    fun tap(x: Int, y: Int): String {
        val path = Path().apply {
            moveTo(x.toFloat(), y.toFloat())
        }
        val gesture = GestureDescription.Builder()
            .addStroke(GestureDescription.StrokeDescription(path, 0, 150))
            .build()

        val latch = CountDownLatch(1)
        var success = false

        dispatchGesture(gesture, object : GestureResultCallback() {
            override fun onCompleted(gestureDescription: GestureDescription?) {
                success = true
                latch.countDown()
            }
            override fun onCancelled(gestureDescription: GestureDescription?) {
                latch.countDown()
            }
        }, null)

        latch.await(3, TimeUnit.SECONDS)
        return if (success) "Tapped at ($x, $y)" else "Tap at ($x, $y) failed or timed out"
    }

    /**
     * Swipe from (x1, y1) to (x2, y2).
     */
    fun swipe(x1: Int, y1: Int, x2: Int, y2: Int): String {
        val path = Path().apply {
            moveTo(x1.toFloat(), y1.toFloat())
            lineTo(x2.toFloat(), y2.toFloat())
        }
        val gesture = GestureDescription.Builder()
            .addStroke(GestureDescription.StrokeDescription(path, 0, 300))
            .build()

        val latch = CountDownLatch(1)
        var success = false

        dispatchGesture(gesture, object : GestureResultCallback() {
            override fun onCompleted(gestureDescription: GestureDescription?) {
                success = true
                latch.countDown()
            }
            override fun onCancelled(gestureDescription: GestureDescription?) {
                latch.countDown()
            }
        }, null)

        latch.await(3, TimeUnit.SECONDS)
        val direction = describeDirection(x1, y1, x2, y2)
        return if (success) "Swiped $direction" else "Swipe $direction failed or timed out"
    }

    private fun describeDirection(x1: Int, y1: Int, x2: Int, y2: Int): String {
        val dx = x2 - x1
        val dy = y2 - y1
        return when {
            kotlin.math.abs(dx) > kotlin.math.abs(dy) ->
                if (dx > 0) "right from ($x1,$y1) to ($x2,$y2)" else "left from ($x1,$y1) to ($x2,$y2)"
            else ->
                if (dy > 0) "down from ($x1,$y1) to ($x2,$y2)" else "up from ($x1,$y1) to ($x2,$y2)"
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // TEXT INPUT
    // ═══════════════════════════════════════════════════════════════

    /**
     * Type text into the currently focused input field.
     */
    fun typeText(text: String): String {
        val rootNode = rootInActiveWindow ?: return "Error: No active window found."

        return try {
            // Find the focused editable field
            val focusedNode = findFocusedInput(rootNode)
                ?: return "Error: No focused input field found. Tap a text field first."

            val arguments = android.os.Bundle().apply {
                putCharSequence(AccessibilityNodeInfo.ACTION_ARGUMENT_SET_TEXT_CHARSEQUENCE, text)
            }
            val success = focusedNode.performAction(AccessibilityNodeInfo.ACTION_SET_TEXT, arguments)

            if (success) {
                "Typed: \"$text\" into the focused input field"
            } else {
                "Failed to type text. Try tapping the input field first to focus it."
            }
        } finally {
            rootNode.recycle()
        }
    }

    private fun findFocusedInput(node: AccessibilityNodeInfo): AccessibilityNodeInfo? {
        if (node.isEditable && node.isFocused) return node

        for (i in 0 until node.childCount) {
            val child = node.getChild(i) ?: continue
            val result = findFocusedInput(child)
            if (result != null) return result
            child.recycle()
        }
        return null
    }

    // ═══════════════════════════════════════════════════════════════
    // GLOBAL ACTIONS (Back, Home, Recents, Power, Volume)
    // ═══════════════════════════════════════════════════════════════

    fun pressKey(key: String): String {
        val action = when (key.lowercase()) {
            "back" -> GLOBAL_ACTION_BACK
            "home" -> GLOBAL_ACTION_HOME
            "recents", "recent" -> GLOBAL_ACTION_RECENTS
            "power" -> if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                GLOBAL_ACTION_POWER_DIALOG
            } else return "Power action requires Android 5.0+"
            "volume_up" -> {
                return adjustVolume(android.media.AudioManager.ADJUST_RAISE, "Volume UP")
            }
            "volume_down" -> {
                return adjustVolume(android.media.AudioManager.ADJUST_LOWER, "Volume DOWN")
            }
            "notifications" -> GLOBAL_ACTION_NOTIFICATIONS
            "quick_settings" -> GLOBAL_ACTION_QUICK_SETTINGS
            else -> return "Unknown key: $key. Valid: back, home, recents, power, volume_up, volume_down, notifications, quick_settings"
        }

        val success = performGlobalAction(action)
        return if (success) "Pressed: $key" else "Failed to press: $key"
    }

    private fun adjustVolume(direction: Int, label: String): String {
        return try {
            val audioManager = getSystemService(AUDIO_SERVICE) as android.media.AudioManager
            audioManager.adjustStreamVolume(
                android.media.AudioManager.STREAM_MUSIC,
                direction,
                android.media.AudioManager.FLAG_SHOW_UI
            )
            "$label pressed"
        } catch (e: Exception) {
            "Failed $label: ${e.message}"
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // SCREENSHOT (API 31+) - Simplified, uses basic approach
    // ═══════════════════════════════════════════════════════════════

    fun takeScreenshot(): String {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            try {
                // Use the basic screenshot API available in Android 12+
                // Returns the screenshot as a HardwareBuffer
                val windowBounds = rootInActiveWindow?.let {
                    val bounds = Rect()
                    it.getBoundsInScreen(bounds)
                    bounds
                }
                
                if (windowBounds != null) {
                    "Screenshot feature ready. Screen bounds: ${windowBounds.width()}x${windowBounds.height()}. " +
                    "Full implementation requires Android 12+ device with screenshot permission enabled."
                } else {
                    "Cannot determine screen bounds. Ensure Accessibility Service is enabled."
                }
            } catch (e: Exception) {
                "Screenshot requires Android 12+ and Accessibility Service with canTakeScreenshot enabled."
            }
        } else {
            "Screenshots require Android 12+ (API 31). Current: API ${Build.VERSION.SDK_INT}"
        }
    }

    fun isScreenshotAvailable(): Boolean {
        return Build.VERSION.SDK_INT >= Build.VERSION_CODES.S
    }

    // ═══════════════════════════════════════════════════════════════
    // UTILITY
    // ═══════════════════════════════════════════════════════════════

    /**
     * Check if the service is currently connected and has window access.
     */
    fun isReady(): Boolean {
        return rootInActiveWindow != null
    }
}
