import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../models/models.dart';
import '../services/services.dart';

class MarketScreen extends StatefulWidget {
  final Player player;

  const MarketScreen({super.key, required this.player});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  late Player _player;
  final _dbService = DatabaseService();
  final _prefService = PreferenceService();
  late Map<String, int> _ownedJokers;

  static final List<JokerItem> _jokers = [
    JokerItem(
      key: 'fish',
      name: 'Balık',
      description:
          'Gridde rastgele birkaç harfi yok eder. Boşalan alanlara üstten yeni harf düşer.',
      fallbackIcon: Icons.set_meal,
      assetPath: 'assets/images/joker_fish.png',
      price: AppConstants.jokerFish,
      previewTitle: 'Rastgele harfleri kaldırır',
    ),
    JokerItem(
      key: 'wheel',
      name: 'Tekerlek',
      description: 'Seçilen harfin bulunduğu satır ve sütundaki tüm harfleri temizler.',
      fallbackIcon: Icons.adjust,
      assetPath: 'assets/images/joker_wheel.png',
      imagePadding: 0,
      imageAlignmentX: 0.45,
      imageSize: 56,
      price: AppConstants.jokerWheel,
      previewTitle: 'Seçilen hücrenin satır+sütunu temizlenir',
    ),
    JokerItem(
      key: 'lollipop',
      name: 'Lolipop Kırıcı',
      description: 'Seçilen tek bir harfi yok eder ve üstten harfler aşağı düşer.',
      fallbackIcon: Icons.icecream,
      assetPath: 'assets/images/joker_lollipop.png',
      price: AppConstants.jokerLollipop,
      previewTitle: 'Tek bir hücreyi hedefler',
    ),
    JokerItem(
      key: 'freeSwap',
      name: 'Serbest Değiştirme',
      description: 'Temas eden iki harfin yerini değiştirir.',
      fallbackIcon: Icons.back_hand,
      assetPath: 'assets/images/joker_swap.png',
      price: AppConstants.jokerFreeSwap,
      previewTitle: 'Komşu iki harfin yeri değişir',
    ),
    JokerItem(
      key: 'shuffle',
      name: 'Harf Karıştırma',
      description: 'Gridde bulunan harfleri rastgele karıştırır.',
      fallbackIcon: Icons.casino,
      assetPath: 'assets/images/joker_shuffle.png',
      price: AppConstants.jokerShuffle,
      previewTitle: 'Grid yeniden karıştırılır',
    ),
    JokerItem(
      key: 'party',
      name: 'Parti Güçlendiricisi',
      description: 'Tüm harfleri yok edip yeniden düzenler.',
      fallbackIcon: Icons.celebration,
      assetPath: 'assets/images/joker_party.png',
      price: AppConstants.jokerParty,
      previewTitle: 'Tüm grid sıfırlanır ve yeniden doldurulur',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _player = widget.player;
    _ownedJokers = _prefService.getOwnedJokers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Market v2')),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.amber.shade50,
              child: Row(
                children: [
                  const Icon(Icons.monetization_on, color: Colors.amber),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Altın Bakiyesi',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        '${_player.totalGold}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _jokers.length,
                itemBuilder: (context, index) => _buildJokerCard(_jokers[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJokerCard(JokerItem joker) {
    final ownedCount = _ownedJokers[joker.key] ?? 0;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.deepPurple.shade200,
                        Colors.deepPurple.shade400,
                      ],
                    ),
                  ),
                  child: Center(
                    child: ClipOval(
                      child: Padding(
                        padding: EdgeInsets.all(joker.imagePadding),
                        child: Image.asset(
                          joker.assetPath,
                          width: joker.imageSize,
                          height: joker.imageSize,
                          fit: BoxFit.contain,
                          alignment: Alignment(joker.imageAlignmentX, 0),
                          filterQuality: FilterQuality.high,
                          cacheWidth: 128,
                          cacheHeight: 128,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            joker.fallbackIcon,
                            size: 28,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        joker.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        joker.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Sahip olunan: $ownedCount',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.deepPurple,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.monetization_on,
                      size: 16,
                      color: Colors.amber,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${joker.price}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: () async => _buyJoker(joker),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                  ),
                  child: const Text(
                    'Satın Al',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _showJokerPreview(joker),
                icon: const Icon(Icons.visibility_outlined, size: 18),
                label: const Text('Nasıl çalışır?'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _buyJoker(JokerItem joker) async {
    if (_player.totalGold < joker.price) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Yetersiz altın!')));
      return;
    }

    setState(() {
      _player.totalGold -= joker.price;
      _ownedJokers[joker.key] = (_ownedJokers[joker.key] ?? 0) + 1;
    });

    await _dbService.updatePlayer(_player);
    await _prefService.setOwnedJokers(_ownedJokers);

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${joker.name} satın alındı!')));
  }

  void _showJokerPreview(JokerItem joker) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(joker.name),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(joker.description),
              const SizedBox(height: 12),
              Text(
                joker.previewTitle,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              _JokerPreviewPanel(jokerKey: joker.key),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }
}

class JokerItem {
  final String key;
  final String name;
  final String description;
  final String assetPath;
  final IconData fallbackIcon;
  final int price;
  final String previewTitle;
  final double imagePadding;
  final double imageAlignmentX;
  final double imageSize;

  JokerItem({
    required this.key,
    required this.name,
    required this.description,
    required this.assetPath,
    required this.fallbackIcon,
    required this.price,
    required this.previewTitle,
    this.imagePadding = 0,
    this.imageAlignmentX = 0,
    this.imageSize = 40,
  });
}

class _JokerPreviewPanel extends StatelessWidget {
  final String jokerKey;

  const _JokerPreviewPanel({required this.jokerKey});

  @override
  Widget build(BuildContext context) {
    final preview = _buildPreviewModel(jokerKey);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Expanded(
              child: Text(
                'Öncesi',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              ),
            ),
            Icon(Icons.arrow_forward, size: 18, color: Colors.black54),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Sonrası',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: _JokerPreviewGrid(
                letters: preview.beforeLetters,
                removed: preview.removedBefore,
                incoming: const {},
                swapped: preview.swapIndices,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _JokerPreviewGrid(
                letters: preview.afterLetters,
                removed: const {},
                incoming: preview.incomingAfter,
                swapped: preview.swapIndices,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Gösterim: Kırmızı=Silinir, Yeşil=Yeni harf, Mavi=Yer değiştirir',
          style: TextStyle(fontSize: 11, color: Colors.black54),
        ),
      ],
    );
  }
}

class _JokerPreviewGrid extends StatelessWidget {
  final List<String> letters;
  final Set<int> removed;
  final Set<int> incoming;
  final Set<int> swapped;

  const _JokerPreviewGrid({
    required this.letters,
    required this.removed,
    required this.incoming,
    required this.swapped,
  });

  @override
  Widget build(BuildContext context) {
    const size = 5;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: List.generate(size, (r) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(size, (c) {
              final index = r * size + c;
              final isIncoming = incoming.contains(index);
              final isRemoved = removed.contains(index);
              final isSwap = swapped.contains(index);
              final bgColor = isSwap
                  ? Colors.blue.shade300
                  : (isRemoved
                        ? Colors.deepOrange.shade300
                        : (isIncoming ? Colors.green.shade300 : Colors.white));
              final marker = letters[index];
              return Container(
                width: 22,
                height: 22,
                margin: const EdgeInsets.all(1.5),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Center(
                  child: Text(
                    marker,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: (isRemoved || isIncoming || isSwap)
                          ? Colors.white
                          : Colors.black87,
                    ),
                  ),
                ),
              );
            }),
          );
        }),
      ),
    );
  }
}

class _PreviewModel {
  final List<String> beforeLetters;
  final List<String> afterLetters;
  final Set<int> removedBefore;
  final Set<int> incomingAfter;
  final Set<int> swapIndices;

  _PreviewModel({
    required this.beforeLetters,
    required this.afterLetters,
    required this.removedBefore,
    required this.incomingAfter,
    required this.swapIndices,
  });
}

_PreviewModel _buildPreviewModel(String jokerKey) {
  const size = 5;
  final before = [
    'A', 'B', 'C', 'C', 'D',
    'E', 'F', 'G', 'G', 'H',
    'I', 'I', 'J', 'K', 'L',
    'M', 'N', 'O', 'O', 'P',
    'R', 'S', 'S', 'T', 'U',
  ];
  final after = [...before];
  final removed = <int>{};
  final incoming = <int>{};
  final swapped = <int>{};
  final refillQueue = ['E', 'A', 'R', 'I', 'L', 'N', 'T', 'S', 'M', 'K'];
  int refillCursor = 0;

  Set<int> toRemove = {};
  switch (jokerKey) {
    case 'lollipop':
      toRemove = {12};
      break;
    case 'wheel':
      toRemove = {
        for (int i = 0; i < size; i++) 2 * size + i,
        for (int i = 0; i < size; i++) i * size + 2,
      };
      break;
    case 'party':
      toRemove = {for (int i = 0; i < size * size; i++) i};
      break;
    case 'fish':
      toRemove = {1, 7, 12, 18, 23};
      break;
    case 'freeSwap':
      swapped.addAll({11, 12});
      final temp = after[11];
      after[11] = after[12];
      after[12] = temp;
      return _PreviewModel(
        beforeLetters: before,
        afterLetters: after,
        removedBefore: const {},
        incomingAfter: const {},
        swapIndices: swapped,
      );
    case 'shuffle':
      for (int i = 0; i < size * size; i++) {
        after[i] = before[(i * 7 + 3) % (size * size)];
      }
      return _PreviewModel(
        beforeLetters: before,
        afterLetters: after,
        removedBefore: const {},
        incomingAfter: const {},
        swapIndices: {for (int i = 0; i < size * size; i++) i},
      );
  }

  removed.addAll(toRemove);
  for (final index in toRemove) {
    after[index] = '';
  }

  for (int col = 0; col < size; col++) {
    final remaining = <String>[];
    for (int row = 0; row < size; row++) {
      final index = row * size + col;
      if (after[index].isNotEmpty) remaining.add(after[index]);
    }

    int row = size - 1;
    for (int i = remaining.length - 1; i >= 0; i--) {
      after[row * size + col] = remaining[i];
      row--;
    }
    while (row >= 0) {
      after[row * size + col] = refillQueue[refillCursor % refillQueue.length];
      incoming.add(row * size + col);
      refillCursor++;
      row--;
    }
  }

  return _PreviewModel(
    beforeLetters: before,
    afterLetters: after,
    removedBefore: removed,
    incomingAfter: incoming,
    swapIndices: swapped,
  );
}
