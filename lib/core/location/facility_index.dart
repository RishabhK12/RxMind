import 'dart:convert';

import 'package:flutter/services.dart';

class ClinicalFacility {
  const ClinicalFacility({
    required this.id,
    required this.name,
    required this.lat,
    required this.lon,
    required this.type,
  });

  final String id;
  final String name;
  final double lat;
  final double lon;
  final String type;

  factory ClinicalFacility.fromGeoJson(Map<String, dynamic> feature) {
    final props = feature['properties'] as Map<String, dynamic>;
    final coords = (feature['geometry'] as Map<String, dynamic>)['coordinates']
        as List<dynamic>;
    return ClinicalFacility(
      id: props['id'] as String,
      name: props['name'] as String? ?? 'Facility',
      lon: (coords[0] as num).toDouble(),
      lat: (coords[1] as num).toDouble(),
      type: props['type'] as String? ?? 'hospital',
    );
  }
}

class FacilityIndex {
  FacilityIndex._();

  static List<ClinicalFacility>? _cache;

  static Future<List<ClinicalFacility>> load() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle
        .loadString('assets/data/clinical_facilities_us.geojson');
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final features = decoded['features'] as List<dynamic>;
    _cache = features
        .map((f) => ClinicalFacility.fromGeoJson(f as Map<String, dynamic>))
        .toList(growable: false);
    return _cache!;
  }

  /// Clears cached index (for tests).
  static void resetCache() => _cache = null;
}
