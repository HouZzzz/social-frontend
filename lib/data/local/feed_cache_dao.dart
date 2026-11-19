import 'package:sqflite/sqflite.dart';

import '../../models/post.dart';
import 'app_database.dart';

class FeedCacheDao {
  FeedCacheDao(this._database);

  final AppDatabase _database;

  Future<void> insertAll(List<Post> posts) async {
    final db = await _database.open();
    await db.transaction((txn) async {
      for (var i = 0; i < posts.length; i++) {
        await txn.insert(
          AppDatabase.tableFeed,
          posts[i].toDbRow(position: i),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await _writeMeta(txn);
    });
  }

  Future<List<Post>> queryAll() async {
    final db = await _database.open();
    final rows = await db.query(
      AppDatabase.tableFeed,
      orderBy: 'position ASC',
    );
    return rows.map(Post.fromDbRow).toList();
  }

  Future<void> replaceAll(List<Post> posts) async {
    final db = await _database.open();
    await db.transaction((txn) async {
      await txn.delete(AppDatabase.tableFeed);
      for (var i = 0; i < posts.length; i++) {
        await txn.insert(
          AppDatabase.tableFeed,
          posts[i].toDbRow(position: i),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await _writeMeta(txn);
    });
  }

  Future<void> clearAll() async {
    final db = await _database.open();
    await db.transaction((txn) async {
      await txn.delete(AppDatabase.tableFeed);
      await txn.delete(AppDatabase.tableMeta);
    });
  }

  Future<DateTime?> lastUpdatedAt() async {
    final db = await _database.open();
    final rows = await db.query(
      AppDatabase.tableMeta,
      where: 'id = 1',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return DateTime.tryParse((rows.first['updated_at'] as String?) ?? '');
  }

  Future<void> _writeMeta(Transaction txn) async {
    await txn.insert(
      AppDatabase.tableMeta,
      {'id': 1, 'updated_at': DateTime.now().toUtc().toIso8601String()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
