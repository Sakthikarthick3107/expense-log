package com.expenseapp.expense_log

import android.Manifest
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.os.Bundle
import android.telephony.SmsMessage
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.MethodCall
import android.util.Log
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import androidx.core.content.FileProvider

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.expenseapp.expense_log/install"
     private val SETTINGS_CHANNEL = "com.expenseapp.expense_log/alarm_settings"
    private val SMS_PERMISSION_CODE = 101

    // private val smsReceiver = object : BroadcastReceiver() {
    //     override fun onReceive(context: Context, intent: Intent) {
    //         // Listen for our custom broadcast "com.yourapp.SMS_CAPTURED"
    //         if (intent.action == "com.expenseapp.expense_log.SMS_CAPTURED") {
    //             val sender = intent.getStringExtra("sender")
    //             val body = intent.getStringExtra("body")

    //             // Send the captured data to Flutter via MethodChannel
    //             sendToFlutter(sender, body)
    //         }
    //     }
    // }

    // override fun onStart() {
    //     super.onStart()

    //     // Register the receiver to listen for SMS capture broadcast
    //     LocalBroadcastManager.getInstance(this).registerReceiver(
    //         smsReceiver,
    //         IntentFilter("com.expenseapp.expense_log.SMS_CAPTURED")
    //     )
    // }

    // override fun onStop() {
    //     super.onStop()

    //     // Unregister the receiver when no longer needed
    //     LocalBroadcastManager.getInstance(this).unregisterReceiver(smsReceiver)
    // }

    // // Send SMS data to Flutter via MethodChannel
    // private fun sendToFlutter(sender: String?, body: String?) {
    //     val channel = MethodChannel(flutterEngine?.dartExecutor, "com.expenseapp.expense_log/sms_capture")
    //     channel.invokeMethod("onSmsReceived", mapOf("sender" to sender, "body" to body))
    // }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "installApk") {
                val apkPath = call.argument<String>("apkPath")
                if (apkPath != null) {
                    val installSuccess = installApk(apkPath)
                    result.success(installSuccess)
                } else {
                    result.error("APK_PATH_ERROR", "APK path is null", null)
                }
            } else {
                result.notImplemented()
            }
        }

    }

    private fun installApk(apkPath: String): Boolean {
        return try {
            val apkFile = File(apkPath)
            if (!apkFile.exists()) {
                return false
            }
            val fileUri: Uri = FileProvider.getUriForFile(
                this,
                "com.expenseapp.expense_log.provider", 
                apkFile
            )

            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(fileUri, "application/vnd.android.package-archive")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_GRANT_READ_URI_PERMISSION
            }

            startActivity(intent)
            true
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }

    
}
