import '../chd/repositories/app_metadata_repository.dart';
import '../storage/sqlcipher_database.dart';

/// Persists per-permission disclosure acknowledgments (non-CHD UI flags).
class PermissionDisclosureStore {
  PermissionDisclosureStore._();

  static String _key(String permission) => 'perm_disclosure_${permission}_v1';

  static Future<bool> isAcknowledged(String permission) async {
    try {
      final db = await SecureDatabase.instance();
      final meta = AppMetadataRepository(db);
      return await meta.get(_key(permission)) == 'true';
    } catch (_) {
      return false;
    }
  }

  static Future<void> setAcknowledged(String permission) async {
    final db = await SecureDatabase.instance();
    final meta = AppMetadataRepository(db);
    await meta.set(_key(permission), 'true');
  }
}
