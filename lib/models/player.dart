class Player {
  String id;
  String username;
  int totalGold;
  DateTime createdAt;
  DateTime lastLoginAt;

  Player({
    required this.id,
    required this.username,
    this.totalGold = 5000,
    required this.createdAt,
    required this.lastLoginAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'totalGold': totalGold,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt.toIso8601String(),
    };
  }

  factory Player.fromMap(Map<String, dynamic> map) {
    return Player(
      id: map['id'],
      username: map['username'],
      totalGold: map['totalGold'],
      createdAt: DateTime.parse(map['createdAt']),
      lastLoginAt: DateTime.parse(map['lastLoginAt']),
    );
  }
}
