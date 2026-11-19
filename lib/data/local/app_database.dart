import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase({
    DatabaseFactory? dbFactory,
    String? path,
    bool singleInstance = true,
  })  : _factory = dbFactory ?? databaseFactory,
        _customPath = path,
        _singleInstance = singleInstance;

  static const String fileName = 'houzz_social.db';
  static const int schemaVersion = 1;

  static const String tableFeed = 'cached_feed';
  static const String tableMeta = 'cached_feed_meta';

  final DatabaseFactory _factory;
  final String? _customPath;
  final bool _singleInstance;
  Database? _database;

  // lazy open
  Future<Database> open() async {
    final existing = _database;
    if (existing != null) return existing;

    final dbPath = _customPath ?? p.join(await _factory.getDatabasesPath(), fileName);

    final db = await _factory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: schemaVersion,
        singleInstance: _singleInstance,
        onCreate: _onCreate,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      ),
    );

    _database = db;
    return db;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableFeed (
        id              INTEGER PRIMARY KEY,
        content         TEXT    NOT NULL,
        author_username TEXT    NOT NULL,
        created_at      TEXT    NOT NULL,
        likes_count     INTEGER NOT NULL DEFAULT 0,
        comments_count  INTEGER NOT NULL DEFAULT 0,
        is_liked        INTEGER NOT NULL DEFAULT 0,
        image_url       TEXT,
        position        INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // last update
    await db.execute('''
      CREATE TABLE $tableMeta (
        id          INTEGER PRIMARY KEY CHECK (id = 1),
        updated_at  TEXT NOT NULL
      )
    ''');

    await db.execute(
      'CREATE INDEX ix_feed_position ON $tableFeed (position)',
    );
  }
}
