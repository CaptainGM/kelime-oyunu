import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:path/path.dart';
import '../models/models.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    try {
      _database = await _initDatabase().timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Database initialization timeout'),
      );
    } catch (e) {
      debugPrint('Database error: $e');
      rethrow;
    }
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
      return await openDatabase('word_game.db', version: 1, onCreate: _createDb);
    }
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'word_game.db');

    return await openDatabase(path, version: 1, onCreate: _createDb);
  }

  Future<void> _createDb(Database db, int version) async {
   
    await db.execute('''
      CREATE TABLE players (
        id TEXT PRIMARY KEY,
        username TEXT UNIQUE NOT NULL,
        totalGold INTEGER DEFAULT 5000,
        createdAt TEXT NOT NULL,
        lastLoginAt TEXT NOT NULL
      )
    ''');

    
    await db.execute('''
      CREATE TABLE game_sessions (
        id TEXT PRIMARY KEY,
        playerId TEXT NOT NULL,
        gridSize INTEGER NOT NULL,
        totalMoves INTEGER NOT NULL,
        movesLeft INTEGER NOT NULL,
        score INTEGER DEFAULT 0,
        foundWords TEXT,
        startTime TEXT NOT NULL,
        endTime TEXT,
        isActive INTEGER DEFAULT 1,
        FOREIGN KEY (playerId) REFERENCES players(id)
      )
    ''');

   
    await db.execute(
      'CREATE INDEX idx_game_sessions_playerId ON game_sessions(playerId)',
    );
  }

  
  Future<Player?> getPlayer(String playerId) async {
    final db = await database;
    final result = await db.query(
      'players',
      where: 'id = ?',
      whereArgs: [playerId],
    );

    if (result.isEmpty) return null;
    return Player.fromMap(result.first);
  }

  Future<Player?> getPlayerByUsername(String username) async {
    final db = await database;
    final result = await db.query(
      'players',
      where: 'username = ?',
      whereArgs: [username],
    );

    if (result.isEmpty) return null;
    return Player.fromMap(result.first);
  }

  Future<void> savePlayer(Player player) async {
    final db = await database;
    await db.insert(
      'players',
      player.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updatePlayer(Player player) async {
    final db = await database;
    await db.update(
      'players',
      player.toMap(),
      where: 'id = ?',
      whereArgs: [player.id],
    );
  }

  
  Future<void> saveGameSession(GameSession session) async {
    final db = await database;
    await db.insert(
      'game_sessions',
      session.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<GameSession>> getGameSessions(String playerId) async {
    final db = await database;
    final result = await db.query(
      'game_sessions',
      where: 'playerId = ?',
      whereArgs: [playerId],
      orderBy: 'startTime DESC',
    );

    return result.map((map) => GameSession.fromMap(map)).toList();
  }

  Future<GameSession?> getGameSession(String sessionId) async {
    final db = await database;
    final result = await db.query(
      'game_sessions',
      where: 'id = ?',
      whereArgs: [sessionId],
    );

    if (result.isEmpty) return null;
    return GameSession.fromMap(result.first);
  }

  
  Future<Map<String, dynamic>> getPlayerStatistics(String playerId) async {
    final db = await database;

    final sessions = await db.query(
      'game_sessions',
      where: 'playerId = ?',
      whereArgs: [playerId],
    );

    if (sessions.isEmpty) {
      return {
        'totalGames': 0,
        'highestScore': 0,
        'averageScore': 0,
        'totalWords': 0,
        'longestWord': '',
        'totalPlayTime': 0,
      };
    }

    int totalGames = sessions.length;
    int highestScore = 0;
    int totalScore = 0;
    int totalWords = 0;
    String longestWord = '';
    int totalPlayTime = 0;

    for (var session in sessions) {
      final sessionMap = session;
      final score = (sessionMap['score'] as int?) ?? 0;
      final foundWords =
          (sessionMap['foundWords'] as String?)?.split(',') ?? [];
      final startTime = DateTime.parse(sessionMap['startTime'] as String);
      final endTime = sessionMap['endTime'] != null
          ? DateTime.parse(sessionMap['endTime'] as String)
          : DateTime.now();

      highestScore = highestScore > score ? highestScore : score;
      totalScore += score;
      totalWords += foundWords.where((w) => w.isNotEmpty).length;
      totalPlayTime += endTime.difference(startTime).inSeconds;

      for (var word in foundWords) {
        if (word.isNotEmpty && word.length > longestWord.length) {
          longestWord = word;
        }
      }
    }

    return {
      'totalGames': totalGames,
      'highestScore': highestScore,
      'averageScore': (totalScore / totalGames).toStringAsFixed(0),
      'totalWords': totalWords,
      'longestWord': longestWord.isEmpty ? '-' : longestWord,
      'totalPlayTime': totalPlayTime,
    };
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
