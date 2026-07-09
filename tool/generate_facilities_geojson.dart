import 'dart:convert';
import 'dart:io';
import 'dart:math';

void main() {
  final random = Random(42);
  final features = <Map<String, dynamic>>[];

  // Reference hospital for geofence tests (Seattle area).
  features.add({
    'type': 'Feature',
    'properties': {
      'id': 'us-hosp-test-001',
      'name': 'RxMind Test Medical Center',
      'type': 'hospital',
    },
    'geometry': {
      'type': 'Point',
      'coordinates': [-122.3321, 47.6062],
    },
  });

  for (var i = 1; i <= 519; i++) {
    final lat = 24.0 + random.nextDouble() * 26.0;
    final lon = -125.0 + random.nextDouble() * 58.0;
    features.add({
      'type': 'Feature',
      'properties': {
        'id': 'us-hosp-${i.toString().padLeft(5, '0')}',
        'name': 'Synthetic Hospital $i',
        'type': 'hospital',
      },
      'geometry': {
        'type': 'Point',
        'coordinates': [
          double.parse(lon.toStringAsFixed(6)),
          double.parse(lat.toStringAsFixed(6))
        ],
      },
    });
  }

  final geojson = {'type': 'FeatureCollection', 'features': features};
  final out = File('assets/data/clinical_facilities_us.geojson');
  out.parent.createSync(recursive: true);
  out.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(geojson));
  stdout.writeln('Wrote ${features.length} facilities to ${out.path}');
}
