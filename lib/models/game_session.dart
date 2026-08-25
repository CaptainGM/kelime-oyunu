import 'package:uuid/uuid.dart';

class GameSession {
  String id;
  String playerId;
  int gridSize;
  int totalMoves;
  int movesLeft;
  int score;
  List<String> foundWords;
  DateTime startTime;
  DateTime? endTime;
  bool isActive;


  Map<String, int> jokers = {
    'fish': 0, // Rastgele harf yok et
    'wheel': 0, // Satır+Sütun temizle
    'lollipop': 0, // Harf kır
    'freeSwap': 0, // Harf değiştir
    'shuffle': 0, // Karıştır
    'party': 0, // Tümünü değiştir
  };

  GameSession({
    String? id,
    required this.playerId,
    required this.gridSize,
    required this.totalMoves,
    required this.startTime,
  }) : id = id ?? const Uuid().v4(),
       movesLeft = totalMoves,
       score = 0,
       foundWords = [],
       isActive = true,
       endTime = null;

  int get elapsedSeconds {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime).inSeconds;
  }

  void addWord(String word, int points) {
    foundWords.add(word);
    score += points;
    movesLeft--;
  }

  void useJoker(String jokerType) {
    if (jokers.containsKey(jokerType) && jokers[jokerType]! > 0) {
      jokers[jokerType] = jokers[jokerType]! - 1;
    }
  }

  void addJoker(String jokerType, int amount) {
    if (jokers.containsKey(jokerType)) {
      jokers[jokerType] = (jokers[jokerType] ?? 0) + amount;
    }
  }

  void endSession() {
    isActive = false;
    endTime = DateTime.now();
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'playerId': playerId,
      'gridSize': gridSize,
      'totalMoves': totalMoves,
      'movesLeft': movesLeft,
      'score': score,
      'foundWords': foundWords.join(','),
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'isActive': isActive ? 1 : 0,
    };
  }

  factory GameSession.fromMap(Map<String, dynamic> map) {
    return GameSession(
        id: map['id'],
        playerId: map['playerId'],
        gridSize: map['gridSize'],
        totalMoves: map['totalMoves'],
        startTime: DateTime.parse(map['startTime']),
      )
      ..movesLeft = map['movesLeft']
      ..score = map['score']
      ..foundWords = (map['foundWords'] as String)
          .split(',')
          .where((w) => w.isNotEmpty)
          .toList()
      ..endTime = map['endTime'] != null ? DateTime.parse(map['endTime']) : null
      ..isActive = map['isActive'] == 1;
  }
}
