import 'package:flutter_test/flutter_test.dart';
import 'package:rxmind_app/core/ai/rate_limiter.dart';
import '../../test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await setupRxMindTestDatabase();
  });

  tearDown(() async {
    await tearDownRxMindTestDatabase();
  });

  group('RateLimiter', () {
    test('canMakeRequest returns true initially', () async {
      expect(await RateLimiter.canMakeRequest(), isTrue);
    });

    test('getRemainingRequests returns max after reset window', () async {
      expect(await RateLimiter.getRemainingRequests(), 20);
    });
  });
}
