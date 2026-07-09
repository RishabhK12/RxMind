import 'dart:typed_data';

class KeyDerivationMetadata {
  const KeyDerivationMetadata({
    required this.salt,
    required this.iterations,
    required this.schemaVersion,
  });

  final Uint8List salt;
  final int iterations;
  final String schemaVersion;

  static const int minIterations = 100000;
  static const String currentSchemaVersion = 'v1';
}
