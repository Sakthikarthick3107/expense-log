package com.expenseapp.expense_log

import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import androidx.core.content.FileProvider

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.expenseapp.expense_log/install"

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
