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
    private val SMS_PERMISSION_CODE = 101

//    override fun onCreate(savedInstanceState: Bundle?) {
//        super.onCreate(savedInstanceState)
//        requestSmsPermission()
//        registerSmsReceiver()
//        // Initialize MethodChannel properly
//        MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
//            if (call.method == "onSmsReceived") {
//                val message = call.arguments as String
//                Log.d("SMS_RECEIVER", "📩 SMS Data Sent to Flutter: $message")
//                result.success(null)
//            }
//        }
//    }

//    private fun requestSmsPermission() {
//        val permissions = arrayOf(
//            Manifest.permission.RECEIVE_SMS,
//            Manifest.permission.READ_SMS
//        )
//
//        if (ContextCompat.checkSelfPermission(this, Manifest.permission.RECEIVE_SMS)
//            != PackageManager.PERMISSION_GRANTED) {
//            ActivityCompat.requestPermissions(this, permissions, SMS_PERMISSION_CODE)
//        }
//    }

//    private fun registerSmsReceiver() {
//        val filter = IntentFilter("android.provider.Telephony.SMS_RECEIVED")
//        registerReceiver(smsReceiver, filter)
//    }

//    private val smsReceiver = object : BroadcastReceiver() {
//        override fun onReceive(context: Context?, intent: Intent?) {
//            if (intent?.action == "android.provider.Telephony.SMS_RECEIVED") {
//                val bundle = intent.extras
//                if (bundle != null) {
//                    val pdus = bundle["pdus"] as Array<*>?
//                    pdus?.forEach { pdu ->
//                        val format = bundle.getString("format")
//                        val sms = SmsMessage.createFromPdu(pdu as ByteArray, format)
//                        val messageBody = sms.messageBody
//
//                        if (messageBody.contains("UPI") && messageBody.contains("debited", ignoreCase = true)) {
//                            // Send SMS content to Flutter via MethodChannel
//                            MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, CHANNEL)
//                                .invokeMethod("onSmsReceived", messageBody)
//                        }
//                    }
//                }
//            }
//        }
//    }

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
            // Use FileProvider to generate a content URI
            if (!apkFile.exists()) {
                return false
            }
            val fileUri: Uri = FileProvider.getUriForFile(
                this,
                "com.expenseapp.expense_log.provider", // This should match the authorities in your Manifest
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
