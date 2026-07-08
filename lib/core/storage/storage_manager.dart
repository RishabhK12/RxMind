import 'dart:convert';

import 'local_storage.dart';
import 'models/user_profile.dart';
import 'secure_wipe_service.dart';

class StorageManager {
  static Future<void> storeUserProfile(UserProfile profile) async {
    await LocalStorage.writeSecure(
      'user_profile',
      jsonEncode(profile.toJson()),
    );
  }

  static Future<UserProfile?> getUserProfile() async {
    final jsonStr = await LocalStorage.readSecure('user_profile');
    if (jsonStr == null) return null;
    return UserProfile.fromJson(
      jsonDecode(jsonStr) as Map<String, dynamic>,
    );
  }

  static Future<void> resetApp() async {
    await SecureWipeService.wipeAll();
  }
}
