package com.mirrorscorpion.floatingtranslator

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.os.Build
import android.os.IBinder
import android.provider.Settings
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.TextView
import java.lang.ref.WeakReference
import kotlin.math.abs

class FloatingTranslatorService : Service() {
  companion object {
    const val ACTION_START = "com.mirrorscorpion.floatingtranslator.START"
    const val ACTION_STOP = "com.mirrorscorpion.floatingtranslator.STOP"
    const val EXTRA_X = "overlay_x"
    const val EXTRA_Y = "overlay_y"
    const val EXTRA_BUBBLE_TEXT = "overlay_bubble_text"

    private const val PREFERENCES = "mirror_scorpion_overlay"
    private const val KEY_X = "x"
    private const val KEY_Y = "y"
    private const val NOTIFICATION_CHANNEL = "mirror_scorpion_overlay"
    private const val NOTIFICATION_ID = 731

    @Volatile
    var isRunning: Boolean = false
      private set

    private var instance: WeakReference<FloatingTranslatorService>? = null

    fun loadPosition(context: Context): Pair<Int, Int> {
      val preferences = context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
      return Pair(preferences.getInt(KEY_X, 24), preferences.getInt(KEY_Y, 180))
    }

    fun savePosition(context: Context, x: Int, y: Int) {
      context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
        .edit()
        .putInt(KEY_X, x)
        .putInt(KEY_Y, y)
        .apply()
    }

    fun updatePosition(x: Int, y: Int) {
      instance?.get()?.moveTo(x, y)
    }
  }

  private lateinit var windowManager: WindowManager
  private var bubble: TextView? = null
  private var layoutParams: WindowManager.LayoutParams? = null
  private var initialX = 0
  private var initialY = 0
  private var downX = 0f
  private var downY = 0f

  override fun onCreate() {
    super.onCreate()
    instance = WeakReference(this)
    isRunning = true
    createNotificationChannel()
    startForeground(NOTIFICATION_ID, createNotification())
    showBubble(loadPosition(this).first, loadPosition(this).second)
  }

  override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
    if (intent?.action == ACTION_STOP) {
      stopSelf()
      return START_NOT_STICKY
    }

    val position = loadPosition(this)
    val x = intent?.getIntExtra(EXTRA_X, position.first) ?: position.first
    val y = intent?.getIntExtra(EXTRA_Y, position.second) ?: position.second
    savePosition(this, x, y)
    if (bubble == null) showBubble(x, y) else moveTo(x, y)
    return START_STICKY
  }

  override fun onDestroy() {
    bubble?.let { view ->
      runCatching { windowManager.removeView(view) }
    }
    bubble = null
    layoutParams = null
    instance = null
    isRunning = false
    super.onDestroy()
  }

  override fun onBind(intent: Intent?): IBinder? = null

  private fun showBubble(x: Int, y: Int) {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.canDrawOverlays(this)) {
      stopSelf()
      return
    }

    windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
    val size = dp(56)
    val windowType = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
      WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
    } else {
      @Suppress("DEPRECATION")
      WindowManager.LayoutParams.TYPE_PHONE
    }

    layoutParams = WindowManager.LayoutParams(
      size,
      size,
      windowType,
      WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
        WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
      PixelFormat.TRANSLUCENT
    ).apply {
      gravity = Gravity.TOP or Gravity.START
      this.x = x
      this.y = y
    }

    bubble = TextView(this).apply {
      text = "文"
      textSize = 21f
      setTextColor(Color.WHITE)
      gravity = Gravity.CENTER
      setBackgroundColor(Color.rgb(10, 126, 164))
      elevation = dp(8).toFloat()
      contentDescription = "فتح ترجمة Mirror Scorpion"
      setOnTouchListener(DragListener())
    }

    runCatching {
      windowManager.addView(requireNotNull(bubble), requireNotNull(layoutParams))
    }.onFailure {
      bubble = null
      layoutParams = null
      stopSelf()
    }
  }

  private fun moveTo(x: Int, y: Int) {
    val view = bubble ?: return
    val params = layoutParams ?: return
    params.x = x.coerceAtLeast(0)
    params.y = y.coerceAtLeast(0)
    runCatching { windowManager.updateViewLayout(view, params) }
  }

  private inner class DragListener : View.OnTouchListener {
    override fun onTouch(view: View, event: MotionEvent): Boolean {
      val params = layoutParams ?: return false
      when (event.actionMasked) {
        MotionEvent.ACTION_DOWN -> {
          initialX = params.x
          initialY = params.y
          downX = event.rawX
          downY = event.rawY
          return true
        }
        MotionEvent.ACTION_MOVE -> {
          params.x = initialX + (event.rawX - downX).toInt()
          params.y = initialY + (event.rawY - downY).toInt()
          runCatching { windowManager.updateViewLayout(view, params) }
          return true
        }
        MotionEvent.ACTION_UP -> {
          val moved = abs(event.rawX - downX) > dp(8) || abs(event.rawY - downY) > dp(8)
          savePosition(this@FloatingTranslatorService, params.x, params.y)
          if (!moved) openTranslator()
          view.performClick()
          return true
        }
      }
      return false
    }
  }

  private fun openTranslator() {
    val sharedText = readClipboardText()
    val intent = packageManager.getLaunchIntentForPackage(packageName)?.apply {
      addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP)
      putExtra("mirror_scorpion_open_translator", true)
      if (!sharedText.isNullOrBlank()) putExtra(EXTRA_BUBBLE_TEXT, sharedText)
    } ?: return
    runCatching { startActivity(intent) }
  }

  private fun readClipboardText(): String? {
    val clipboard = getSystemService(CLIPBOARD_SERVICE) as? ClipboardManager ?: return null
    if (!clipboard.hasPrimaryClip()) return null
    val clip: ClipData = clipboard.primaryClip ?: return null
    if (clip.itemCount == 0) return null
    return clip.getItemAt(0).coerceToText(this)?.toString()?.takeIf { it.isNotBlank() }
  }

  private fun createNotificationChannel() {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
    val manager = getSystemService(NotificationManager::class.java)
    manager.createNotificationChannel(
      NotificationChannel(
        NOTIFICATION_CHANNEL,
        "Mirror Scorpion translator bubble",
        NotificationManager.IMPORTANCE_LOW
      ).apply {
        description = "Keeps the translation bubble available above other apps."
        setShowBadge(false)
      }
    )
  }

  private fun createNotification(): Notification {
    val launchIntent = packageManager.getLaunchIntentForPackage(packageName)?.apply {
      addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
    }
    val pendingIntent = launchIntent?.let {
      PendingIntent.getActivity(
        this,
        0,
        it,
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
      )
    }
    val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
      Notification.Builder(this, NOTIFICATION_CHANNEL)
    } else {
      @Suppress("DEPRECATION")
      Notification.Builder(this)
    }
    return builder
      .setSmallIcon(android.R.drawable.ic_menu_search)
      .setContentTitle("Mirror Scorpion")
      .setContentText("فقاعة الترجمة العائمة مفعلة")
      .setOngoing(true)
      .setCategory(Notification.CATEGORY_SERVICE)
      .apply { if (pendingIntent != null) setContentIntent(pendingIntent) }
      .build()
  }

  private fun dp(value: Int): Int = (value * resources.displayMetrics.density).toInt()
}
