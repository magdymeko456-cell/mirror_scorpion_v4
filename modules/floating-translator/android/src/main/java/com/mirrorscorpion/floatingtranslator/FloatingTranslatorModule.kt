package com.mirrorscorpion.floatingtranslator

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import expo.modules.kotlin.modules.Module
import expo.modules.kotlin.modules.ModuleDefinition

class FloatingTranslatorModule : Module() {
  override fun definition() = ModuleDefinition {
    Name("FloatingTranslator")

    Function("isSupported") {
      Build.VERSION.SDK_INT >= Build.VERSION_CODES.M
    }

    Function("canDrawOverlays") {
      val context = appContext.reactContext ?: return@Function false
      Build.VERSION.SDK_INT < Build.VERSION_CODES.M || Settings.canDrawOverlays(context)
    }

    Function("requestOverlayPermission") {
      val context = appContext.reactContext ?: return@Function null
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.canDrawOverlays(context)) {
        val intent = Intent(
          Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
          Uri.parse("package:${context.packageName}")
        ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        appContext.currentActivity?.startActivity(intent)
      }
      null
    }

    AsyncFunction("start") { x: Int?, y: Int? ->
      val context = appContext.reactContext ?: return@AsyncFunction false
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.canDrawOverlays(context)) {
        return@AsyncFunction false
      }

      val position = FloatingTranslatorService.loadPosition(context)
      val intent = Intent(context, FloatingTranslatorService::class.java).apply {
        action = FloatingTranslatorService.ACTION_START
        putExtra(FloatingTranslatorService.EXTRA_X, x ?: position.first)
        putExtra(FloatingTranslatorService.EXTRA_Y, y ?: position.second)
      }

      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
        context.startForegroundService(intent)
      } else {
        context.startService(intent)
      }
      true
    }

    Function("stop") {
      val context = appContext.reactContext ?: return@Function null
      context.stopService(Intent(context, FloatingTranslatorService::class.java))
      null
    }

    Function("isRunning") {
      FloatingTranslatorService.isRunning
    }

    Function("setPosition") { x: Int, y: Int ->
      val context = appContext.reactContext ?: return@Function null
      FloatingTranslatorService.savePosition(context, x, y)
      FloatingTranslatorService.updatePosition(x, y)
      null
    }

    Function("getState") {
      val context = appContext.reactContext
      val position = context?.let { FloatingTranslatorService.loadPosition(it) } ?: Pair(24, 180)
      val supported = Build.VERSION.SDK_INT >= Build.VERSION_CODES.M
      val permissionGranted = context != null && (Build.VERSION.SDK_INT < Build.VERSION_CODES.M || Settings.canDrawOverlays(context))
      mapOf(
        "supported" to supported,
        "permissionGranted" to permissionGranted,
        "running" to FloatingTranslatorService.isRunning,
        "x" to position.first,
        "y" to position.second
      )
    }

    Function("consumeSharedText") {
      val activity = appContext.currentActivity ?: return@Function null
      val intent = activity.intent
      val bubbleText = intent?.getStringExtra(FloatingTranslatorService.EXTRA_BUBBLE_TEXT)
      val action = intent?.action
      val extraKey = when (action) {
        Intent.ACTION_PROCESS_TEXT -> Intent.EXTRA_PROCESS_TEXT
        Intent.ACTION_SEND -> Intent.EXTRA_TEXT
        else -> null
      }
      val sharedText = bubbleText ?: extraKey?.let { key -> intent?.extras?.getCharSequence(key)?.toString() }
      if (!sharedText.isNullOrBlank()) {
        intent?.removeExtra(Intent.EXTRA_TEXT)
        intent?.removeExtra(Intent.EXTRA_PROCESS_TEXT)
        intent?.removeExtra(FloatingTranslatorService.EXTRA_BUBBLE_TEXT)
        intent?.action = Intent.ACTION_MAIN
      }
      sharedText
    }
  }
}
