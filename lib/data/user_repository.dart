import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/saved_analysis.dart';

/// Stores the user's nickname and saved analyses in SharedPreferences.
///
/// The favourites list is a List of objects, so it is encoded to a JSON
/// string before being written — SharedPreferences only stores strings.
class UserRepository {
  static const _nicknameKey = 'user.nickname';
  static const _favoritesKey = 'user.favorites';

  SharedPreferences? _prefs;
  String? _nickname;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _nickname = _prefs!.getString(_nicknameKey);
  }

  String? get nickname => _nickname;

  Future<void> setNickname(String name) async {
    _nickname = name;
    await _prefs!.setString(_nicknameKey, name);
  }

  Future<List<SavedAnalysis>> favorites() async {
    final raw = _prefs!.getString(_favoritesKey);
    if (raw == null) return [];

    final list = jsonDecode(raw) as List<dynamic>;
    final result = <SavedAnalysis>[];
    for (final item in list) {
      result.add(SavedAnalysis.fromJson(item as Map<String, dynamic>));
    }
    return result;
  }

  Future<void> saveFavorite(SavedAnalysis analysis) async {
    final list = await favorites();
    list.removeWhere((a) => a.id == analysis.id);
    list.insert(0, analysis); // newest first
    await _persistFavorites(list);
  }

  Future<void> removeFavorite(String id) async {
    final list = await favorites();
    list.removeWhere((a) => a.id == id);
    await _persistFavorites(list);
  }

  Future<void> _persistFavorites(List<SavedAnalysis> list) async {
    final maps = <Map<String, dynamic>>[];
    for (final analysis in list) {
      maps.add(analysis.toJson());
    }
    await _prefs!.setString(_favoritesKey, jsonEncode(maps));
  }
}
