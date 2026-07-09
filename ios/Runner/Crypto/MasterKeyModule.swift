import Foundation
import Security
import CryptoKit
import CommonCrypto

enum CryptoError: Error {
    case accessControlFailed
    case secureEnclaveUnavailable
    case keyNotFound
    case derivationFailed
}

@objc class MasterKeyModule: NSObject {
    static let channel = "rxmind/crypto"
    private static let masterKeyTag = "org.rxmind.app.mk.v1"
    private static let dekKey = "rxmind_encrypted_dek_v1"
    private static let dekIvKey = "rxmind_dek_iv_v1"
    private static let saltKey = "rxmind_db_salt_v1"
    private static let pbkdf2Iterations = 100_000

    @objc static func provisionMasterKey() -> Bool {
        do {
            try ensureMasterKeyExists()
            try ensureDekProvisioned()
            try ensureSaltProvisioned()
            return true
        } catch {
            NSLog("RxMindCrypto provisionMasterKey failed: \(error)")
            return false
        }
    }

    @objc static func getMasterKeyAlias() -> String {
        masterKeyTag
    }

    @objc static func deriveDatabaseKey() throws -> Data {
        try ensureMasterKeyExists()
        try ensureDekProvisioned()
        try ensureSaltProvisioned()

        guard let encryptedDekB64 = UserDefaults.standard.string(forKey: dekKey),
              let ivB64 = UserDefaults.standard.string(forKey: dekIvKey),
              let encryptedDek = Data(base64Encoded: encryptedDekB64),
              let iv = Data(base64Encoded: ivB64) else {
            throw CryptoError.derivationFailed
        }

        let privateKey = try loadPrivateKey()
        let dek = try decryptDek(privateKey: privateKey, encrypted: encryptedDek, iv: iv)
        let salt = try getSaltData()

        defer { dek.withUnsafeMutableBytes { ptr in
            if let base = ptr.baseAddress { memset(base, 0, ptr.count) }
        }}

        return try pbkdf2(password: dek, salt: salt, iterations: pbkdf2Iterations, keyLength: 32)
    }

    @objc static func getSalt() throws -> Data {
        try getSaltData()
    }

    @objc static func wipeAll() throws {
        let fm = FileManager.default
        if let support = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            for suffix in ["", "-wal", "-shm"] {
                let url = support.appendingPathComponent("rxmind.db\(suffix)")
                if fm.fileExists(atPath: url.path) {
                    try secureDeleteFile(at: url)
                }
            }
        }
        if let caches = fm.urls(for: .cachesDirectory, in: .userDomainMask).first {
            try? fm.removeItem(at: caches)
        }
        try deleteSecureEnclaveKey()
        UserDefaults.standard.removeObject(forKey: dekKey)
        UserDefaults.standard.removeObject(forKey: dekIvKey)
        UserDefaults.standard.removeObject(forKey: saltKey)
    }

    // MARK: - Key provisioning

    private static func ensureMasterKeyExists() throws {
        if try loadPrivateKeyIfExists() != nil { return }

        #if targetEnvironment(simulator)
        try ensureSimulatorFallbackKey()
        return
        #else
        let flags: SecAccessControlCreateFlags = [.privateKeyUsage]
        guard let access = SecAccessControlCreateWithFlags(
            kCFAllocatorDefault,
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            flags,
            nil
        ) else { throw CryptoError.accessControlFailed }

        let attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeySizeInBits as String: 256,
            kSecAttrTokenID as String: kSecAttrTokenIDSecureEnclave,
            kSecPrivateKeyAttrs as String: [
                kSecAttrIsPermanent as String: true,
                kSecAttrApplicationTag as String: masterKeyTag.data(using: .utf8)!,
                kSecAttrAccessControl as String: access
            ]
        ]

        var error: Unmanaged<CFError>?
        guard SecKeyCreateRandomKey(attributes as CFDictionary, &error) != nil else {
            throw error?.takeRetainedValue() ?? CryptoError.secureEnclaveUnavailable
        }
        #endif
    }

    #if targetEnvironment(simulator)
    private static func ensureSimulatorFallbackKey() throws {
        let flags: SecAccessControlCreateFlags = []
        guard let access = SecAccessControlCreateWithFlags(
            kCFAllocatorDefault,
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            flags,
            nil
        ) else { throw CryptoError.accessControlFailed }

        let attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeySizeInBits as String: 256,
            kSecPrivateKeyAttrs as String: [
                kSecAttrIsPermanent as String: true,
                kSecAttrApplicationTag as String: masterKeyTag.data(using: .utf8)!,
                kSecAttrAccessControl as String: access
            ]
        ]

        var error: Unmanaged<CFError>?
        guard SecKeyCreateRandomKey(attributes as CFDictionary, &error) != nil else {
            throw error?.takeRetainedValue() ?? CryptoError.secureEnclaveUnavailable
        }
    }
    #endif

    private static func ensureDekProvisioned() throws {
        if UserDefaults.standard.string(forKey: dekKey) != nil { return }

        var dek = Data(count: 32)
        _ = dek.withUnsafeMutableBytes { SecRandomCopyBytes(kSecRandomDefault, 32, $0.baseAddress!) }

        let iv = Data((0..<12).map { _ in UInt8.random(in: 0...255) })
        let privateKey = try loadPrivateKey()
        let encrypted = try encryptDek(privateKey: privateKey, dek: dek, iv: iv)

        UserDefaults.standard.set(encrypted.base64EncodedString(), forKey: dekKey)
        UserDefaults.standard.set(iv.base64EncodedString(), forKey: dekIvKey)
        dek.withUnsafeMutableBytes { ptr in
            if let base = ptr.baseAddress { memset(base, 0, ptr.count) }
        }
    }

    private static func ensureSaltProvisioned() throws {
        if UserDefaults.standard.string(forKey: saltKey) != nil { return }
        var salt = Data(count: 32)
        _ = salt.withUnsafeMutableBytes { SecRandomCopyBytes(kSecRandomDefault, 32, $0.baseAddress!) }
        UserDefaults.standard.set(salt.base64EncodedString(), forKey: saltKey)
    }

    private static func getSaltData() throws -> Data {
        try ensureSaltProvisioned()
        guard let b64 = UserDefaults.standard.string(forKey: saltKey),
              let salt = Data(base64Encoded: b64) else {
            throw CryptoError.derivationFailed
        }
        return salt
    }

    // MARK: - Secure Enclave crypto helpers

    private static func loadPrivateKeyIfExists() throws -> SecKey? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: masterKeyTag.data(using: .utf8)!,
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecReturnRef as String: true
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess else { throw CryptoError.keyNotFound }
        return (item as! SecKey)
    }

    private static func loadPrivateKey() throws -> SecKey {
        if let key = try loadPrivateKeyIfExists() { return key }
        throw CryptoError.keyNotFound
    }

    private static func encryptDek(privateKey: SecKey, dek: Data, iv: Data) throws -> Data {
        guard let publicKey = SecKeyCopyPublicKey(privateKey) else {
            throw CryptoError.derivationFailed
        }
        var error: Unmanaged<CFError>?
        guard let encrypted = SecKeyCreateEncryptedData(
            publicKey,
            .eciesEncryptionCofactorX963SHA256AESGCM,
            dek as CFData,
            &error
        ) else {
            throw error?.takeRetainedValue() ?? CryptoError.derivationFailed
        }
        return encrypted as Data
    }

    private static func decryptDek(privateKey: SecKey, encrypted: Data, iv: Data) throws -> Data {
        var mutableDek = Data(count: 32)
        var error: Unmanaged<CFError>?
        guard let decrypted = SecKeyCreateDecryptedData(
            privateKey,
            .eciesEncryptionCofactorX963SHA256AESGCM,
            encrypted as CFData,
            &error
        ) else {
            throw error?.takeRetainedValue() ?? CryptoError.derivationFailed
        }
        mutableDek = decrypted as Data
        return mutableDek
    }

    private static func deleteSecureEnclaveKey() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: masterKeyTag.data(using: .utf8)!,
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom
        ]
        SecItemDelete(query as CFDictionary)
    }

    // MARK: - PBKDF2 & secure delete

    private static func pbkdf2(password: Data, salt: Data, iterations: Int, keyLength: Int) throws -> Data {
        var derived = Data(count: keyLength)
        let result = derived.withUnsafeMutableBytes { derivedBytes in
            salt.withUnsafeBytes { saltBytes in
                password.withUnsafeBytes { passwordBytes in
                    CCKeyDerivationPBKDF(
                        CCPBKDFAlgorithm(kCCPBKDF2),
                        passwordBytes.baseAddress?.assumingMemoryBound(to: Int8.self),
                        password.count,
                        saltBytes.baseAddress?.assumingMemoryBound(to: UInt8.self),
                        salt.count,
                        CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                        UInt32(iterations),
                        derivedBytes.baseAddress?.assumingMemoryBound(to: UInt8.self),
                        keyLength
                    )
                }
            }
        }
        guard result == kCCSuccess else { throw CryptoError.derivationFailed }
        return derived
    }

    private static func secureDeleteFile(at url: URL) throws {
        let handle = try FileHandle(forWritingTo: url)
        defer { try? handle.close() }
        let size = try FileManager.default.attributesOfItem(atPath: url.path)[.size] as! Int
        try writePattern(handle: handle, size: size, byte: 0x00)
        try writePattern(handle: handle, size: size, byte: 0xFF)
        var random = Data(count: size)
        _ = random.withUnsafeMutableBytes { SecRandomCopyBytes(kSecRandomDefault, size, $0.baseAddress!) }
        try handle.seek(toOffset: 0)
        try handle.write(contentsOf: random)
        try FileManager.default.removeItem(at: url)
    }

    private static func writePattern(handle: FileHandle, size: Int, byte: UInt8) throws {
        let chunk = Data(repeating: byte, count: min(size, 65536))
        try handle.seek(toOffset: 0)
        var written = 0
        while written < size {
            let toWrite = min(chunk.count, size - written)
            try handle.write(contentsOf: chunk.prefix(toWrite))
            written += toWrite
        }
    }
}
