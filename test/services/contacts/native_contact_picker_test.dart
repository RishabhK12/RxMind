import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rxmind_app/services/contacts/native_contact_picker_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('rxmind/contacts');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('pickSingleContact returns PickedContact from platform', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'pickSingleContact') {
        return {'name': 'Dr. Smith', 'phone': '+1-555-0100'};
      }
      return null;
    });

    final service = NativeContactPickerService(
      channel: channel,
      assumeSupported: true,
    );
    final contact = await service.pickSingleContact();
    expect(contact?.name, 'Dr. Smith');
    expect(contact?.phone, '+1-555-0100');
  });

  test('pickSingleContact returns null on cancel', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => null);

    final service = NativeContactPickerService(
      channel: channel,
      assumeSupported: true,
    );
    expect(await service.pickSingleContact(), isNull);
  });
}
