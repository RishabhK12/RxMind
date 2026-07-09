import '../chd/repositories/app_metadata_repository.dart';
import '../storage/sqlcipher_database.dart';

class RateLimiter {
  static const String _requestCountKey = 'request_count';
  static const String _lastResetKey = 'last_reset';
  static const int _maxRequestsPerHour = 20;
  static const Duration _resetInterval = Duration(hours: 1);

  static Future<AppMetadataRepository> _meta() async {
    final db = await SecureDatabase.instance();
    return AppMetadataRepository(db);
  }

  static Future<bool> canMakeRequest() async {
    final meta = await _meta();
    final now = DateTime.now();
    final lastResetMs = int.tryParse(await meta.get(_lastResetKey) ?? '0') ?? 0;
    final lastReset = DateTime.fromMillisecondsSinceEpoch(lastResetMs);

    if (now.difference(lastReset) >= _resetInterval) {
      await meta.set(_requestCountKey, '0');
      await meta.set(_lastResetKey, now.millisecondsSinceEpoch.toString());
      await meta.set(_requestCountKey, '1');
      return true;
    }

    final currentCount =
        int.tryParse(await meta.get(_requestCountKey) ?? '0') ?? 0;
    if (currentCount >= _maxRequestsPerHour) {
      return false;
    }

    await meta.set(_requestCountKey, (currentCount + 1).toString());
    return true;
  }

  static Future<int> getRemainingRequests() async {
    final meta = await _meta();
    final now = DateTime.now();
    final lastResetMs = int.tryParse(await meta.get(_lastResetKey) ?? '0') ?? 0;
    final lastReset = DateTime.fromMillisecondsSinceEpoch(lastResetMs);

    if (now.difference(lastReset) >= _resetInterval) {
      return _maxRequestsPerHour;
    }

    final currentCount =
        int.tryParse(await meta.get(_requestCountKey) ?? '0') ?? 0;
    return _maxRequestsPerHour - currentCount;
  }
}
