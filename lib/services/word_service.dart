import 'dart:convert';
import 'package:flutter/services.dart';
import '../constants/app_constants.dart';

class WordService {
  static final WordService _instance = WordService._internal();

  late Set<String> _dictionary;
  late Set<String> _prefixes;
  late int _maxWordLength;
  bool _isInitialized = false;

  factory WordService() {
    return _instance;
  }

  WordService._internal();

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
    
      final jsonString = await rootBundle.loadString(
        'assets/words/turkish_dictionary.json',
      );
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      final words = jsonData['words'] as List<dynamic>;
      final cleaned = _sanitizeDictionary(words);
      _dictionary = {..._seedDictionary, ..._selectGameWords(cleaned)};
    } catch (e) {
      _dictionary = {..._seedDictionary};
    }
    _buildPrefixIndex();
    _isInitialized = true;
  }

  static final Set<String> _seedDictionary = {
    'ADA',
    'ADANA',
    'ADAM',
    'AİLE',
    'AKIL',
    'ALAN',
    'ALEV',
    'ANNE',
    'ARABA',
    'ARI',
    'ARSA',
    'ASLAN',
    'AYNA',
    'BAL',
    'BALIK',
    'BASAR',
    'BEBEK',
    'BİLGİ',
    'BINA',
    'BIRIM',
    'BULUT',
    'CAN',
    'ÇİÇEK',
    'CUMA',
    'DANA',
    'DENİZ',
    'DERE',
    'DİL',
    'DOST',
    'DUVAR',
    'ELMA',
    'EMEK',
    'ERİK',
    'FENER',
    'GEMI',
    'GECE',
    'GOL',
    'GüL',
    'HANE',
    'HARF',
    'HAYAT',
    'IRMAK',
    'IŞIK',
    'iSTEK',
    'KAPI',
    'KAR',
    'KART',
    'KASE',
    'KEDİ',
    'KELİME',
    'KISA',
    'KIS',
    'KİTAP',
    'KONU',
    'KÖSE',
    'KÖY',
    'KUM',
    'KUS',
    'LALE',
    'LİMAN',
    'MASA',
    'MASAL',
    'MAVI',
    'MEYVE',
    'OKUL',
    'ORMAN',
    'OYUN',
    'PAZAR',
    'PENCERE',
    'RENK',
    'RESİM',
    'RÜZGAR',
    'SAAT',
    'SABAH',
    'SARI',
    'ŞEHİR',
    'ŞEKER',
    'SES',
    'ŞİİR',
    'SINIF',
    'SOKAK',
    'SORU',
    'SU',
    'TABAK',
    'TARLA',
    'TATİL',
    'TEKER',
    'TEMİZ',
    'TOP',
    'TOPRAK',
    'UZAY',
    'UZUM',
    'VAKİT',
    'YAZ',
    'YAZI',
    'YELKEN',
    'YEMEK',
    'YOL',
    'YON',
    'YORUM',
    'YUVA',
    'ZAMAN',
    'ZEKA',
    'SAL',
    'KEL',
    'VARİL',
    'KALEM',
    'KALEMİ',
    'KALEMLER',
    'PATİKA',
    'YILDIZ',
    'ŞEMSİYE',
    'TABLO',
    'MÜHENDİS',
    'BİLGİSAYAR',
    'SALATA',
    'SANDIK',
    'SEPET',
    'SERGİ',
    'SOKAĞI',
    'KARPÜZ',
    'PORTAKAL',
    'DOMATES',
    'PATATES',
    'KABAK',
    'KASABA',
    'MERDİVEN',
    'MANZARA',
    'BALKON',
    'MİSAFİR',
    'KAHVALTI',
    'KAHVE',
    'SÜTLAÇ',
    'SIMIT',
    'PEYNİR',
    'ZEYTİN',
    'YASTIK',
    'YORGAN',
    'ÇANTA',
    'KAŞIK',
    'ÇATAL',
    'BIÇAK',
    'TABAKA',
    'KAPLAN',
    'KARGA',
    'SERÇE',
    'KARTAL',
    'TİLKİ',
    'ZÜRAFA',
    'PANTER',
    'MAYDANOZ',
    'FISTIK',
    'FINDIK',
    'BAHARAT',
    'ZENCEFİL',
    'MISIR',
    'PİLAV',
    'ÇORBA',
    'YUMURTA',
    'MANTAR',
    'KAVUN',
    'LİMON',
    'NARİN',
    'NANE',
    'REYHAN',
    'HAMBURGER',
    'KELİMELER',
    'SORULAR',
    'OYUNLAR',
    'BULMACA',
    'STRATEJİ',
    'AKTİF',
    'PASİF',
    'SEVİYE',
    'HAMLE',
    'PUANLAR',
    'JOKER',
    'MARKET',
    'TABLOSU',
    'ORTALAMA',
    'YÜKSEK',
  };

  Set<String> _sanitizeDictionary(List<dynamic> rawWords) {
    final validChars = RegExp(r'^[ABCÇDEFGĞHIİJKLMNOÖPRSŞTUÜVYZ]+$');
    final hasVowel = RegExp(r'[AEIİOÖUÜ]');
    final fourConsonants = RegExp(r'[^AEIİOÖUÜ]{4,}');
    const blockedEndings = <String>{
      'DA',
      'DE',
      'TA',
      'TE',
      'DAN',
      'DEN',
      'TAN',
      'TEN',
      'DIR',
      'DİR',
      'DUR',
      'DÜR',
      'TIR',
      'TİR',
      'TUR',
      'TÜR',
      'MİŞ',
      'MIŞ',
      'MUŞ',
      'MÜŞ',
      'LAR',
      'LER',
    };
    final cleaned = <String>{};

    for (final raw in rawWords) {
      if (raw is! String) continue;
      final word = _normalizeWord(raw.trim());
      if (word.length < 3 || word.length > 10) continue;
      if (!validChars.hasMatch(word)) continue;
      if (!hasVowel.hasMatch(word)) continue;
      if (fourConsonants.hasMatch(word)) continue;
      if (_hasTooManyRepeatedChars(word)) continue;
      if (blockedEndings.any(word.endsWith) && word.length >= 5) continue;
      cleaned.add(word);
    }
    return cleaned;
  }

  Set<String> _selectGameWords(Set<String> cleaned) {
    final all = cleaned.toList()..sort();
    final short = <String>[];
    final medium = <String>[];
    final long = <String>[];

    for (final w in all) {
      if (w.length <= 4) {
        short.add(w);
      } else if (w.length <= 7) {
        medium.add(w);
      } else {
        long.add(w);
      }
    }

    final selected = <String>{
      ...medium.take(1800),
      ...short.take(700),
      ...long.take(500),
    };
    return selected;
  }

  bool _hasTooManyRepeatedChars(String word) {
    int streak = 1;
    for (int i = 1; i < word.length; i++) {
      if (word[i] == word[i - 1]) {
        streak++;
        if (streak >= 3) return true;
      } else {
        streak = 1;
      }
    }
    return false;
  }

  void _buildPrefixIndex() {
    _prefixes = <String>{};
    _maxWordLength = 0;
    for (final word in _dictionary) {
      if (word.length > _maxWordLength) {
        _maxWordLength = word.length;
      }
      for (int i = 1; i <= word.length; i++) {
        _prefixes.add(word.substring(0, i));
      }
    }
  }

  bool isValidWord(String word) {
    if (!_isInitialized) return false;
    return _dictionary.contains(_normalizeWord(word));
  }

  bool isPrefix(String value) {
    if (!_isInitialized) return false;
    return _prefixes.contains(_normalizeWord(value));
  }

  Set<String> getDictionary() => _dictionary;
  int getDictionarySize() => _dictionary.length;
  int getMaxWordLength() => _maxWordLength;

  
  int calculateWordScore(String word) {
    int score = 0;
    for (String char in _normalizeWord(word).split('')) {
      score += AppConstants.letterScores[char] ?? 0;
    }
    return score;
  }


  ComboResult calculateCombo(String mainWord) {
    mainWord = _normalizeWord(mainWord);

    if (!isValidWord(mainWord)) {
      return ComboResult(mainWord: mainWord, foundWords: [], totalScore: 0);
    }

    Set<String> foundWords = {mainWord};
    int totalScore = calculateWordScore(mainWord);

    
    for (int i = 0; i < mainWord.length; i++) {
      for (int j = i + 3; j <= mainWord.length; j++) {
        String subWord = mainWord.substring(i, j);
        if (isValidWord(subWord) && !foundWords.contains(subWord)) {
          foundWords.add(subWord);
          totalScore += calculateWordScore(subWord);
        }
      }
    }

    return ComboResult(
      mainWord: mainWord,
      foundWords: foundWords.toList(),
      totalScore: totalScore,
    );
  }

  
  SpecialPower? getSpecialPower(int wordLength) {
    if (wordLength == 4) return SpecialPower.lineClean;
    if (wordLength == 5) return SpecialPower.areaBomb;
    if (wordLength == 6) return SpecialPower.columnClean;
    if (wordLength >= 7) return SpecialPower.megaBomb;
    return null;
  }

  
  String getSpecialPowerDescription(SpecialPower power) {
    switch (power) {
      case SpecialPower.lineClean:
        return '⇆ Satır Temizleme';
      case SpecialPower.areaBomb:
        return '✹ Alan Patlatma';
      case SpecialPower.columnClean:
        return '⇅ Sütun Temizleme';
      case SpecialPower.megaBomb:
        return '✪ Mega Patlatma';
    }
  }

  String _normalizeWord(String input) {
    return input
        .trim()
        .replaceAll('i', 'İ')
        .replaceAll('ı', 'I')
        .toUpperCase();
  }
}

class ComboResult {
  final String mainWord;
  final List<String> foundWords;
  final int totalScore;

  ComboResult({
    required this.mainWord,
    required this.foundWords,
    required this.totalScore,
  });
}

enum SpecialPower { lineClean, areaBomb, columnClean, megaBomb }
