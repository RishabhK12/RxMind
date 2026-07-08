package com.rxmind.app

import android.content.Intent
import com.rxmind.app.contacts.ContactPickerModule
import com.rxmind.app.crypto.MasterKeyModule
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private lateinit var contactPickerModule: ContactPickerModule

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        contactPickerModule = ContactPickerModule(this)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            ContactPickerModule.CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "pickSingleContact" -> contactPickerModule.pickSingleContact(result)
                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            MasterKeyModule.CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "provisionMasterKey" -> {
                    result.success(MasterKeyModule.provisionMasterKey(this))
                }
                "getMasterKeyAlias" -> {
                    result.success(MasterKeyModule.getMasterKeyAlias())
                }
                "isStrongBoxBacked" -> {
                    result.success(MasterKeyModule.isStrongBoxBacked(this))
                }
                "deriveDatabaseKey" -> {
                    try {
                        val key = MasterKeyModule.deriveDatabaseKey(this)
                        result.success(key)
                    } catch (e: Exception) {
                        result.error("DATABASE_KEY_UNAVAILABLE", e.message, null)
                    }
                }
                "getSalt" -> {
                    try {
                        result.success(MasterKeyModule.getSalt(this))
                    } catch (e: Exception) {
                        result.error("SALT_UNAVAILABLE", e.message, null)
                    }
                }
                "wipeAll" -> {
                    try {
                        MasterKeyModule.wipeAll(this)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("WIPE_FAILED", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (::contactPickerModule.isInitialized) {
            contactPickerModule.onActivityResult(requestCode, resultCode, data)
        }
    }
}
