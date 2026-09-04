package com.example.take_home

import android.app.DatePickerDialog
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import android.os.Build
import android.view.Gravity
import android.widget.LinearLayout
import android.widget.TextView
import com.google.android.material.bottomsheet.BottomSheetDialog
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Calendar

class MainActivity : FlutterActivity() {
    private val channelName = "com.smartworkspace.app/native"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "pickDate" -> pickDate(call.argument<String>("initialDate"), result)
                        "showNativeOptionsSheet" -> showNativeOptionsSheet(result)
                        "getDeviceInfo" -> result.success(deviceInfo())
                        else -> result.notImplemented()
                    }
                } catch (e: Exception) {
                    result.error("NATIVE_ERROR", e.message, null)
                }
            }
    }

    private fun pickDate(initialDateIso: String?, result: MethodChannel.Result) {
        val calendar = Calendar.getInstance()
        initialDateIso?.split("-")?.let { parts ->
            if (parts.size == 3) {
                calendar.set(parts[0].toInt(), parts[1].toInt() - 1, parts[2].toInt())
            }
        }

        var answered = false
        val dialog = DatePickerDialog(
            this,
            { _, year, month, day ->
                // DatePickerDialog's listener already runs on the main thread,
                // so result.success can be called directly from here.
                answered = true
                result.success("%04d-%02d-%02d".format(year, month + 1, day))
            },
            calendar.get(Calendar.YEAR),
            calendar.get(Calendar.MONTH),
            calendar.get(Calendar.DAY_OF_MONTH),
        )
        dialog.setOnDismissListener { if (!answered) result.success(null) }
        dialog.show()
    }

    private fun showNativeOptionsSheet(result: MethodChannel.Result) {
        val dialog = BottomSheetDialog(
            this,
            com.google.android.material.R.style.Theme_MaterialComponents_DayNight_BottomSheetDialog,
        )
        var answered = false

        val options = listOf(
            Triple("camera", "Camera", android.R.drawable.ic_menu_camera),
            Triple("gallery", "Gallery", android.R.drawable.ic_menu_gallery),
            Triple("file", "File Picker", android.R.drawable.ic_menu_agenda),
        )
        val container = LinearLayout(dialog.context).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(0, 24, 0, 24)
        }
        for ((value, label, icon) in options) {
            container.addView(
                TextView(dialog.context).apply {
                    text = label
                    textSize = 16f
                    gravity = Gravity.CENTER_VERTICAL
                    setCompoundDrawablesWithIntrinsicBounds(icon, 0, 0, 0)
                    compoundDrawablePadding = 32
                    setPadding(48, 32, 48, 32)
                    isClickable = true
                    setOnClickListener {
                        answered = true
                        result.success(value)
                        dialog.dismiss()
                    }
                },
            )
        }
        dialog.setContentView(container)
        dialog.setOnDismissListener { if (!answered) result.success(null) }
        dialog.show()
    }

    private fun deviceInfo(): Map<String, Any> {
        val battery = applicationContext.registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
        val level = battery?.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) ?: -1
        val scale = battery?.getIntExtra(BatteryManager.EXTRA_SCALE, -1) ?: -1
        val batteryPercent = if (level >= 0 && scale > 0) level * 100 / scale else -1

        return mapOf(
            "model" to Build.MODEL,
            "osVersion" to Build.VERSION.RELEASE,
            "batteryPercent" to batteryPercent,
        )
    }
}
