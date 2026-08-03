import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import '../models/models.dart';
import '../services/services.dart';
import '../constants/app_constants.dart';

class GameScreen extends StatefulWidget {
  final Player player;
  final int gridSize;
  final int totalMoves;

  const GameScreen({
    super.key,
    required this.player,
    required this.gridSize,
    required this.totalMoves,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameSession _gameSession;
  late List<List<_GridCell>> _grid;
  late List<int> _selectedIndices;
  late WordService _wordService;
  late DatabaseService _dbService;
  late PreferenceService _prefService;
  late Stopwatch _stopwatch;
  late int _availableWords;
  final GlobalKey _boardKey = GlobalKey();
  Set<int> _jokerPreviewRemove = <int>{};
  Set<int> _jokerPreviewIncoming = <int>{};
  Set<int> _jokerPreviewSwap = <int>{};
  bool _showHintPanel = false;
  List<_WordCandidate> _hintCandidates = [];
  List<_WordCandidate> _disjointHintCandidates = [];
  List<int> _hintPreviewIndices = <int>[];

  @override
  void initState() {
    super.initState();
    _wordService = WordService();
    _dbService = DatabaseService();
    _prefService = PreferenceService();
    _selectedIndices = [];
    _stopwatch = Stopwatch()..start();

    _gameSession = GameSession(
      playerId: widget.player.id,
      gridSize: widget.gridSize,
      totalMoves: widget.totalMoves,
      startTime: DateTime.now(),
    );

    _initializeGame();
    _loadOwnedJokers();
  }

  Future<void> _loadOwnedJokers() async {
    final owned = _prefService.getOwnedJokers();
    if (!mounted) return;
    setState(() {
      _gameSession.jokers = {..._gameSession.jokers, ...owned};
    });
  }

  void _initializeGame() {
    final minTargetWords = widget.gridSize >= AppConstants.gridSizeEasy ? 3 : 1;
    int attempts = 0;
    do {
      _generateGrid();
      _guaranteePlayableGrid();
      attempts++;
    } while (_availableWords < minTargetWords && attempts < 14);
  }

  void _generateGrid() {
    _grid = List.generate(
      widget.gridSize,
      (_) => List.generate(widget.gridSize, (_) => const _GridCell(letter: '')),
    );

    final random = Random();
    final letters = AppConstants.letterFrequencies.keys.toList();

    for (int i = 0; i < widget.gridSize; i++) {
      for (int j = 0; j < widget.gridSize; j++) {
        _grid[i][j] = _GridCell(letter: _getRandomLetter(random, letters));
      }
    }

    _injectLongWordSeeds(random);
  }

  void _injectLongWordSeeds(Random random) {
    final dict = _wordService.getDictionary();
    final maxLen = min(8, widget.gridSize);

    List<String> bucket(int lo, int hi) => dict
        .where((w) => w.length >= lo && w.length <= min(hi, maxLen))
        .toList();

    final long = bucket(7, 8);
    final mid = bucket(5, 6);

    void seedFrom(List<String> pool, int count) {
      if (pool.isEmpty) return;
      for (int i = 0; i < count; i++) {
        for (int attempt = 0; attempt < 10; attempt++) {
          final word = pool[random.nextInt(pool.length)];
          if (_tryPlaceWordAsCurvedPath(word, random)) break;
        }
      }
    }

    final big = widget.gridSize >= 10;
    seedFrom(long, big ? 2 : 1);
    seedFrom(mid, big ? 2 : 1);
  }

  String _getRandomLetter(Random random, List<String> letters) {
    double randomValue = random.nextDouble() * 100;
    double cumulative = 0;

    for (String letter in letters) {
      cumulative += AppConstants.letterFrequencies[letter] ?? 0;
      if (randomValue <= cumulative) {
        return letter;
      }
    }

    return letters[random.nextInt(letters.length)];
  }

  bool _tryPlaceWordAsCurvedPath(
    String word,
    Random random, {
    Set<Point<int>>? allowedCells,
  }) {
    if (word.isEmpty || word.length > widget.gridSize * widget.gridSize) {
      return false;
    }

    final allowedIndices = allowedCells
        ?.map((p) => p.x * widget.gridSize + p.y)
        .toSet();
    final startCandidates = <int>[];
    for (int r = 0; r < widget.gridSize; r++) {
      for (int c = 0; c < widget.gridSize; c++) {
        final idx = r * widget.gridSize + c;
        if (allowedIndices == null || allowedIndices.contains(idx)) {
          startCandidates.add(idx);
        }
      }
    }
    if (startCandidates.isEmpty) return false;
    startCandidates.shuffle(random);

    bool isAllowed(int index) =>
        allowedIndices == null || allowedIndices.contains(index);

    List<int> shuffledNeighbors(int index) {
      final row = index ~/ widget.gridSize;
      final col = index % widget.gridSize;
      final neighbors = <int>[];
      for (int dr = -1; dr <= 1; dr++) {
        for (int dc = -1; dc <= 1; dc++) {
          if (dr == 0 && dc == 0) continue;
          final nr = row + dr;
          final nc = col + dc;
          if (nr < 0 ||
              nr >= widget.gridSize ||
              nc < 0 ||
              nc >= widget.gridSize) {
            continue;
          }
          final nextIdx = nr * widget.gridSize + nc;
          if (isAllowed(nextIdx)) {
            neighbors.add(nextIdx);
          }
        }
      }
      neighbors.shuffle(random);
      return neighbors;
    }

    bool hasDirectionChange(List<int> path) {
      if (path.length < 3) return true;
      int? prevDr;
      int? prevDc;
      for (int i = 1; i < path.length; i++) {
        final prev = path[i - 1];
        final curr = path[i];
        final prevRow = prev ~/ widget.gridSize;
        final prevCol = prev % widget.gridSize;
        final currRow = curr ~/ widget.gridSize;
        final currCol = curr % widget.gridSize;
        final dr = (currRow - prevRow).sign;
        final dc = (currCol - prevCol).sign;
        if (prevDr != null &&
            prevDc != null &&
            (dr != prevDr || dc != prevDc)) {
          return true;
        }
        prevDr = dr;
        prevDc = dc;
      }
      return false;
    }

    bool placeFromPath(List<int> path) {
      for (int i = 0; i < path.length; i++) {
        final idx = path[i];
        final row = idx ~/ widget.gridSize;
        final col = idx % widget.gridSize;
        _grid[row][col] = _GridCell(letter: word[i]);
      }
      return true;
    }

    bool dfs(int current, List<int> path, Set<int> visited) {
      if (path.length == word.length) {
        if (word.length >= 5 && !hasDirectionChange(path)) {
          return false;
        }
        return placeFromPath(path);
      }

      for (final next in shuffledNeighbors(current)) {
        if (visited.contains(next)) continue;
        visited.add(next);
        path.add(next);
        final ok = dfs(next, path, visited);
        if (ok) return true;
        path.removeLast();
        visited.remove(next);
      }
      return false;
    }

    for (final start in startCandidates) {
      final visited = <int>{start};
      final path = <int>[start];
      if (dfs(start, path, visited)) return true;
    }

    return false;
  }

  void _countAvailableWords() {
    final candidates = _collectCandidateWords();
    _availableWords = _maxDisjointWords(candidates);
    _disjointHintCandidates = _buildHintShowcaseCandidates(candidates);
    _hintCandidates = [...candidates]
      ..sort((a, b) {
        final lenCmp = b.word.length.compareTo(a.word.length);
        if (lenCmp != 0) return lenCmp;
        return _wordService
            .calculateWordScore(b.word)
            .compareTo(_wordService.calculateWordScore(a.word));
      });
  }

  List<_WordCandidate> _collectCandidateWords() {
    final Map<String, _WordCandidate> uniqueByWord = {};
    final maxWordLength = _wordService.getMaxWordLength();
    final maxDepth = maxWordLength < 3 ? 3 : min(maxWordLength, 8);

    void dfs(
      int row,
      int col,
      String currentWord,
      List<int> currentPath,
      Set<int> visited,
    ) {
      if (row < 0 ||
          row >= widget.gridSize ||
          col < 0 ||
          col >= widget.gridSize) {
        return;
      }
      final index = row * widget.gridSize + col;
      if (visited.contains(index)) return;

      final cell = _grid[row][col];
      if (cell.isEmpty) return;

      final nextWord = currentWord + cell.letter;
      if (!_wordService.isPrefix(nextWord)) return;

      final nextPath = [...currentPath, index];
      final nextVisited = {...visited, index};

      if (nextWord.length >= AppConstants.minWordLength &&
          _wordService.isValidWord(nextWord)) {
        uniqueByWord.putIfAbsent(
          nextWord,
          () => _WordCandidate(
            word: nextWord,
            indices: nextPath.toSet(),
            orderedIndices: nextPath,
          ),
        );
      }

      if (nextWord.length >= maxDepth) return;

      for (int di = -1; di <= 1; di++) {
        for (int dj = -1; dj <= 1; dj++) {
          if (di == 0 && dj == 0) continue;
          dfs(row + di, col + dj, nextWord, nextPath, nextVisited);
        }
      }
    }

    for (int i = 0; i < widget.gridSize; i++) {
      for (int j = 0; j < widget.gridSize; j++) {
        dfs(i, j, '', const [], <int>{});
      }
    }

    return uniqueByWord.values.toList();
  }

  int _maxDisjointWords(List<_WordCandidate> candidates) {
    if (candidates.isEmpty) return 0;
    final sorted = [...candidates]
      ..sort((a, b) => a.indices.length.compareTo(b.indices.length));
    int best = 0;

    void backtrack(int cursor, Set<int> used, int count) {
      if (count > best) best = count;
      if (cursor >= sorted.length) return;
      if (count + (sorted.length - cursor) <= best) return;

      for (int i = cursor; i < sorted.length; i++) {
        final candidate = sorted[i];
        if (candidate.indices.any(used.contains)) continue;
        backtrack(i + 1, {...used, ...candidate.indices}, count + 1);
      }
    }

    backtrack(0, <int>{}, 0);
    return best;
  }

  List<_WordCandidate> _buildHintShowcaseCandidates(
    List<_WordCandidate> candidates,
  ) {
    if (candidates.isEmpty) return const [];
    final sortedByPriority = [...candidates]
      ..sort((a, b) {
        final aLen = a.word.length;
        final bLen = b.word.length;
        final lenCmp = bLen.compareTo(aLen);
        if (lenCmp != 0) return lenCmp;
        return _wordService
            .calculateWordScore(b.word)
            .compareTo(_wordService.calculateWordScore(a.word));
      });

    final selected = <_WordCandidate>[];
    final used = <int>{};

    void pickByMinLength(int minLength) {
      for (final candidate in sortedByPriority) {
        if (candidate.word.length < minLength) continue;
        if (candidate.indices.any(used.contains)) continue;
        selected.add(candidate);
        used.addAll(candidate.indices);
        if (selected.length >= 12) return;
      }
    }

    pickByMinLength(7);
    if (selected.length < 12) pickByMinLength(6);
    if (selected.length < 12) pickByMinLength(5);

    if (selected.length < 12) pickByMinLength(3);

    return selected;
  }

  void _guaranteePlayableGrid() {
    _countAvailableWords();
    final minTargetWords = widget.gridSize >= AppConstants.gridSizeEasy ? 3 : 2;
    bool hasLongWord = _hintCandidates.any((c) => c.word.length >= 6);
    if (_availableWords >= minTargetWords && hasLongWord) return;

    final random = Random();
    final eligibleWords = _wordService
        .getDictionary()
        .where((w) => w.length >= 3 && w.length <= min(widget.gridSize, 7))
        .toList();
    if (eligibleWords.isEmpty) return;
    final longerWords = eligibleWords.where((w) => w.length >= 5).toList();
    final longerLongWords = eligibleWords.where((w) => w.length >= 6).toList();

    int safety = 0;
    while ((_availableWords < minTargetWords || !hasLongWord) && safety < 7) {
      final source = longerLongWords.isNotEmpty
          ? longerLongWords
          : (longerWords.isNotEmpty ? longerWords : eligibleWords);
      final fallbackWord = source[random.nextInt(source.length)];
      _tryPlaceWordAsCurvedPath(fallbackWord, random);
      _countAvailableWords();
      hasLongWord = _hintCandidates.any((c) => c.word.length >= 6);
      safety++;
    }
  }

  void _removeSelectedCells({
    SpecialPower? earnedPower,
    Map<int, SpecialPower> activatedPowers = const {},
  }) {
    final lastIndex = _selectedIndices.isNotEmpty ? _selectedIndices.last : -1;
    for (var index in _selectedIndices) {
      int row = index ~/ widget.gridSize;
      int col = index % widget.gridSize;
      final isPowerSpawn = earnedPower != null && index == lastIndex;
      if (isPowerSpawn) {
        _grid[row][col] = _grid[row][col].copyWith(power: earnedPower);
      } else {
        _grid[row][col] = const _GridCell(letter: '');
      }
    }

    for (final entry in activatedPowers.entries) {
      _activateSpecialPowerAt(entry.key, entry.value);
    }

    _applyGravity();
    _generateNewLetters();
    _guaranteePlayableGrid();
  }

  void _activateSpecialPowerAt(int centerIndex, SpecialPower power) {
    final centerRow = centerIndex ~/ widget.gridSize;
    final centerCol = centerIndex % widget.gridSize;

    bool inBounds(int r, int c) =>
        r >= 0 && r < widget.gridSize && c >= 0 && c < widget.gridSize;

    void clearCell(int r, int c) {
      if (inBounds(r, c)) {
        _grid[r][c] = const _GridCell(letter: '');
      }
    }

    switch (power) {
      case SpecialPower.lineClean:
        for (int c = 0; c < widget.gridSize; c++) {
          clearCell(centerRow, c);
        }
        break;
      case SpecialPower.columnClean:
        for (int r = 0; r < widget.gridSize; r++) {
          clearCell(r, centerCol);
        }
        break;
      case SpecialPower.areaBomb:
        for (int dr = -1; dr <= 1; dr++) {
          for (int dc = -1; dc <= 1; dc++) {
            clearCell(centerRow + dr, centerCol + dc);
          }
        }
        break;
      case SpecialPower.megaBomb:
        for (int dr = -2; dr <= 2; dr++) {
          for (int dc = -2; dc <= 2; dc++) {
            if (dr.abs() <= 2 && dc.abs() <= 2) {
              clearCell(centerRow + dr, centerCol + dc);
            }
          }
        }
        break;
    }
  }

  void _applyGravity() {
    for (int col = 0; col < widget.gridSize; col++) {
      List<_GridCell> column = [];
      for (int row = 0; row < widget.gridSize; row++) {
        if (_grid[row][col].isNotEmpty) {
          column.add(_grid[row][col]);
        }
      }

      for (int row = 0; row < widget.gridSize; row++) {
        _grid[row][col] = const _GridCell(letter: '');
      }

      int startRow = widget.gridSize - column.length;
      for (int i = 0; i < column.length; i++) {
        _grid[startRow + i][col] = column[i];
      }
    }
  }

  void _generateNewLetters() {
    final random = Random();
    final letters = AppConstants.letterFrequencies.keys.toList();

    final emptyCells = <Point<int>>{};
    for (int i = 0; i < widget.gridSize; i++) {
      for (int j = 0; j < widget.gridSize; j++) {
        if (_grid[i][j].isEmpty) emptyCells.add(Point(i, j));
      }
    }
    if (emptyCells.isEmpty) return;

    for (final p in emptyCells) {
      _grid[p.x][p.y] = _GridCell(letter: _getRandomLetter(random, letters));
    }

    _seedWordsInRefill(random, emptyCells);
  }

  void _seedWordsInRefill(Random random, Set<Point<int>> emptyCells) {
    final dict = _wordService.getDictionary();
    final maxLen = min(8, widget.gridSize);

    List<String> bucket(int lo, int hi) => dict
        .where((w) => w.length >= lo && w.length <= min(hi, maxLen))
        .toList();

    final long = bucket(7, 8);
    final mid = bucket(5, 6);

    bool tryPlace(List<String> pool) {
      if (pool.isEmpty) return false;
      final fits = pool.where((w) => w.length <= emptyCells.length).toList();
      if (fits.isEmpty) return false;
      for (int attempt = 0; attempt < 20; attempt++) {
        final word = fits[random.nextInt(fits.length)];
        if (_tryPlaceWordAsCurvedPath(word, random, allowedCells: emptyCells)) {
          return true;
        }
      }
      return false;
    }

    if (!tryPlace(long)) {
      tryPlace(mid);
    } else {
      tryPlace(mid);
    }
  }

  void _submitWord(String word) {
    _hintPreviewIndices = [];

    _gameSession.movesLeft--;

    if (word.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Minimum 3 harf gereklidir!'),
          duration: Duration(seconds: 1),
        ),
      );
      _selectedIndices.clear();
      _countAvailableWords();
      if (_gameSession.movesLeft <= 0) {
        _endGame();
      } else {
        setState(() {});
      }
      return;
    }

    if (_wordService.isValidWord(word)) {
      final activatedPowers = <int, SpecialPower>{};
      for (final index in _selectedIndices) {
        final row = index ~/ widget.gridSize;
        final col = index % widget.gridSize;
        final power = _grid[row][col].power;
        if (power != null) {
          activatedPowers[index] = power;
        }
      }

      final comboResult = _wordService.calculateCombo(word);
      int totalScore = comboResult.totalScore;

      final specialPower = _wordService.getSpecialPower(word.length);

      _gameSession.addWord(word, totalScore);
      _gameSession.movesLeft++;
      _removeSelectedCells(
        earnedPower: specialPower,
        activatedPowers: activatedPowers,
      );

      String scoreMsg = 'Doğru! +$totalScore puan';
      if (comboResult.foundWords.length > 1) {
        scoreMsg += '\nCombo x${comboResult.foundWords.length}';
      }
      if (specialPower != null) {
        scoreMsg +=
            '\n${_wordService.getSpecialPowerDescription(specialPower)}';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(scoreMsg), duration: const Duration(seconds: 2)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Geçersiz kelime!'),
          duration: Duration(seconds: 1),
        ),
      );
    }

    _selectedIndices.clear();
    _countAvailableWords();

    if (_gameSession.movesLeft <= 0) {
      _endGame();
    } else {
      setState(() {});
    }
  }

  void _endGame() {
    _stopwatch.stop();
    _gameSession.endSession();
    _dbService.saveGameSession(_gameSession);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => GameOverDialog(
        gameSession: _gameSession,
        onClose: () {
          Navigator.of(context).pop();
          Navigator.of(context).pop();
        },
      ),
    );
  }

  @override
  void dispose() {
    _stopwatch.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.keyQ) {
          setState(() => _showHintPanel = !_showHintPanel);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) {
            _showExitDialog();
          }
        },
        child: Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Puan: ${_gameSession.score}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    Text(
                      'Hamle: ${_gameSession.movesLeft}/${_gameSession.totalMoves}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Gridde olusturulabilir (cakismasiz): $_availableWords',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Bulunan: ${_gameSession.foundWords.length}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              GestureDetector(
                onTap: _showExitDialog,
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Icon(Icons.close),
                ),
              ),
            ],
          ),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFF4F0FF),
                  Color(0xFFECEFFF),
                  Color(0xFFF7EFFF),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          const spacing = 4.0;
                          final boardSize = constraints.maxWidth;
                          final cellSize =
                              (boardSize - (widget.gridSize - 1) * spacing) /
                              widget.gridSize;

                          return GestureDetector(
                            key: _boardKey,
                            onPanStart: (details) => _handleBoardDrag(
                              details.localPosition,
                              spacing,
                            ),
                            onPanUpdate: (details) => _handleBoardDrag(
                              details.localPosition,
                              spacing,
                            ),
                            child: Stack(
                              children: [
                                GridView.builder(
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: widget.gridSize,
                                        mainAxisSpacing: spacing,
                                        crossAxisSpacing: spacing,
                                      ),
                                  itemCount: widget.gridSize * widget.gridSize,
                                  itemBuilder: (context, index) {
                                    int row = index ~/ widget.gridSize;
                                    int col = index % widget.gridSize;
                                    bool isSelected = _selectedIndices.contains(
                                      index,
                                    );
                                    final cell = _grid[row][col];
                                    final isRemoving = _jokerPreviewRemove
                                        .contains(index);
                                    final isIncoming = _jokerPreviewIncoming
                                        .contains(index);
                                    final isSwapping = _jokerPreviewSwap
                                        .contains(index);

                                    return AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 150,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: isSelected
                                            ? const LinearGradient(
                                                colors: [
                                                  Color(0xFF7E57C2),
                                                  Color(0xFF5E35B1),
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              )
                                            : const LinearGradient(
                                                colors: [
                                                  Color(0xFFF8FAFC),
                                                  Color(0xFFE2E8F0),
                                                ],
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                              ),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: isSelected
                                              ? Colors.deepPurple
                                              : Colors.white,
                                          width: isSelected ? 1.5 : 1,
                                        ),
                                      ),
                                      child: Stack(
                                        children: [
                                          Center(
                                            child: Text(
                                              cell.letter,
                                              style: TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                                color: isSelected
                                                    ? Colors.white
                                                    : Colors.black87,
                                              ),
                                            ),
                                          ),
                                          if (isIncoming && !isRemoving)
                                            Positioned.fill(
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.green
                                                      .withValues(alpha: 0.22),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: const Align(
                                                  alignment:
                                                      Alignment.topCenter,
                                                  child: Text(
                                                    '↓',
                                                    style: TextStyle(
                                                      color: Colors.green,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          if (isSwapping)
                                            Positioned.fill(
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.blue.withValues(
                                                    alpha: 0.2,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: const Center(
                                                  child: Icon(
                                                    Icons.swap_horiz,
                                                    size: 16,
                                                    color: Colors.blue,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          if (isRemoving)
                                            Positioned.fill(
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.red.withValues(
                                                    alpha: 0.28,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: const Center(
                                                  child: Icon(
                                                    Icons.close,
                                                    size: 16,
                                                    color: Colors.red,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          if (cell.power != null)
                                            Positioned(
                                              right: 2,
                                              top: 2,
                                              child: Text(
                                                _powerSymbol(cell.power!),
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                                IgnorePointer(
                                  child: CustomPaint(
                                    size: Size(boardSize, boardSize),
                                    painter: _SelectionPathPainter(
                                      selectedIndices: _selectedIndices,
                                      hintIndices: _hintPreviewIndices,
                                      gridSize: widget.gridSize,
                                      cellSize: cellSize,
                                      spacing: spacing,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  if (_jokerPreviewRemove.isNotEmpty ||
                      _jokerPreviewIncoming.isNotEmpty ||
                      _jokerPreviewSwap.isNotEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Kırmızı=Silinecek  ',
                            style: TextStyle(fontSize: 11),
                          ),
                          Text(
                            'Yeşil=Yeni Harf  ',
                            style: TextStyle(fontSize: 11),
                          ),
                          Text(
                            'Mavi=Yer Değiştir',
                            style: TextStyle(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  if (_showHintPanel)
                    Container(
                      margin: const EdgeInsets.fromLTRB(12, 0, 12, 6),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.deepPurple.shade100),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Q paneli - Cakismaz olasi kelimeler (${_disjointHintCandidates.length})',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.deepPurple.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _hintCandidates.isEmpty
                                ? 'Kelime yok'
                                : 'Bir kelimeye dokun, yolu gridde cizilsin',
                            style: const TextStyle(fontSize: 11),
                          ),
                          if (_disjointHintCandidates.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: _disjointHintCandidates.take(12).map((
                                candidate,
                              ) {
                                final active =
                                    _selectedIndices.isNotEmpty &&
                                    _selectedIndices.join(',') ==
                                        candidate.orderedIndices.join(',');
                                return ActionChip(
                                  label: Text(
                                    '${candidate.word}(${_wordService.calculateWordScore(candidate.word)})',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  backgroundColor: active
                                      ? Colors.deepPurple.shade100
                                      : Colors.grey.shade100,
                                  onPressed: () {
                                    setState(() {
                                      if (active) {
                                        _selectedIndices.clear();
                                      } else {
                                        _selectedIndices = [
                                          ...candidate.orderedIndices,
                                        ];
                                        _hintPreviewIndices = [];
                                      }
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),

                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Jokerler:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildJokerButton(
                                'Balık',
                                _gameSession.jokers['fish'] ?? 0,
                                'fish',
                                'assets/images/joker_fish.png',
                                Icons.set_meal,
                              ),
                              const SizedBox(width: 8),
                              _buildJokerButton(
                                'Tekerlek',
                                _gameSession.jokers['wheel'] ?? 0,
                                'wheel',
                                'assets/images/joker_wheel.png',
                                Icons.adjust,
                              ),
                              const SizedBox(width: 8),
                              _buildJokerButton(
                                'Lolipop',
                                _gameSession.jokers['lollipop'] ?? 0,
                                'lollipop',
                                'assets/images/joker_lollipop.png',
                                Icons.icecream,
                              ),
                              const SizedBox(width: 8),
                              _buildJokerButton(
                                'Değiştir',
                                _gameSession.jokers['freeSwap'] ?? 0,
                                'freeSwap',
                                'assets/images/joker_swap.png',
                                Icons.back_hand,
                              ),
                              const SizedBox(width: 8),
                              _buildJokerButton(
                                'Karıştır',
                                _gameSession.jokers['shuffle'] ?? 0,
                                'shuffle',
                                'assets/images/joker_shuffle.png',
                                Icons.casino,
                              ),
                              const SizedBox(width: 8),
                              _buildJokerButton(
                                'Parti',
                                _gameSession.jokers['party'] ?? 0,
                                'party',
                                'assets/images/joker_party.png',
                                Icons.celebration,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_selectedIndices.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(
                            _buildWordFromSelection(),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    setState(() => _selectedIndices.clear());
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey,
                                  ),
                                  child: const Text('İptal'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    _submitWord(_buildWordFromSelection());
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.deepPurple,
                                  ),
                                  child: const Text('Onayla'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _buildWordFromSelection() {
    return _selectedIndices.map((index) {
      int row = index ~/ widget.gridSize;
      int col = index % widget.gridSize;
      return _grid[row][col].letter;
    }).join();
  }

  bool _isAdjacent(int index1, int index2) {
    int row1 = index1 ~/ widget.gridSize;
    int col1 = index1 % widget.gridSize;
    int row2 = index2 ~/ widget.gridSize;
    int col2 = index2 % widget.gridSize;

    return (row1 - row2).abs() <= 1 && (col1 - col2).abs() <= 1;
  }

  void _handleBoardDrag(Offset position, double spacing) {
    final index = _indexFromPosition(position, spacing);
    if (index == null) return;

    setState(() {
      _hintPreviewIndices = [];
      if (_selectedIndices.isEmpty) {
        _selectedIndices.add(index);
        return;
      }

      final last = _selectedIndices.last;
      if (index == last) return;

      if (_selectedIndices.length >= 2 &&
          _selectedIndices[_selectedIndices.length - 2] == index) {
        _selectedIndices.removeLast();
        return;
      }

      if (_selectedIndices.contains(index)) return;
      if (_isAdjacent(index, last)) {
        _selectedIndices.add(index);
      }
    });
  }

  int? _indexFromPosition(Offset localPosition, double spacing) {
    final renderObject = _boardKey.currentContext?.findRenderObject();
    if (renderObject is! RenderBox) return null;
    final size = renderObject.size.width;
    if (localPosition.dx < 0 ||
        localPosition.dy < 0 ||
        localPosition.dx > size ||
        localPosition.dy > size) {
      return null;
    }

    final cellSize = (size - (widget.gridSize - 1) * spacing) / widget.gridSize;
    final step = cellSize + spacing;
    final col = (localPosition.dx / step).floor();
    final row = (localPosition.dy / step).floor();
    if (row < 0 ||
        row >= widget.gridSize ||
        col < 0 ||
        col >= widget.gridSize) {
      return null;
    }
    return row * widget.gridSize + col;
  }

  String _powerSymbol(SpecialPower power) {
    switch (power) {
      case SpecialPower.lineClean:
        return '⇆';
      case SpecialPower.areaBomb:
        return '✹';
      case SpecialPower.columnClean:
        return '⇅';
      case SpecialPower.megaBomb:
        return '✪';
    }
  }

  Widget _buildJokerButton(
    String label,
    int count,
    String jokerType,
    String assetPath,
    IconData fallbackIcon,
  ) {
    return ElevatedButton(
      onPressed: count > 0
          ? () async {
              await _useJoker(jokerType);
            }
          : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: count > 0 ? Colors.amber : Colors.grey,
        disabledBackgroundColor: Colors.grey,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: jokerType == 'wheel' ? 26 : 18,
            height: jokerType == 'wheel' ? 26 : 18,
            child: Padding(
              padding: EdgeInsets.all(jokerType == 'wheel' ? 0.5 : 0),
              child: Image.asset(
                assetPath,
                fit: BoxFit.contain,
                alignment: jokerType == 'wheel'
                    ? const Alignment(0.42, 0)
                    : Alignment.center,
                errorBuilder: (context, error, stackTrace) =>
                    Icon(fallbackIcon, size: 14, color: Colors.white),
              ),
            ),
          ),
          Text(label, style: const TextStyle(fontSize: 10)),
          Text(
            'x$count',
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Future<void> _useJoker(String jokerType) async {
    int beforeCount = _gameSession.jokers[jokerType] ?? 0;

    if (beforeCount <= 0) return;
    if (!_canUseJoker(jokerType)) return;

    _gameSession.useJoker(jokerType);

    switch (jokerType) {
      case 'fish':
        await _useJokerFish();
        break;
      case 'wheel':
        await _useJokerWheel();
        break;
      case 'lollipop':
        await _useJokerLollipop();
        break;
      case 'freeSwap':
        await _useJokerSwap();
        break;
      case 'shuffle':
        await _useJokerShuffle();
        break;
      case 'party':
        await _useJokerParty();
        break;
    }

    _guaranteePlayableGrid();
    await _persistJokers();
    _countAvailableWords();

    if (!mounted) return;
    final jokerName = _jokerDisplayName(jokerType);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$jokerName jokeri kullanıldı! (Kalan: ${beforeCount - 1})',
        ),
        duration: const Duration(milliseconds: 800),
      ),
    );
    setState(() {});
  }

  String _jokerDisplayName(String jokerType) {
    switch (jokerType) {
      case 'fish':
        return 'Balik';
      case 'wheel':
        return 'Tekerlek';
      case 'lollipop':
        return 'Lolipop';
      case 'freeSwap':
        return 'Degistirme';
      case 'shuffle':
        return 'Karistir';
      case 'party':
        return 'Parti';
      default:
        return 'Joker';
    }
  }

  bool _canUseJoker(String jokerType) {
    if (jokerType == 'wheel' || jokerType == 'lollipop') {
      if (_selectedIndices.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Önce bir hücre seçiniz!')),
        );
        return false;
      }
    }
    if (jokerType == 'freeSwap') {
      if (_selectedIndices.length < 2) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('2 komşu hücre seçiniz!')));
        return false;
      }
      final i1 = _selectedIndices[_selectedIndices.length - 2];
      final i2 = _selectedIndices.last;
      if (!_isAdjacent(i1, i2)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Seçilen hücreler komşu olmalı!')),
        );
        return false;
      }
    }
    return true;
  }

  Future<void> _previewJokerEffect({
    Set<int> remove = const {},
    Set<int> incoming = const {},
    Set<int> swap = const {},
    Duration duration = const Duration(seconds: 3),
  }) async {
    if (!mounted) return;
    setState(() {
      _jokerPreviewRemove = {...remove};
      _jokerPreviewIncoming = {...incoming};
      _jokerPreviewSwap = {...swap};
    });
    await Future.delayed(duration);
    if (!mounted) return;
    setState(() {
      _jokerPreviewRemove.clear();
      _jokerPreviewIncoming.clear();
      _jokerPreviewSwap.clear();
    });
  }

  Future<void> _useJokerFish() async {
    final random = Random();
    final toRemove = (widget.gridSize * 0.3).toInt();
    final nonEmptyIndices = <int>[];
    for (int r = 0; r < widget.gridSize; r++) {
      for (int c = 0; c < widget.gridSize; c++) {
        if (_grid[r][c].isNotEmpty) {
          nonEmptyIndices.add(r * widget.gridSize + c);
        }
      }
    }
    nonEmptyIndices.shuffle(random);
    final removeSet = nonEmptyIndices.take(toRemove).toSet();
    final incomingSet = removeSet.map((i) => i % widget.gridSize).toSet();
    await _previewJokerEffect(remove: removeSet, incoming: incomingSet);

    for (final index in removeSet) {
      final row = index ~/ widget.gridSize;
      final col = index % widget.gridSize;
      _grid[row][col] = const _GridCell(letter: '');
    }
    _applyGravity();
    _generateNewLetters();
  }

  Future<void> _useJokerWheel() async {
    int index = _selectedIndices.first;
    int row = index ~/ widget.gridSize;
    int col = index % widget.gridSize;
    final removeSet = <int>{};

    for (int j = 0; j < widget.gridSize; j++) {
      removeSet.add(row * widget.gridSize + j);
    }

    for (int i = 0; i < widget.gridSize; i++) {
      removeSet.add(i * widget.gridSize + col);
    }
    final incomingSet = removeSet.map((i) => i % widget.gridSize).toSet();
    await _previewJokerEffect(remove: removeSet, incoming: incomingSet);

    for (final i in removeSet) {
      final rr = i ~/ widget.gridSize;
      final cc = i % widget.gridSize;
      _grid[rr][cc] = const _GridCell(letter: '');
    }

    _selectedIndices.clear();
    _applyGravity();
    _generateNewLetters();
  }

  Future<void> _useJokerLollipop() async {
    int index = _selectedIndices.first;
    int row = index ~/ widget.gridSize;
    int col = index % widget.gridSize;
    await _previewJokerEffect(remove: {index}, incoming: {col});
    _grid[row][col] = const _GridCell(letter: '');

    _selectedIndices.clear();
    _applyGravity();
    _generateNewLetters();
  }

  Future<void> _useJokerSwap() async {
    int index1 = _selectedIndices[_selectedIndices.length - 2];
    int index2 = _selectedIndices.last;
    await _previewJokerEffect(swap: {index1, index2});

    int row1 = index1 ~/ widget.gridSize;
    int col1 = index1 % widget.gridSize;
    int row2 = index2 ~/ widget.gridSize;
    int col2 = index2 % widget.gridSize;

    _GridCell temp = _grid[row1][col1];
    _grid[row1][col1] = _grid[row2][col2];
    _grid[row2][col2] = temp;

    _selectedIndices.clear();
  }

  Future<void> _useJokerShuffle() async {
    final random = Random();
    List<_GridCell> allLetters = [];
    final allIndices = <int>{
      for (int i = 0; i < widget.gridSize * widget.gridSize; i++) i,
    };
    await _previewJokerEffect(swap: allIndices);

    for (int i = 0; i < widget.gridSize; i++) {
      for (int j = 0; j < widget.gridSize; j++) {
        allLetters.add(_grid[i][j]);
      }
    }

    allLetters.shuffle(random);

    int index = 0;
    for (int i = 0; i < widget.gridSize; i++) {
      for (int j = 0; j < widget.gridSize; j++) {
        _grid[i][j] = allLetters[index++];
      }
    }

    _selectedIndices.clear();
  }

  Future<void> _useJokerParty() async {
    final allIndices = <int>{
      for (int i = 0; i < widget.gridSize * widget.gridSize; i++) i,
    };
    final topRow = <int>{for (int i = 0; i < widget.gridSize; i++) i};
    await _previewJokerEffect(remove: allIndices, incoming: topRow);
    _initializeGame();
    _selectedIndices.clear();
  }

  Future<void> _persistJokers() async {
    await _prefService.setOwnedJokers(_gameSession.jokers);
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Çıkış'),
        content: const Text('Oyundan çıkmak istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hayır'),
          ),
          TextButton(
            onPressed: () {
              _stopwatch.stop();
              _gameSession.endSession();
              _dbService.saveGameSession(_gameSession);
              _persistJokers();
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Evet'),
          ),
        ],
      ),
    );
  }
}

class _GridCell {
  final String letter;
  final SpecialPower? power;

  const _GridCell({required this.letter, this.power});

  bool get isEmpty => letter.isEmpty;
  bool get isNotEmpty => letter.isNotEmpty;

  _GridCell copyWith({
    String? letter,
    SpecialPower? power,
    bool clearPower = false,
  }) {
    return _GridCell(
      letter: letter ?? this.letter,
      power: clearPower ? null : (power ?? this.power),
    );
  }
}

class _WordCandidate {
  final String word;
  final Set<int> indices;
  final List<int> orderedIndices;

  _WordCandidate({
    required this.word,
    required this.indices,
    required this.orderedIndices,
  });
}

class _SelectionPathPainter extends CustomPainter {
  final List<int> selectedIndices;
  final List<int> hintIndices;
  final int gridSize;
  final double cellSize;
  final double spacing;

  _SelectionPathPainter({
    required this.selectedIndices,
    required this.hintIndices,
    required this.gridSize,
    required this.cellSize,
    required this.spacing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final basePaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final accentPaint = Paint()
      ..color = const Color(0xFFFFC107)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final hintPaint = Paint()
      ..color = Colors.redAccent
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final hintBasePaint = Paint()
      ..color = Colors.black87
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final hintNodePaint = Paint()
      ..color = Colors.redAccent
      ..style = PaintingStyle.fill;

    Offset centerFor(int index) {
      final row = index ~/ gridSize;
      final col = index % gridSize;
      final x = col * (cellSize + spacing) + cellSize / 2;
      final y = row * (cellSize + spacing) + cellSize / 2;
      return Offset(x, y);
    }

    Offset edgePoint(Offset from, Offset to, double inset) {
      final dx = to.dx - from.dx;
      final dy = to.dy - from.dy;
      final len = sqrt(dx * dx + dy * dy);
      if (len == 0) return from;
      return Offset(from.dx + (dx / len) * inset, from.dy + (dy / len) * inset);
    }

    if (selectedIndices.length >= 2) {
      for (int i = 0; i < selectedIndices.length - 1; i++) {
        final start = centerFor(selectedIndices[i]);
        final end = centerFor(selectedIndices[i + 1]);
        final trimmedStart = edgePoint(start, end, cellSize * 0.28);
        final trimmedEnd = edgePoint(end, start, cellSize * 0.28);
        canvas.drawLine(trimmedStart, trimmedEnd, basePaint);
        canvas.drawLine(trimmedStart, trimmedEnd, accentPaint);
      }
    }

    if (hintIndices.length >= 2 && selectedIndices.isEmpty) {
      for (int i = 0; i < hintIndices.length - 1; i++) {
        final start = centerFor(hintIndices[i]);
        final end = centerFor(hintIndices[i + 1]);
        final trimmedStart = edgePoint(start, end, cellSize * 0.28);
        final trimmedEnd = edgePoint(end, start, cellSize * 0.28);
        canvas.drawLine(trimmedStart, trimmedEnd, hintBasePaint);
        canvas.drawLine(trimmedStart, trimmedEnd, hintPaint);
      }
      for (final idx in hintIndices) {
        canvas.drawCircle(centerFor(idx), 4.5, hintNodePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SelectionPathPainter oldDelegate) {
    return oldDelegate.selectedIndices != selectedIndices ||
        oldDelegate.hintIndices != hintIndices ||
        oldDelegate.gridSize != gridSize ||
        oldDelegate.cellSize != cellSize ||
        oldDelegate.spacing != spacing;
  }
}

class GameOverDialog extends StatelessWidget {
  final GameSession gameSession;
  final VoidCallback onClose;

  const GameOverDialog({
    super.key,
    required this.gameSession,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Oyun Bitti!'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Puanınız: ${gameSession.score}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(height: 16),
          Text('Bulunan Kelimeler: ${gameSession.foundWords.length}'),
          const SizedBox(height: 8),
          Text(
            'Hamle: ${gameSession.totalMoves - gameSession.movesLeft}/${gameSession.totalMoves}',
          ),
        ],
      ),
      actions: [ElevatedButton(onPressed: onClose, child: const Text('Kapat'))],
    );
  }
}
