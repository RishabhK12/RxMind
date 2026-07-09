import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rxmind_app/core/notifications/neutral_notification_copy.dart';

void main() {
  test('neutral copy constants exclude clinical strings', () {
    expect(NeutralNotificationCopy.title, 'Recovery reminder');
    expect(
        NeutralNotificationCopy.body, 'You have a scheduled wellness entry');
    expect(NeutralNotificationCopy.title, isNot(contains('Task')));
    expect(NeutralNotificationCopy.body, isNot(contains('mg')));
  });

  test('notification_service uses neutral copy not taskTitle in schedule path',
      () {
    final source = File('lib/services/notification_service.dart').readAsStringSync();
    expect(source, contains('NeutralNotificationCopy.title'));
    expect(source, contains('NeutralNotificationCopy.body'));
    expect(source, isNot(contains(r"'$taskTitle is due")));
    expect(source, isNot(contains("'Task Reminder'")));
  });
}
