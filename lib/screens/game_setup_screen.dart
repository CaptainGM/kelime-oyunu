import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../models/models.dart';
import 'game_screen.dart';

class GameSetupScreen extends StatefulWidget {
  final Player player;

  const GameSetupScreen({super.key, required this.player});

  @override
  State<GameSetupScreen> createState() => _GameSetupScreenState();
}

class _GameSetupScreenState extends State<GameSetupScreen> {
  int? _selectedGridSize;
  int? _selectedMoves;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Oyun Ayarları')),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
               
                Text(
                  'Grid Boyutu Seçin',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                _buildGridSizeOption(
                  size: '10x10',
                  level: 'Kolay Seviye',
                  selected: _selectedGridSize == AppConstants.gridSizeEasy,
                  onTap: () => setState(
                    () => _selectedGridSize = AppConstants.gridSizeEasy,
                  ),
                ),
                const SizedBox(height: 12),
                _buildGridSizeOption(
                  size: '8x8',
                  level: 'Orta Seviye',
                  selected: _selectedGridSize == AppConstants.gridSizeMedium,
                  onTap: () => setState(
                    () => _selectedGridSize = AppConstants.gridSizeMedium,
                  ),
                ),
                const SizedBox(height: 12),
                _buildGridSizeOption(
                  size: '6x6',
                  level: 'Zor Seviye',
                  selected: _selectedGridSize == AppConstants.gridSizeHard,
                  onTap: () => setState(
                    () => _selectedGridSize = AppConstants.gridSizeHard,
                  ),
                ),
                const SizedBox(height: 40),

                
                if (_selectedGridSize != null) ...[
                  Text(
                    'Hamle Sayısı Seçin',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _buildMovesOption(
                    moves: AppConstants.movesEasy,
                    level: 'Kolay',
                    selected: _selectedMoves == AppConstants.movesEasy,
                    onTap: () =>
                        setState(() => _selectedMoves = AppConstants.movesEasy),
                  ),
                  const SizedBox(height: 12),
                  _buildMovesOption(
                    moves: AppConstants.movesMedium,
                    level: 'Orta',
                    selected: _selectedMoves == AppConstants.movesMedium,
                    onTap: () =>
                        setState(() => _selectedMoves = AppConstants.movesMedium),
                  ),
                  const SizedBox(height: 12),
                  _buildMovesOption(
                    moves: AppConstants.movesHard,
                    level: 'Zor',
                    selected: _selectedMoves == AppConstants.movesHard,
                    onTap: () =>
                        setState(() => _selectedMoves = AppConstants.movesHard),
                  ),
                  const SizedBox(height: 40),
                ],

                
                if (_selectedGridSize != null && _selectedMoves != null)
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _startGame,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Oyunu Başlat',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGridSizeOption({
    required String size,
    required String level,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: selected ? Colors.deepPurple : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: selected ? Colors.deepPurple.shade50 : Colors.transparent,
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? Colors.deepPurple : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.deepPurple,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  size,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  level,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMovesOption({
    required int moves,
    required String level,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: selected ? Colors.deepPurple : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: selected ? Colors.deepPurple.shade50 : Colors.transparent,
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? Colors.deepPurple : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.deepPurple,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$moves Hamle',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$level Seviye',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _startGame() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameScreen(
          player: widget.player,
          gridSize: _selectedGridSize!,
          totalMoves: _selectedMoves!,
        ),
      ),
    );
  }
}
