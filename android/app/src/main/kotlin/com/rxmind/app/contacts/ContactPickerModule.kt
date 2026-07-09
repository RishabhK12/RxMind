package com.rxmind.app.contacts

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.provider.ContactsContract
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class ContactPickerModule(private val activity: FlutterActivity) {
    private var pendingResult: MethodChannel.Result? = null

    fun pickSingleContact(result: MethodChannel.Result) {
        pendingResult = result
        val intent = Intent(
            Intent.ACTION_PICK,
            ContactsContract.CommonDataKinds.Phone.CONTENT_URI
        )
        activity.startActivityForResult(intent, PICK_CONTACT_REQUEST)
    }

    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode != PICK_CONTACT_REQUEST) return
        val result = pendingResult ?: return
        pendingResult = null

        if (resultCode != Activity.RESULT_OK || data == null) {
            result.success(null)
            return
        }

        val uri: Uri = data.data ?: run {
            result.success(null)
            return
        }

        try {
            val projection = arrayOf(
                ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME,
                ContactsContract.CommonDataKinds.Phone.NUMBER
            )
            activity.contentResolver.query(uri, projection, null, null, null)
                ?.use { cursor ->
                    if (!cursor.moveToFirst()) {
                        result.success(null)
                        return
                    }
                    val nameIdx =
                        cursor.getColumnIndex(ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME)
                    val phoneIdx =
                        cursor.getColumnIndex(ContactsContract.CommonDataKinds.Phone.NUMBER)
                    val name = if (nameIdx >= 0) cursor.getString(nameIdx) ?: "" else ""
                    val phone = if (phoneIdx >= 0) cursor.getString(phoneIdx) ?: "" else ""
                    result.success(mapOf("name" to name, "phone" to phone))
                } ?: result.success(null)
        } catch (e: Exception) {
            result.error("PICK_FAILED", e.message, null)
        }
    }

    companion object {
        const val CHANNEL = "rxmind/contacts"
        const val PICK_CONTACT_REQUEST = 9001
    }
}
