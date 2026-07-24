package com.wgn.driver.taxiapp
import android.content.Context
import android.content.Intent
import android.graphics.PixelFormat
import android.os.Build
import android.provider.Settings
import android.util.Log
import android.view.Gravity
import android.view.MotionEvent
import android.view.WindowManager
import android.widget.ImageView
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.net.Uri

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.wgn.driver.taxiapp/floating_bubble"
    private val TAG = "MainActivity"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (!hasOverlayPermission()) {
                Log.e(TAG, "Overlay permission not granted")
                result.error("PERMISSION_ERROR", "Overlay permission not granted", null)
                val intent = Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION, Uri.parse("package:$packageName"))
                startActivity(intent)
                return@setMethodCallHandler
            }

            when (call.method) {
                "showBubble" -> {
                    try {
                        BubbleManager.showBubble(this)
                        result.success("Bubble shown")
                    } catch (e: Exception) {
                        Log.e(TAG, "Failed to show bubble: ${e.message}")
                        result.error("BUBBLE_ERROR", "Failed to show bubble: ${e.message}", null)
                    }
                }
                "hideBubble" -> {
                    try {
                        BubbleManager.hideBubble()
                        result.success("Bubble hidden")
                    } catch (e: Exception) {
                        Log.e(TAG, "Failed to hide bubble: ${e.message}")
                        result.error("BUBBLE_ERROR", "Failed to hide bubble: ${e.message}", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun hasOverlayPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Settings.canDrawOverlays(this)
        } else {
            true
        }
    }

    override fun onDestroy() {
        try {
            super.onDestroy()
        } catch (e: NullPointerException) {
            // Workaround for location plugin crash during activity relaunch/config-change detach.
            val isLocationPluginDestroyNpe =
                e.message?.contains("FlutterLocationService") == true ||
                e.stackTraceToString().contains("com.lyokone.location.LocationPlugin")
            if (!isLocationPluginDestroyNpe) {
                throw e
            }
            Log.w(TAG, "Ignoring known location plugin destroy NPE: ${e.message}")
        } finally {
            BubbleManager.hideBubble() // Ensure bubble is removed when activity is destroyed
        }
    }
}

object BubbleManager {
    private var bubbleView: ImageView? = null
    private var params: WindowManager.LayoutParams? = null
    private var windowManager: WindowManager? = null
    private const val TAG = "BubbleManager"
    private var initialX: Int = 0
    private var initialY: Int = 0
    private var initialTouchX: Float = 0f
    private var initialTouchY: Float = 0f
    private var touchStartTime: Long = 0
    private var isDragging: Boolean = false
    private const val maxClickDuration = 200 // Max duration for a click (ms)
    private const val maxClickDistance = 10 // Max movement for a click (pixels)

    fun showBubble(context: Context) {
        // Remove any existing bubble first
        hideBubble()

        windowManager = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
        bubbleView = ImageView(context).apply {
            setImageResource(R.mipmap.launcher_icon)
            layoutParams = WindowManager.LayoutParams(150, 150)
            clipToOutline = true
            background = android.graphics.drawable.GradientDrawable().apply {
                shape = android.graphics.drawable.GradientDrawable.OVAL
                setColor(0xFF000000.toInt())
            }
            setOnClickListener {
                Log.d(TAG, "Bubble clicked, launching app")
                val intent = Intent(context, MainActivity::class.java).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                }
                try {
                    context.startActivity(intent)
                    Log.d(TAG, "App launched successfully")
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to launch app: ${e.message}")
                }
            }
            setOnTouchListener { _, event ->
                when (event.action) {
                    MotionEvent.ACTION_DOWN -> {
                        initialX = params?.x ?: 0
                        initialY = params?.y ?: 0
                        initialTouchX = event.rawX
                        initialTouchY = event.rawY
                        touchStartTime = System.currentTimeMillis()
                        isDragging = false
                        true
                    }
                    MotionEvent.ACTION_MOVE -> {
                        val deltaX = (event.rawX - initialTouchX).toInt()
                        val deltaY = (event.rawY - initialTouchY).toInt()
                        if (Math.abs(deltaX) > maxClickDistance || Math.abs(deltaY) > maxClickDistance) {
                            isDragging = true
                        }
                        if (isDragging) {
                            params?.x = initialX + deltaX
                            params?.y = initialY + deltaY
                            windowManager?.updateViewLayout(bubbleView, params)
                            Log.d(TAG, "Dragging to x=${params?.x}, y=${params?.y}")
                        }
                        true
                    }
                    MotionEvent.ACTION_UP -> {
                        val touchDuration = System.currentTimeMillis() - touchStartTime
                        if (!isDragging && touchDuration < maxClickDuration) {
                            performClick() // Trigger click listener for short taps
                        }
                        isDragging = false
                        true
                    }
                    else -> false
                }
            }
        }

        val type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            WindowManager.LayoutParams.TYPE_PHONE
        }
        params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            type,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = 0
            y = 100
        }

        try {
            windowManager?.addView(bubbleView, params)
            Log.d(TAG, "Bubble shown at x=${params?.x}, y=${params?.y}")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to add bubble to WindowManager: ${e.message}")
            bubbleView = null
            params = null
            windowManager = null
            throw e
        }
    }

    fun hideBubble() {
        try {
            if (bubbleView != null && bubbleView?.parent != null) {
                windowManager?.removeView(bubbleView)
                Log.d(TAG, "Bubble removed")
            } else {
                Log.d(TAG, "No bubble to remove")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to remove bubble: ${e.message}")
        } finally {
            bubbleView = null
            params = null
            windowManager = null
        }
    }
}
