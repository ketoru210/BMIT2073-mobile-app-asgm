import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/grant.dart';
import '../models/saved_analysis.dart';

/// The user contract every implementation must satisfy.
///
/// [LocalUserRepository] runs fully offline; the Supabase implementation
/// swaps in later with the same shape. Grants code reads [role] and
/// [userId] from here, never from Supabase directly.
abstract class UserRepository {
  Future<void> init({bool useRemote = false});
  String? get nickname;
  Future<void> setNickname(String name);
  String? get userId;
  UserRole get role;
  Future<List<SavedAnalysis>> favorites();
  Future<void> saveFavorite(SavedAnalysis a);
  Future<void> removeFavorite(String id);
}

/// Offline implementation backed by SharedPreferences.
///
/// Favourites are a List of objects, so they are encoded to a JSON string
/// before being written — SharedPreferences only stores strings.
class LocalUserRepository implements UserRepository {
  static const _nicknameKey = 'user.nickname';
  static const _favoritesKey = 'user.favorites';
  static const _roleKey = 'user.role';

  /// A stable synthetic id for the single offline user. Grants and
  /// applications are keyed to it locally; the Supabase implementation
  /// replaces it with the real `auth.uid()`.
  static const localUserId = 'local';

  SharedPreferences? _prefs;
  String? _nickname;
  UserRole _role = UserRole.user;

  @override
  Future<void> init({bool useRemote = false}) async {
    _prefs = await SharedPreferences.getInstance();
    _nickname = _prefs!.getString(_nicknameKey);
    final storedRole = _prefs!.getString(_roleKey);
    _role = storedRole == null
        ? UserRole.user
        : UserRole.values.byName(storedRole);
  }

  @override
  String? get nickname => _nickname;

  @override
  String? get userId => localUserId;

  @override
  UserRole get role => _role;

  /// Debug-only role switch so the grants flow can be exercised as both
  /// user and admin without a login. Once the Supabase implementation is
  /// in, the real `role` column replaces this.
  Future<void> setFakeRole(UserRole role) async {
    _role = role;
    await _prefs!.setString(_roleKey, role.name);
  }

  @override
  Future<void> setNickname(String name) async {
    _nickname = name;
    await _prefs!.setString(_nicknameKey, name);
  }

  @override
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

  @override
  Future<void> saveFavorite(SavedAnalysis analysis) async {
    final list = await favorites();
    list.removeWhere((a) => a.id == analysis.id);
    list.insert(0, analysis); // newest first
    await _persistFavorites(list);
  }

  @override
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
