import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:take_home/core/network/connectivity_service.dart';
import 'package:take_home/core/sync/sync_cubit.dart';
import 'package:take_home/core/sync/sync_queue.dart';

class MockConnectivityService extends Mock implements ConnectivityService {}

class MockSyncQueue extends Mock implements SyncQueue {}

SyncQueueEntry _entry(int id) => SyncQueueEntry(
  id: id,
  tableName: 'notes',
  operation: 'create',
  payload: const {},
  createdAt: DateTime(2026, 1, 1),
);

void main() {
  late MockConnectivityService connectivity;
  late MockSyncQueue queue;
  late StreamController<bool> onlineController;
  late StreamController<void> queueChangedController;

  setUp(() {
    connectivity = MockConnectivityService();
    queue = MockSyncQueue();
    onlineController = StreamController<bool>.broadcast();
    queueChangedController = StreamController<void>.broadcast();

    when(
      () => connectivity.onlineStream,
    ).thenAnswer((_) => onlineController.stream);
    when(
      () => queue.onChanged,
    ).thenAnswer((_) => queueChangedController.stream);
  });

  tearDown(() async {
    await onlineController.close();
    await queueChangedController.close();
  });

  test(
    'drains queued entries one at a time, in order, while online, until the queue is empty',
    () async {
      final entries = [_entry(1), _entry(2)];
      when(() => connectivity.isOnline).thenReturn(true);
      when(() => queue.getAll()).thenAnswer((_) async => List.of(entries));
      when(() => queue.count()).thenAnswer((_) async => entries.length);
      when(() => queue.remove(any())).thenAnswer((invocation) async {
        final id = invocation.positionalArguments.first as int;
        entries.removeWhere((e) => e.id == id);
      });

      final cubit = SyncCubit(connectivity, queue);
      await cubit.init();

      // Two entries, ~500ms simulated delay each inside SyncCubit.
      await Future<void>.delayed(const Duration(milliseconds: 1200));

      expect(cubit.state.pendingCount, 0);
      expect(cubit.state.isSyncing, isFalse);
      expect(cubit.state.justSyncedAt, isNotNull);

      final removeCalls = verify(() => queue.remove(captureAny())).captured;
      expect(removeCalls, [1, 2]);

      await cubit.close();
    },
  );

  test(
    'stops draining as soon as connectivity drops mid-drain, leaving the rest queued',
    () async {
      final entries = [_entry(1), _entry(2)];
      when(() => connectivity.isOnline).thenReturn(true);
      when(() => queue.getAll()).thenAnswer((_) async => List.of(entries));
      when(() => queue.count()).thenAnswer((_) async => entries.length);
      when(() => queue.remove(any())).thenAnswer((invocation) async {
        final id = invocation.positionalArguments.first as int;
        entries.removeWhere((e) => e.id == id);
      });

      final cubit = SyncCubit(connectivity, queue);
      await cubit.init();

      // Drop offline partway through the first item's simulated delay.
      Timer(
        const Duration(milliseconds: 100),
        () => onlineController.add(false),
      );

      await Future<void>.delayed(const Duration(milliseconds: 700));

      expect(cubit.state.isOnline, isFalse);
      expect(cubit.state.pendingCount, 2);
      verifyNever(() => queue.remove(any()));

      await cubit.close();
    },
  );
}
