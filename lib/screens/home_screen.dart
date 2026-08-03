import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../services/services.dart';
import 'game_setup_screen.dart';
import 'score_board_screen.dart';
import 'market_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Player _currentPlayer;
  bool _isLoading = true;
  final _dbService = DatabaseService();
  final _prefService = PreferenceService();

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      String? playerId = _prefService.getCurrentPlayerId();

      if (playerId != null) {
        final player = await _dbService.getPlayer(playerId);
        if (player != null && mounted) {
          setState(() {
            _currentPlayer = player;
            _isLoading = false;
          });
          return;
        }
      }

    
      if (mounted) {
        _showUsernameDialogDeferred();
      }
    } catch (e) {
      debugPrint('Player initialization error: $e');
      if (mounted) {
        _showUsernameDialogDeferred();
      }
    }
  }

  void _showUsernameDialogDeferred({String? initialUsername, bool isEdit = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showUsernameDialog(initialUsername: initialUsername, isEdit: isEdit);
    });
  }

  void _showUsernameDialog({String? initialUsername, bool isEdit = false}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => UsernameDialog(
        initialUsername: initialUsername,
        isEdit: isEdit,
        onUsernameSubmitted: (username) async {
          debugPrint('Username submitted: $username');

          try {
            
            Navigator.of(dialogContext).pop();
            debugPrint('Dialog closed');

            late final Player player;
            if (isEdit) {
              player = Player(
                id: _currentPlayer.id,
                username: username,
                totalGold: _currentPlayer.totalGold,
                createdAt: _currentPlayer.createdAt,
                lastLoginAt: DateTime.now(),
              );
              await _dbService.updatePlayer(player);
              await _prefService.setCurrentPlayerId(player.id);
            } else {
              player = Player(
                id: const Uuid().v4(),
                username: username,
                totalGold: 5000,
                createdAt: DateTime.now(),
                lastLoginAt: DateTime.now(),
              );
              debugPrint('Saving player to database...');
              await _dbService.savePlayer(player);

              debugPrint('Setting preference...');
              await _prefService.setCurrentPlayerId(player.id);
            }

            debugPrint('Updating UI...');
            if (!mounted) return;
            setState(() {
              _currentPlayer = player;
              _isLoading = false;
            });
            debugPrint('UI updated successfully');
          } catch (e) {
            debugPrint('Error in username submission: $e');
            if (mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Hata: $e')));
            }
          }
        },
      ),
    );
  }

  void _changeUsername() {
    _showUsernameDialog(
      initialUsername: _currentPlayer.username,
      isEdit: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('Loading...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: GestureDetector(
          onTap: _changeUsername,
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.deepPurple.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                _currentPlayer.username[0].toUpperCase(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
            ),
          ),
        ),
        title: GestureDetector(
          onTap: _changeUsername,
          child: Text(
            _currentPlayer.username,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.15,
                  child: Center(
                    child: Text(
                      'WORD GAME V2',
                      style: Theme.of(context).textTheme.displayMedium
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                    ),
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.1),

                
                _buildMenuButton(
                  icon: Icons.play_circle,
                  title: 'Yeni Oyun',
                  subtitle: 'Yeni bir oyun başla',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          GameSetupScreen(player: _currentPlayer),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                
                _buildMenuButton(
                  icon: Icons.leaderboard,
                  title: 'Skor Tablosu',
                  subtitle: 'Performansını takip et',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ScoreBoardScreen(player: _currentPlayer),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

             
                _buildMenuButton(
                  icon: Icons.shopping_cart,
                  title: 'Market',
                  subtitle: 'Jokerler ve bonuslar',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          MarketScreen(player: _currentPlayer),
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

  Widget _buildMenuButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [Colors.deepPurple.shade400, Colors.deepPurple.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 48, color: Colors.white),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class UsernameDialog extends StatefulWidget {
  final Function(String) onUsernameSubmitted;
  final String? initialUsername;
  final bool isEdit;

  const UsernameDialog({
    super.key,
    required this.onUsernameSubmitted,
    this.initialUsername,
    this.isEdit = false,
  });

  @override
  State<UsernameDialog> createState() => _UsernameDialogState();
}

class _UsernameDialogState extends State<UsernameDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialUsername ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isEdit ? 'Kullanıcı Adını Değiştir' : 'Hoşgeldin!'),
      content: TextField(
        controller: _controller,
        decoration: InputDecoration(
          hintText: 'Kullanıcı adını gir',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () async {
            if (_controller.text.isNotEmpty) {
              await widget.onUsernameSubmitted(_controller.text);
            }
          },
          child: Text(widget.isEdit ? 'Güncelle' : 'Başla'),
        ),
      ],
    );
  }
}
