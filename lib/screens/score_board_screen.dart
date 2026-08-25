import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/services.dart';

class ScoreBoardScreen extends StatefulWidget {
  final Player player;

  const ScoreBoardScreen({super.key, required this.player});

  @override
  State<ScoreBoardScreen> createState() => _ScoreBoardScreenState();
}

class _ScoreBoardScreenState extends State<ScoreBoardScreen> {
  late Future<List<GameSession>> _sessionsFuture;
  late Future<Map<String, dynamic>> _statsFuture;
  final _dbService = DatabaseService();

  @override
  void initState() {
    super.initState();
    _sessionsFuture = _dbService.getGameSessions(widget.player.id);
    _statsFuture = _dbService.getPlayerStatistics(widget.player.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Skor Tablosu')),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                
                FutureBuilder<Map<String, dynamic>>(
                  future: _statsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return const Text('Hata oluştu');
                    }

                    final stats = snapshot.data ?? {};
                    return _buildStatsSummary(stats);
                  },
                ),
                const SizedBox(height: 32),

                
                Text(
                  'Oyun Geçmişi',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                FutureBuilder<List<GameSession>>(
                  future: _sessionsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return const Text('Hata oluştu');
                    }

                    final sessions = snapshot.data ?? [];

                    if (sessions.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text('Henüz oyun oynamamışsın'),
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: sessions.length,
                      itemBuilder: (context, index) {
                        return _buildGameCard(sessions[index], index + 1);
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSummary(Map<String, dynamic> stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.deepPurple.shade200),
      ),
      child: Column(
        children: [
          _buildStatRow('Toplam Oyun', stats['totalGames'].toString()),
          const Divider(),
          _buildStatRow('En Yüksek Puan', stats['highestScore'].toString()),
          const Divider(),
          _buildStatRow('Ortalama Puan', stats['averageScore'].toString()),
          const Divider(),
          _buildStatRow('Toplam Kelime', stats['totalWords'].toString()),
          const Divider(),
          _buildStatRow('En Uzun Kelime', stats['longestWord'].toString()),
          const Divider(),
          _buildStatRow(
            'Toplam Süre',
            _formatDuration(stats['totalPlayTime'] as int),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameCard(GameSession session, int gameNumber) {
    final startTime = session.startTime;
    final endTime = session.endTime ?? DateTime.now();
    final duration = endTime.difference(startTime);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Oyun $gameNumber',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Puan: ${session.score}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.deepPurple,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildGameInfoRow(
              'Tarih',
              DateFormat('dd.MM.yyyy HH:mm').format(startTime),
            ),
            _buildGameInfoRow(
              'Grid',
              '${session.gridSize}x${session.gridSize}',
            ),
            _buildGameInfoRow('Kelime Sayısı', '${session.foundWords.length}'),
            if (session.foundWords.isNotEmpty)
              _buildGameInfoRow(
                'En Uzun Kelime',
                session.foundWords.reduce(
                  (a, b) => a.length > b.length ? a : b,
                ),
              ),
            _buildGameInfoRow('Süre', '${duration.inMinutes} dk'),
          ],
        ),
      ),
    );
  }

  Widget _buildGameInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '$hours sa $minutes dk';
  }
}
