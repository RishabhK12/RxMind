import 'dart:typed_data';

/// Volatile RAM buffer for OCR frames; zeroized on dispose.
class SecureBytes {
  SecureBytes(this._data);

  Uint8List _data;
  bool _disposed = false;

  Uint8List get data {
    if (_disposed) throw StateError('SecureBytes already disposed');
    return _data;
  }

  int get length => _data.length;

  void dispose() {
    if (_disposed) return;
    for (var i = 0; i < _data.length; i++) {
      _data[i] = 0;
    }
    _disposed = true;
  }
}
