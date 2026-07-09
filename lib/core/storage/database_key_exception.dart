/// Thrown when the hardware-backed master key cannot derive a database passphrase.
class DatabaseKeyException implements Exception {
  DatabaseKeyException(this.message);
  final String message;

  @override
  String toString() => 'DatabaseKeyException: $message';
}

/// Thrown when iOS Secure Enclave is unavailable (e.g. simulator).
class SecureEnclaveUnavailableException implements Exception {
  SecureEnclaveUnavailableException(this.message);
  final String message;

  @override
  String toString() => 'SecureEnclaveUnavailableException: $message';
}
