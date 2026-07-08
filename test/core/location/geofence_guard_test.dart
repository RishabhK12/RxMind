import 'package:flutter_test/flutter_test.dart';
import 'package:rxmind_app/core/location/facility_index.dart';
import 'package:rxmind_app/core/location/geofence_guard.dart';

import '../../test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const hospitalLat = 47.6062;
  const hospitalLon = -122.3321;

  double offsetFeet(double feet, {required bool north}) {
    final meters = GeofenceGuard.feetToMeters(feet);
    final deltaLat = meters / 111320.0;
    return north ? hospitalLat + deltaLat : hospitalLat - deltaLat;
  }

  setUp(() async {
    await setupRxMindTestDatabase();
    FacilityIndex.resetCache();
  });

  tearDown(() async {
    await tearDownRxMindTestDatabase();
    FacilityIndex.resetCache();
  });

  group('GeofenceGuard', () {
    test('haversine distance is consistent for known offset', () {
      final lat1500 = offsetFeet(1500, north: true);
      final distance = GeofenceGuard.haversineMeters(
        lat1500,
        hospitalLon,
        hospitalLat,
        hospitalLon,
      );
      expect(distance, closeTo(GeofenceGuard.feetToMeters(1500), 5.0));
    });

    test('evaluate is no-op when location features disabled', () async {
      await GeofenceGuard.setLocationFeaturesEnabled(false);
      final result = await GeofenceGuard.evaluate(hospitalLat, hospitalLon);
      expect(result.allowed, isTrue);
    });

    test('blocks within 1500 ft of test hospital when enabled', () async {
      await GeofenceGuard.setLocationFeaturesEnabled(true);
      final lat = offsetFeet(1500, north: true);
      final result = await GeofenceGuard.evaluate(lat, hospitalLon);
      expect(result.allowed, isFalse);
      expect(result.facilityId, 'us-hosp-test-001');
      await GeofenceGuard.setLocationFeaturesEnabled(false);
    });

    test('allows at 2500 ft from test hospital when enabled', () async {
      await GeofenceGuard.setLocationFeaturesEnabled(true);
      final lat = offsetFeet(2500, north: true);
      final result = await GeofenceGuard.evaluate(lat, hospitalLon);
      expect(result.allowed, isTrue);
      await GeofenceGuard.setLocationFeaturesEnabled(false);
    });
  });
}
