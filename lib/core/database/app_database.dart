import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../constants/db_constants.dart';

class AppDatabase {
  static const String _dbName = 'smart_workspace.db';
  static const int _dbVersion = 1;

  Database? _database;

  Future<Database> get database async {
    final existing = _database;
    if (existing != null) return existing;
    final opened = await _open();
    _database = opened;
    return opened;
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ${DbTables.notes} (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        is_archived INTEGER NOT NULL DEFAULT 0,
        reminder_date TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE ${DbTables.checklistItems} (
        id TEXT PRIMARY KEY,
        note_id TEXT NOT NULL,
        label TEXT NOT NULL,
        is_checked INTEGER NOT NULL DEFAULT 0,
        sort_order INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (note_id) REFERENCES ${DbTables.notes} (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE ${DbTables.noteImages} (
        id TEXT PRIMARY KEY,
        note_id TEXT NOT NULL,
        file_path TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (note_id) REFERENCES ${DbTables.notes} (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE ${DbTables.dashboardCards} (
        id TEXT PRIMARY KEY,
        sort_order INTEGER NOT NULL DEFAULT 0,
        is_visible INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE ${DbTables.syncQueue} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        table_name TEXT NOT NULL,
        operation TEXT NOT NULL,
        payload TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE ${DbTables.searchItems} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        subtitle TEXT NOT NULL DEFAULT '',
        category TEXT NOT NULL DEFAULT ''
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_checklist_items_note_id ON ${DbTables.checklistItems} (note_id)',
    );
    await db.execute(
      'CREATE INDEX idx_note_images_note_id ON ${DbTables.noteImages} (note_id)',
    );
    await db.execute(
      'CREATE INDEX idx_search_items_title ON ${DbTables.searchItems} (title)',
    );
  }

  Future<void> close() async {
    final db = _database;
    if (db == null) return;
    await db.close();
    _database = null;
  }
}
