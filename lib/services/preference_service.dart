import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PreferenceService {
  static final PreferenceService _instance = PreferenceService._internal();
  static SharedPreferences? _prefs;

  factory PreferenceService() {
    return _instance;
  }

  PreferenceService._internal();

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  
  Future<void> setCurrentPlayerId(String playerId) async {
    await _prefs?.setString('current_player_id', playerId);
  }

  String? getCurrentPlayerId() {
    return _prefs?.getString('current_player_id');
  }

  Future<void> clearCurrentPlayer() async {
    await _prefs?.remove('current_player_id');
  }

 
  Future<void> setSoundEnabled(bool enabled) async {
    await _prefs?.setBool('sound_enabled', enabled);
  }

  bool isSoundEnabled() {
    return _prefs?.getBool('sound_enabled') ?? true;
  }

  
  Future<void> setMusicEnabled(bool enabled) async {
    await _prefs?.setBool('music_enabled', enabled);
  }

  bool isMusicEnabled() {
    return _prefs?.getBool('music_enabled') ?? true;
  }

  
  Future<void> setDarkMode(bool enabled) async {
    await _prefs?.setBool('dark_mode', enabled);
  }

  bool isDarkMode() {
    return _prefs?.getBool('dark_mode') ?? false;
  }

  
  Future<void> setLanguage(String language) async {
    await _prefs?.setString('language', language);
  }

  String getLanguage() {
    return _prefs?.getString('language') ?? 'tr';
  }

  
  Future<void> setOwnedJokers(Map<String, int> jokers) async {
    await _prefs?.setString('owned_jokers', jsonEncode(jokers));
  }

  Map<String, int> getOwnedJokers() {
    final raw = _prefs?.getString('owned_jokers');
    if (raw == null || raw.isEmpty) {
      return {
        'fish': 0,
        'wheel': 0,
        'lollipop': 0,
        'freeSwap': 0,
        'shuffle': 0,
        'party': 0,
      };
    }

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((key, value) => MapEntry(key, (value as num).toInt()));
    } catch (_) {
      return {
        'fish': 0,
        'wheel': 0,
        'lollipop': 0,
        'freeSwap': 0,
        'shuffle': 0,
        'party': 0,
      };
    }
  }
}
