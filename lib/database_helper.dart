import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'level_screen.dart';

class DatabaseHelper {
  static final _databaseName = "game.db";  // The name of the database
  static final _databaseVersion = 1;       // Database version

  // Tables and columns
  static final tableUser = 'user_table';
  static final tableLevelStatus = 'levelStatus';

  static final columnId = '_id';
  static final columnNickname = 'nickname';
  static final columnAvatar = 'avatar';
  static final columnLevel = 'level';
  static final columnIsUnlocked = 'isUnlocked';

  // Singleton pattern
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Initialize database
  _initDatabase() async {
    var databasesPath = await getDatabasesPath();
    String path = join(databasesPath, _databaseName);
    return await openDatabase(path, version: _databaseVersion, onCreate: _onCreate);
  }

  // Create tables
  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableUser (
        $columnId INTEGER PRIMARY KEY,
        $columnNickname TEXT NOT NULL,
        $columnAvatar TEXT NOT NULL,
        $columnLevel INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableLevelStatus (
        level INTEGER PRIMARY KEY,
        isUnlocked INTEGER NOT NULL,
         stars INTEGER DEFAULT 0
      )
    ''');
  }

  Future<int> updateUser(Map<String, dynamic> values) async {
    final db = await database;
    return await db.update(
      tableUser,
      values,
      where: '$columnId = ?',
      whereArgs: [1], // Assuming the user has ID 1; modify as needed
    );
  }

  // Insert user data into the user table
  Future<int> insertUser(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.insert(tableUser, row);
  }

  // Insert level completion status
  Future<int> insertLevelStatus(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.insert(tableLevelStatus, row);
  }

  // Query all rows from the user table
  Future<List<Map<String, dynamic>>> queryAllRows() async {
    Database db = await database;
    return await db.query(tableUser);
  }

  // Get level status (whether the level is unlocked)
  Future<List<Map<String, dynamic>>> getLevelStatus(int level) async {
    Database db = await database;
    return await db.query(
      tableLevelStatus,
      where: 'level = ?',
      whereArgs: [level],
    );
  }

  // Update level status
  Future<int> updateLevelStatus(int level, bool isUnlocked) async {
    Database db = await database;
    return await db.update(
      tableLevelStatus,
      {'isUnlocked': isUnlocked ? 1 : 0},
      where: 'level = ?',
      whereArgs: [level],
    );
  }

  Future<void> unlockNextLevel(int level) async {
    // Get the stars for the current level
    int stars = await getStars(level);

    // Check if the stars are at least 1
    if (stars >= 1) {
      // Unlock the next level
      int nextLevel = level + 1;
      Database db = await database;
      await db.update(
        tableLevelStatus,
        {'isUnlocked': 1},
        where: 'level = ?',
        whereArgs: [nextLevel],
      );
    }
  }


  // Check if a level is unlocked
  Future<bool> isLevelUnlocked(int level) async {
    Database db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      tableLevelStatus,
      where: 'level = ?',
      whereArgs: [level],
    );
    if (result.isNotEmpty) {
      return result.first['isUnlocked'] == 1;
    }
    return false;
  }

// Initialize level 1 as unlocked if the table is empty
  Future<void> initializeLevelStatus() async {
    Database db = await database;

    // Check if the level status table is empty
    final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM $tableLevelStatus'));

    if (count == 0) {
      // Unlock level 1 by default
      await db.insert(tableLevelStatus, {'level': 1, 'isUnlocked': 1});

      // Set other levels (2 to 6) as locked by default
      for (int i = 2; i <= 6; i++) {
        await db.insert(tableLevelStatus, {'level': i, 'isUnlocked': 0});
      }
    }
  }


  //updating the star rating
  Future<int> updateStars(int level, int stars) async {
    Database db = await database;
    return await db.update(
      tableLevelStatus,
      {'stars': stars},
      where: 'level = ?',
      whereArgs: [level],
    );
  }

  //getting star rating for particular level
  Future<int> getStars(int level) async {
    Database db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      tableLevelStatus,
      columns: ['stars'],
      where: 'level = ?',
      whereArgs: [level],
    );
    if (result.isNotEmpty) {
      return result.first['stars'];
    }
    return 0; // Default if no record found
  }


}
