import 'dart:async';
import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../constants/db_constants.dart';
import '../database/app_database.dart';

class SyncQueueEntry {
  const SyncQueueEntry({
    required this.id,
    required this.tableName,
    required this.operation,
    required this.payload,
    required this.createdAt,
  });

  final int id;
  final String tableName;
  final String operation;
  final Map<String, Object?> payload;
  final DateTime createdAt;

  factory SyncQueueEntry.fromMap(Map<String, Object?> map) {
    return SyncQueueEntry(
      id: map['id']! as int,
      tableName: map['table_name']! as String,
      operation: map['operation']! as String,
      payload: jsonDecode(map['payload']! as String) as Map<String, Object?>,
      createdAt: DateTime.parse(map['created_at']! as String),
    );
  }
}

/// The offline write queue: every mutating repository write is appended
/// here (in addition to writing straight to its own table) to be "replayed"
/// against a server once one exists. There's no real backend for this
/// assignment, so replaying just means: wait a moment, then drop the row.
class SyncQueue {
  SyncQueue(this._appDatabase);

  final AppDatabase _appDatabase;
  final StreamController<void> _changes = StreamController<void>.broadcast();

  /// Fires whenever an entry is added or removed, so listeners can re-read
  /// the count/contents without polling.
  Stream<void> get onChanged => _changes.stream;

  Future<void> enqueue({
    required String tableName,
    required String operation,
    Map<String, Object?> payload = const {},
  }) async {
    final db = await _appDatabase.database;
    await db.insert(DbTables.syncQueue, {
      'table_name': tableName,
      'operation': operation,
      'payload': jsonEncode(payload),
      'created_at': DateTime.now().toIso8601String(),
    });
    _changes.add(null);
  }

  Future<List<SyncQueueEntry>> getAll() async {
    final db = await _appDatabase.database;
    final rows = await db.query(DbTables.syncQueue, orderBy: 'created_at ASC');
    return rows.map(SyncQueueEntry.fromMap).toList();
  }

  Future<void> remove(int id) async {
    final db = await _appDatabase.database;
    await db.delete(DbTables.syncQueue, where: 'id = ?', whereArgs: [id]);
    _changes.add(null);
  }

  Future<int> count() async {
    final db = await _appDatabase.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS count FROM ${DbTables.syncQueue}',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
