import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class PickedContact {
  const PickedContact({required this.name, required this.phone});

  final String name;
  final String phone;

  factory PickedContact.fromMap(Map<dynamic, dynamic> map) {
    return PickedContact(
      name: map['name'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
    );
  }
}

class NativeContactPickerService {
  NativeContactPickerService({
    MethodChannel? channel,
    bool assumeSupported = false,
  })  : _channel = channel ?? const MethodChannel('rxmind/contacts'),
        _assumeSupported = assumeSupported;

  final MethodChannel _channel;
  final bool _assumeSupported;

  bool get isSupported =>
      _assumeSupported || (!kIsWeb && (Platform.isAndroid || Platform.isIOS));

  Future<PickedContact?> pickSingleContact() async {
    if (!isSupported) return null;
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>?>(
        'pickSingleContact',
      );
      if (result == null) return null;
      final contact = PickedContact.fromMap(result);
      if (contact.name.isEmpty && contact.phone.isEmpty) return null;
      return contact;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        debugPrint('NativeContactPickerService: ${e.message}');
      }
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}
