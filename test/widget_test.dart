import 'package:flutter_test/flutter_test.dart';
import 'package:word_game/constants/app_constants.dart';
import 'package:word_game/models/game_session.dart';

void main() {
  test('Grid boyutu ile hamle eslesmesi sabit', () {
    expect(AppConstants.movesForGrid(AppConstants.gridSizeHard), 15);
    expect(AppConstants.movesForGrid(AppConstants.gridSizeMedium), 20);
    expect(AppConstants.movesForGrid(AppConstants.gridSizeEasy), 25);
  });

  test('Harf puani tablosu soru ornegini saglar', () {
    final soruScore = (AppConstants.letterScores['S'] ?? 0) +
        (AppConstants.letterScores['O'] ?? 0) +
        (AppConstants.letterScores['R'] ?? 0) +
        (AppConstants.letterScores['U'] ?? 0);
    expect(soruScore, 7);
  });

  test('GameSession addWord puan ve hamleyi gunceller', () {
    final session = GameSession(
      playerId: 'p1',
      gridSize: AppConstants.gridSizeMedium,
      totalMoves: AppConstants.movesMedium,
      startTime: DateTime(2026, 1, 1),
    );
    final startingMoves = session.movesLeft;

    session.addWord('SORU', 7);

    expect(session.score, 7);
    expect(session.foundWords, ['SORU']);
    expect(session.movesLeft, startingMoves - 1);
  });
}
