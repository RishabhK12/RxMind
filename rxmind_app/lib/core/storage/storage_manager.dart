import 'local_storage.dart';
import 'models/user_profile.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class StorageManager {
  static Future<void> storeUserProfile(UserProfile profile) async {
    await LocalStorage.writeSecure('user_profile', profile.toJson().toString());
  }

  static Future<UserProfile?> getUserProfile() async {
    final jsonStr = await LocalStorage.readSecure('user_profile');
    if (jsonStr == null) return null;
    return UserProfile.fromJson(jsonStr as Map<String, dynamic>);
  }

  static Future<void> resetApp() async {
    // Wipe all secure storage
    await LocalStorage.secureStorage.deleteAll();
    // Wipe DB
    if (LocalStorage.db != null) {
      await LocalStorage.db!.close();
      await LocalStorage.initDb();
    }
    // Cancel notifications
    final notifications = FlutterLocalNotificationsPlugin();
    await notifications.cancelAll();
    // TODO: Redirect to onboarding info flow (handled in UI)
  }
}
