import 'package:flutter_test/flutter_test.dart';
import 'package:rxmind_app/core/storage/lock_safe_write_buffer.dart';

void main() {
  group('LockSafeWriteBuffer', () {
    tearDown(() => LockSafeWriteBuffer.instance.clear());

    test('enqueue and flush replays all pending writes', () async {
      final buffer = LockSafeWriteBuffer.instance;
      buffer.enqueue(
        PendingWrite(operation: 'reschedule_task', payload: {'taskId': 'a'}),
      );
      buffer.enqueue(
        PendingWrite(operation: 'reschedule_task', payload: {'taskId': 'b'}),
      );

      final applied = <String>[];
      await buffer.flush((write) async {
        applied.add(write.payload['taskId'] as String);
      });

      expect(applied, ['a', 'b']);
      expect(buffer.hasPending, isFalse);
    });

    test('enqueue drops oldest when exceeding maxEntries', () {
      final buffer = LockSafeWriteBuffer.instance;
      for (var i = 0; i < LockSafeWriteBuffer.maxEntries + 1; i++) {
        buffer.enqueue(
          PendingWrite(operation: 'op', payload: {'i': i}),
        );
      }
      expect(buffer.length, LockSafeWriteBuffer.maxEntries);
    });

    test('clear empties queue', () {
      final buffer = LockSafeWriteBuffer.instance;
      buffer.enqueue(PendingWrite(operation: 'op', payload: {}));
      buffer.clear();
      expect(buffer.hasPending, isFalse);
    });
  });
}
