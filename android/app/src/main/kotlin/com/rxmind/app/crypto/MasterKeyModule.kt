package com.rxmind.app.crypto

import android.content.Context
import android.content.SharedPreferences
import android.os.Build
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import android.util.Log
import java.io.File
import java.io.IOException
import java.io.RandomAccessFile
import java.security.KeyStore
import java.security.SecureRandom
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.SecretKeyFactory
import javax.crypto.spec.GCMParameterSpec
import javax.crypto.spec.PBEKeySpec
import javax.crypto.spec.SecretKeySpec

object MasterKeyModule {
    private const val TAG = "RxMindCrypto"
    const val CHANNEL = "rxmind/crypto"
    const val MASTER_KEY_ALIAS = "rxmind_mk_v1"
    private const val PREFS_NAME = "rxmind_crypto_prefs"
    private const val KEY_ENCRYPTED_DEK = "encrypted_dek_v1"
    private const val KEY_DEK_IV = "dek_iv_v1"
    private const val KEY_SALT = "db_salt_v1"
    private const val PBKDF2_ITERATIONS = 100_000

    private fun cryptoPrefs(context: Context): SharedPreferences =
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    fun provisionMasterKey(context: Context): Boolean {
        return try {
            ensureMasterKeyExists(context)
            ensureDekProvisioned(context)
            ensureSaltProvisioned(context)
            true
        } catch (e: Exception) {
            Log.e(TAG, "provisionMasterKey failed", e)
            false
        }
    }

    fun getMasterKeyAlias(): String = MASTER_KEY_ALIAS

    fun isStrongBoxBacked(context: Context): Boolean {
        return context.packageManager.hasSystemFeature(
            android.content.pm.PackageManager.FEATURE_STRONGBOX_KEYSTORE
        )
    }

    fun ensureMasterKeyExists(context: Context) {
        val keyStore = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
        if (keyStore.containsAlias(MASTER_KEY_ALIAS)) return

        val strongBoxAvailable = isStrongBoxBacked(context)
        val builder = KeyGenParameterSpec.Builder(
            MASTER_KEY_ALIAS,
            KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT
        )
            .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
            .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
            .setKeySize(256)
            .setUserAuthenticationRequired(false)
            .setInvalidatedByBiometricEnrollment(true)

        if (strongBoxAvailable && Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            builder.setIsStrongBoxBacked(true)
        } else {
            Log.w(TAG, "StrongBox unavailable; using TEE-backed Keystore")
        }

        KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore")
            .init(builder.build())
            .generateKey()
    }

    private fun ensureDekProvisioned(context: Context) {
        val prefs = cryptoPrefs(context)
        if (prefs.contains(KEY_ENCRYPTED_DEK)) return

        val dek = ByteArray(32).also { SecureRandom().nextBytes(it) }
        val iv = ByteArray(12).also { SecureRandom().nextBytes(it) }
        val keyStore = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
        val secretKey = keyStore.getKey(MASTER_KEY_ALIAS, null) as SecretKey

        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.ENCRYPT_MODE, secretKey, GCMParameterSpec(128, iv))
        val encryptedDek = cipher.doFinal(dek)
        dek.fill(0)

        prefs.edit()
            .putString(KEY_ENCRYPTED_DEK, Base64.encodeToString(encryptedDek, Base64.NO_WRAP))
            .putString(KEY_DEK_IV, Base64.encodeToString(iv, Base64.NO_WRAP))
            .apply()
    }

    private fun ensureSaltProvisioned(context: Context) {
        val prefs = cryptoPrefs(context)
        if (prefs.contains(KEY_SALT)) return
        val salt = ByteArray(32).also { SecureRandom().nextBytes(it) }
        prefs.edit()
            .putString(KEY_SALT, Base64.encodeToString(salt, Base64.NO_WRAP))
            .apply()
    }

    fun getSalt(context: Context): ByteArray {
        ensureSaltProvisioned(context)
        val encoded = cryptoPrefs(context).getString(KEY_SALT, null)
            ?: throw IllegalStateException("Salt not provisioned")
        return Base64.decode(encoded, Base64.NO_WRAP)
    }

    fun deriveDatabaseKey(context: Context): ByteArray {
        ensureMasterKeyExists(context)
        ensureDekProvisioned(context)
        ensureSaltProvisioned(context)

        val prefs = cryptoPrefs(context)
        val encryptedDekB64 = prefs.getString(KEY_ENCRYPTED_DEK, null)
            ?: throw IllegalStateException("DEK not provisioned")
        val ivB64 = prefs.getString(KEY_DEK_IV, null)
            ?: throw IllegalStateException("DEK IV not provisioned")

        val keyStore = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
        if (!keyStore.containsAlias(MASTER_KEY_ALIAS)) {
            throw IllegalStateException("Master key unavailable")
        }
        val secretKey = keyStore.getKey(MASTER_KEY_ALIAS, null) as SecretKey

        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(
            Cipher.DECRYPT_MODE,
            secretKey,
            GCMParameterSpec(128, Base64.decode(ivB64, Base64.NO_WRAP))
        )
        val dek = cipher.doFinal(Base64.decode(encryptedDekB64, Base64.NO_WRAP))
        val salt = getSalt(context)

        return try {
            pbkdf2Sha256(dek, salt, PBKDF2_ITERATIONS, 32)
        } finally {
            dek.fill(0)
        }
    }

    private fun pbkdf2Sha256(
        password: ByteArray,
        salt: ByteArray,
        iterations: Int,
        keyLengthBytes: Int
    ): ByteArray {
        val spec = PBEKeySpec(
            password.map { (it.toInt() and 0xFF).toChar() }.toCharArray(),
            salt,
            iterations,
            keyLengthBytes * 8
        )
        return SecretKeyFactory.getInstance("PBKDF2WithHmacSHA256")
            .generateSecret(spec)
            .encoded
    }

    fun secureDeleteFile(file: File) {
        if (!file.exists()) return
        val length = file.length()
        if (length == 0L) {
            file.delete()
            return
        }
        RandomAccessFile(file, "rws").use { raf ->
            raf.seek(0)
            raf.write(ByteArray(length.toInt()) { 0 })
            raf.fd.sync()
            raf.seek(0)
            raf.write(ByteArray(length.toInt()) { 0xFF.toByte() })
            raf.fd.sync()
            val random = ByteArray(length.toInt())
            SecureRandom().nextBytes(random)
            raf.seek(0)
            raf.write(random)
            raf.fd.sync()
        }
        if (!file.delete()) throw IOException("Failed to delete ${file.path}")
    }

    fun wipeAll(context: Context) {
        val dbPath = context.getDatabasePath("rxmind.db")
        val dbDir = dbPath.parentFile
        if (dbDir != null && dbDir.exists()) {
            listOf("rxmind.db", "rxmind.db-wal", "rxmind.db-shm").forEach { name ->
                secureDeleteFile(File(dbDir, name))
            }
        }

        val supportDir = File(context.filesDir.parent, "app_flutter")
        if (supportDir.exists()) {
            File(supportDir, "rxmind.db").let { if (it.exists()) secureDeleteFile(it) }
            File(supportDir, "rxmind.db-wal").let { if (it.exists()) secureDeleteFile(it) }
            File(supportDir, "rxmind.db-shm").let { if (it.exists()) secureDeleteFile(it) }
        }

        val keyStore = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
        if (keyStore.containsAlias(MASTER_KEY_ALIAS)) {
            keyStore.deleteEntry(MASTER_KEY_ALIAS)
        }

        cryptoPrefs(context).edit().clear().apply()
        context.cacheDir.deleteRecursively()
        context.codeCacheDir?.deleteRecursively()
    }
}
