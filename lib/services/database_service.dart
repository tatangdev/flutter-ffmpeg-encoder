import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  static const _dbName = 'devcoder.db';
  static const _dbVersion = 4;
  static const _jobsTable = 'compression_jobs';
  static const _draftsTable = 'drafts';

  Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_jobsTable (
        id                          TEXT PRIMARY KEY,
        input_path                  TEXT NOT NULL,
        output_dir                  TEXT NOT NULL,
        file_name                   TEXT NOT NULL,
        created_at                  INTEGER NOT NULL,
        status                      TEXT NOT NULL,
        progress                    REAL NOT NULL DEFAULT 0.0,
        thumbnail_path              TEXT,

        settings_export_mode        TEXT NOT NULL,
        settings_platform           TEXT NOT NULL,
        settings_custom_resolution  TEXT NOT NULL,
        settings_tier               TEXT NOT NULL,
        settings_aspect_ratio       TEXT NOT NULL,
        settings_fit                TEXT NOT NULL,
        settings_rotation           TEXT NOT NULL DEFAULT 'none',
        settings_delete_original    INTEGER NOT NULL DEFAULT 0,

        result_success              INTEGER,
        result_output_path          TEXT,
        result_original_size_bytes  INTEGER,
        result_compressed_size_bytes INTEGER,
        result_compression_duration_ms INTEGER,
        result_error_message        TEXT,
        result_ffmpeg_return_code   INTEGER,
        result_original_deleted     INTEGER DEFAULT 0
      )
    ''');
    await _createJobIndices(db);
    await _createDraftsTable(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createDraftsTable(db);
    }
    if (oldVersion < 3) {
      await _createJobIndices(db);
    }
    if (oldVersion < 4) {
      await db.execute(
        "ALTER TABLE $_jobsTable ADD COLUMN settings_rotation TEXT NOT NULL DEFAULT 'none'",
      );
      await db.execute(
        "ALTER TABLE $_draftsTable ADD COLUMN settings_rotation TEXT NOT NULL DEFAULT 'none'",
      );
    }
  }

  Future<void> _createJobIndices(Database db) async {
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_jobs_status ON $_jobsTable(status)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_jobs_created_at ON $_jobsTable(created_at DESC)',
    );
  }

  Future<void> _createDraftsTable(Database db) async {
    await db.execute('''
      CREATE TABLE $_draftsTable (
        id                          TEXT PRIMARY KEY,
        video_path                  TEXT NOT NULL,
        file_name                   TEXT NOT NULL,
        size_bytes                  INTEGER NOT NULL,
        duration_ms                 INTEGER,
        width                       INTEGER,
        height                      INTEGER,
        video_codec                 TEXT,
        bitrate                     REAL,
        format                      TEXT,
        thumbnail_path              TEXT,
        output_dir                  TEXT,

        settings_export_mode        TEXT NOT NULL,
        settings_platform           TEXT NOT NULL,
        settings_custom_resolution  TEXT NOT NULL,
        settings_tier               TEXT NOT NULL,
        settings_aspect_ratio       TEXT NOT NULL,
        settings_fit                TEXT NOT NULL,
        settings_rotation           TEXT NOT NULL DEFAULT 'none',
        settings_delete_original    INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  // --- Jobs ---

  Future<void> insertJob(Map<String, dynamic> jobMap) async {
    final db = await database;
    await db.insert(_jobsTable, jobMap, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateJob(Map<String, dynamic> jobMap) async {
    final db = await database;
    await db.update(
      _jobsTable,
      jobMap,
      where: 'id = ?',
      whereArgs: [jobMap['id']],
    );
  }

  Future<void> deleteJob(String id) async {
    final db = await database;
    await db.delete(_jobsTable, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getAllJobs() async {
    final db = await database;
    return db.query(_jobsTable, orderBy: 'created_at DESC', limit: 50);
  }

  Future<void> markInterruptedJobsAsFailed() async {
    final db = await database;
    await db.update(
      _jobsTable,
      {
        'status': 'failed',
        'result_success': 0,
        'result_error_message': 'App was closed during compression',
      },
      where: 'status IN (?, ?)',
      whereArgs: ['compressing', 'pending'],
    );
  }

  // --- Drafts ---

  Future<void> saveDraft(Map<String, dynamic> draftMap) async {
    final db = await database;
    await db.insert(_draftsTable, draftMap, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> loadDraft() async {
    final db = await database;
    final rows = await db.query(_draftsTable, where: 'id = ?', whereArgs: ['current']);
    return rows.isEmpty ? null : rows.first;
  }

  Future<void> deleteDraft() async {
    final db = await database;
    await db.delete(_draftsTable);
  }

  // --- Lifecycle ---

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
