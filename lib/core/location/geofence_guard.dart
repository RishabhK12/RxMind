import 'dart:convert';
import 'dart:math' as math;

import 'package:crypto/crypto.dart';

import '../chd/repositories/app_metadata_repository.dart';
import '../storage/sqlcipher_database.dart';
import 'facility_index.dart';

const _enableLocationKey = 'enable_location_features';

class GeofenceResult {
  const GeofenceResult._({
    required this.allowed,
    this.facilityId,
    this.distanceMeters,
  });

  final bool allowed;
  final String? facilityId;
  final double? distanceMeters;

  factory GeofenceResult.allowed() => const GeofenceResult._(allowed: true);

  factory GeofenceResult.blocked({
    required String facilityId,
    required double distanceMeters,
  }) =>
      GeofenceResult._(
        allowed: false,
        facilityId: facilityId,
        distanceMeters: distanceMeters,
      );
}

class GeofenceGuard {
  GeofenceGuard._();

  static const exclusionRadiusMeters = 609.6; // 2,000 feet

  static Future<bool> isLocationFeaturesEnabled() async {
    try {
      final db = await SecureDatabase.instance();
      final meta = AppMetadataRepository(db);
      return await meta.get(_enableLocationKey) == 'true';
    } catch (_) {
      return false;
    }
  }

  static Future<void> setLocationFeaturesEnabled(bool enabled) async {
    final db = await SecureDatabase.instance();
    final meta = AppMetadataRepository(db);
    await meta.set(_enableLocationKey, enabled ? 'true' : 'false');
  }

  static Future<GeofenceResult> evaluate(double lat, double lon) async {
    if (!await isLocationFeaturesEnabled()) {
      return GeofenceResult.allowed();
    }

    final facilities = await FacilityIndex.load();
    for (final facility in facilities) {
      final distance = haversineMeters(lat, lon, facility.lat, facility.lon);
      if (distance < exclusionRadiusMeters) {
        await _logBlockedEvent(facility.id);
        return GeofenceResult.blocked(
          facilityId: facility.id,
          distanceMeters: distance,
        );
      }
    }
    return GeofenceResult.allowed();
  }

  static Future<void> _logBlockedEvent(String facilityId) async {
    try {
      final db = await SecureDatabase.instance();
      final meta = AppMetadataRepository(db);
      final hash = sha256.convert(utf8.encode(facilityId)).toString();
      final key =
          'geofence_blocked_${DateTime.now().toUtc().millisecondsSinceEpoch}';
      await meta.set(
          key,
          jsonEncode({
            'facility_id_hash': hash.substring(0, 16),
            'ts': DateTime.now().toUtc().toIso8601String(),
          }));
    } catch (_) {
      // Logging is best-effort.
    }
  }

  static double haversineMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const r = 6371000.0;
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRad(lat1)) *
            math.cos(_toRad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  static double _toRad(double deg) => deg * math.pi / 180.0;

  /// Feet to meters conversion for tests.
  static double feetToMeters(double feet) => feet * 0.3048;
}
