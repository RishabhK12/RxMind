/// Volatile RAM queue for writes deferred while the device is locked.
class PendingWrite {
  PendingWrite({
    required this.operation,
    required this.payload,
    DateTime? enqueuedAt,
  }) : enqueuedAt = enqueuedAt ?? DateTime.now();

  final String operation;
  final Map<String, dynamic> payload;
  final DateTime enqueuedAt;
}

class LockSafeWriteBuffer {
  LockSafeWriteBuffer._();

  static final LockSafeWriteBuffer instance = LockSafeWriteBuffer._();

  static const maxEntries = 256;

  final List<PendingWrite> _queue = [];

  bool get hasPending => _queue.isNotEmpty;

  int get length => _queue.length;

  void enqueue(PendingWrite write) {
    if (_queue.length >= maxEntries) {
      _queue.removeAt(0);
    }
    _queue.add(write);
  }

  Future<void> flush(Future<void> Function(PendingWrite) applier) async {
    final snapshot = List<PendingWrite>.from(_queue);
    _queue.clear();
    for (final write in snapshot) {
      await applier(write);
    }
  }

  void clear() => _queue.clear();
}
