import 'package:flutter_test/flutter_test.dart';

import 'package:take_home/core/utils/debouncer.dart';

void main() {
  test(
    'run() coalesces rapid calls into a single invocation of the latest action, '
    'after the delay elapses',
    () async {
      final debouncer = Debouncer(delay: const Duration(milliseconds: 50));
      final calls = <int>[];

      debouncer.run(() => calls.add(1));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      debouncer.run(() => calls.add(2));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      debouncer.run(() => calls.add(3));

      // Still inside the debounce window from the last run() call.
      expect(calls, isEmpty);

      await Future<void>.delayed(const Duration(milliseconds: 80));

      expect(calls, [3]);

      debouncer.dispose();
    },
  );

  test('dispose() cancels a pending call so it never fires', () async {
    final debouncer = Debouncer(delay: const Duration(milliseconds: 50));
    var fired = false;

    debouncer.run(() => fired = true);
    debouncer.dispose();

    await Future<void>.delayed(const Duration(milliseconds: 80));
    expect(fired, isFalse);
  });
}
