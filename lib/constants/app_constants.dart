class AppConstants {
 
  static const int gridSizeEasy = 10; // 10x10
  static const int gridSizeMedium = 8; // 8x8
  static const int gridSizeHard = 6; // 6x6


  static const int movesEasy = 25;
  static const int movesMedium = 20;
  static const int movesHard = 15;

  static int movesForGrid(int gridSize) {
    switch (gridSize) {
      case gridSizeEasy:
        return movesEasy;
      case gridSizeMedium:
        return movesMedium;
      case gridSizeHard:
        return movesHard;
      default:
        return movesMedium;
    }
  }

  static String difficultyForGrid(int gridSize) {
    switch (gridSize) {
      case gridSizeEasy:
        return 'Kolay';
      case gridSizeMedium:
        return 'Orta';
      case gridSizeHard:
        return 'Zor';
      default:
        return 'Bilinmiyor';
    }
  }

  static const int minWordLength = 3;


  static const int startingGold = 5000;

  
  static const int jokerFish = 100;
  static const int jokerWheel = 200;
  static const int jokerLollipop = 75;
  static const int jokerFreeSwap = 125;
  static const int jokerShuffle = 300;
  static const int jokerParty = 400;

 
  static const Map<String, double> letterFrequencies = {
    'A': 11.5,
    'E': 8.5,
    'İ': 8.0,
    'I': 5.0,
    'N': 7.0,
    'R': 6.5,
    'L': 5.8,
    'K': 4.7,
    'D': 4.7,
    'M': 3.7,
    'Y': 3.4,
    'U': 3.4,
    'T': 3.3,
    'S': 3.0,
    'B': 2.8,
    'O': 2.5,
    'Ü': 1.9,
    'Ş': 1.8,
    'Z': 1.5,
    'G': 1.3,
    'Ç': 1.2,
    'H': 1.1,
    'C': 1.0,
    'P': 0.9,
    'Ö': 0.8,
    'V': 1.0,
    'F': 0.5,
    'Ğ': 1.1,
    'J': 0.1,
  };

  static const Map<String, int> letterScores = {
    'A': 1,
    'B': 3,
    'C': 4,
    'Ç': 4,
    'D': 3,
    'E': 1,
    'F': 7,
    'G': 5,
    'Ğ': 8,
    'H': 5,
    'I': 2,
    'İ': 1,
    'J': 10,
    'K': 1,
    'L': 1,
    'M': 2,
    'N': 1,
    'O': 2,
    'Ö': 7,
    'P': 5,
    'R': 1,
    'S': 2,
    'Ş': 4,
    'T': 1,
    'U': 2,
    'Ü': 3,
    'V': 7,
    'Y': 3,
    'Z': 4,
  };
}
