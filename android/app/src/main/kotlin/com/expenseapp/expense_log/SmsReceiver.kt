package com.expenseapp.expense_log

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Environment
import android.provider.Telephony
import android.telephony.SmsMessage
import java.io.File
import java.io.FileOutputStream

class SmsReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (Telephony.Sms.Intents.SMS_RECEIVED_ACTION == intent.action) {
            val bundle = intent.extras  
            if (bundle != null) {
                val pdus = bundle.get("pdus") as Array<*>
                val format = bundle.getString("format")
                val messages = pdus.mapNotNull { pdu ->
                    SmsMessage.createFromPdu(pdu as ByteArray, format)
                }
                val externalDir = context.getExternalFilesDir(null) 
                val logFile = File(externalDir, "upi_logs.txt")
                val logText = messages.joinToString("\n") { msg ->
                    "${msg.displayOriginatingAddress}: ${msg.messageBody}"
                } + "\n---\n"

                FileOutputStream(logFile, true).bufferedWriter().use {
                    it.append(logText)
                }
            }
        }
    }
}
