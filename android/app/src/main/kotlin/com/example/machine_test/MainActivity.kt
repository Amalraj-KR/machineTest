package com.example.machine_test

import android.app.Activity
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.database.Cursor
import android.net.Uri
import android.os.BatteryManager
import android.os.Build
import android.provider.MediaStore
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.InputStream

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.machine_test/platform"
    private val BATTERY_CHANNEL = "com.example.machine_test/battery"
    private val PICK_IMAGE_REQUEST = 1000
    
    private lateinit var methodChannel: MethodChannel
    private lateinit var batteryChannel: EventChannel
    private var batteryReceiver: BroadcastReceiver? = null
    private var batteryEventSink: EventChannel.EventSink? = null
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "getDeviceModel" -> {
                    result.success(getDeviceModel())
                }
                "getAndroidVersion" -> {
                    result.success(getAndroidVersion())
                }
                "getBatteryLevel" -> {
                    val batteryLevel = getBatteryLevel()
                    if (batteryLevel != -1) {
                        result.success(batteryLevel)
                    } else {
                        result.error("UNAVAILABLE", "Battery level not available.", null)
                    }
                }
                "pickImage" -> {
                    pendingResult = result
                    pickImage()
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // Battery level stream
        batteryChannel = EventChannel(flutterEngine.dartExecutor.binaryMessenger, BATTERY_CHANNEL)
        batteryChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                batteryEventSink = events
                startBatteryLevelListener()
            }

            override fun onCancel(arguments: Any?) {
                stopBatteryLevelListener()
                batteryEventSink = null
            }
        })
    }

    private fun getDeviceModel(): String {
        return "${Build.MANUFACTURER} ${Build.MODEL}"
    }

    private fun getAndroidVersion(): String {
        return "Android ${Build.VERSION.RELEASE} (API ${Build.VERSION.SDK_INT})"
    }

    private fun getBatteryLevel(): Int {
        val batteryManager = getSystemService(Context.BATTERY_SERVICE) as BatteryManager
        return batteryManager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
    }

    private fun startBatteryLevelListener() {
        batteryReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                val level = getBatteryLevel()
                batteryEventSink?.success(level)
            }
        }
        
        val filter = IntentFilter(Intent.ACTION_BATTERY_CHANGED)
        registerReceiver(batteryReceiver, filter)
        
        // Send initial battery level
        val initialLevel = getBatteryLevel()
        batteryEventSink?.success(initialLevel)
    }

    private fun stopBatteryLevelListener() {
        batteryReceiver?.let {
            unregisterReceiver(it)
            batteryReceiver = null
        }
    }

    private fun pickImage() {
        val intent = Intent(Intent.ACTION_PICK, MediaStore.Images.Media.EXTERNAL_CONTENT_URI)
        intent.type = "image/*"
        startActivityForResult(intent, PICK_IMAGE_REQUEST)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        
        when (requestCode) {
            PICK_IMAGE_REQUEST -> {
                if (resultCode == Activity.RESULT_OK && data?.data != null) {
                    val imageUri = data.data
                    try {
                        val imageBytes = getImageBytes(imageUri!!)
                        pendingResult?.success(imageBytes)
                    } catch (e: Exception) {
                        pendingResult?.error("IMAGE_PICK_ERROR", "Failed to load image: ${e.message}", null)
                    }
                } else {
                    pendingResult?.error("IMAGE_PICK_CANCELLED", "Image picking was cancelled", null)
                }
                pendingResult = null
            }
        }
    }

    private fun getImageBytes(uri: Uri): ByteArray {
        val inputStream: InputStream? = contentResolver.openInputStream(uri)
        val byteArrayOutputStream = ByteArrayOutputStream()
        val buffer = ByteArray(1024)
        var bytesRead: Int
        
        inputStream?.use { input ->
            while (input.read(buffer).also { bytesRead = it } != -1) {
                byteArrayOutputStream.write(buffer, 0, bytesRead)
            }
        }
        
        return byteArrayOutputStream.toByteArray()
    }

    override fun onDestroy() {
        super.onDestroy()
        stopBatteryLevelListener()
    }
}
