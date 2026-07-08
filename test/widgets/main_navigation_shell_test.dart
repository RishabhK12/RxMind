import 'package:flutter_test/flutter_test.dart';
import 'package:rxmind_app/screens/home/main_navigation_shell.dart';

void main() {
  test('nav bar height meets accessibility minimum', () {
    expect(MainNavigationShell.navBarHeight, greaterThanOrEqualTo(56));
  });
}
