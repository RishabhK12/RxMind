import 'package:shared_preferences/shared_preferences.dart';

class RateLimiter {
  static const String _requestCountKey = 'request_count';
  static const String _lastResetKey = 'last_reset';
  static const int _maxRequestsPerHour = 20;
  static const Duration _resetInterval = Duration(hours: 1);

  static Future<bool> canMakeRequest() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final lastReset =
        DateTime.fromMillisecondsSinceEpoch(prefs.getInt(_lastResetKey) ?? 0);

    // Reset count if more than an hour has passed
    if (now.difference(lastReset) >= _resetInterval) {
      await prefs.setInt(_requestCountKey, 0);
      await prefs.setInt(_lastResetKey, now.millisecondsSinceEpoch);
      return true;
    }

    final currentCount = prefs.getInt(_requestCountKey) ?? 0;
    if (currentCount >= _maxRequestsPerHour) {
      return false;
    }

    await prefs.setInt(_requestCountKey, currentCount + 1);
    return true;
  }

  static Future<int> getRemainingRequests() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final lastReset =
        DateTime.fromMillisecondsSinceEpoch(prefs.getInt(_lastResetKey) ?? 0);

    if (now.difference(lastReset) >= _resetInterval) {
      return _maxRequestsPerHour;
    }

    final currentCount = prefs.getInt(_requestCountKey) ?? 0;
    return _maxRequestsPerHour - currentCount;
  }
}
