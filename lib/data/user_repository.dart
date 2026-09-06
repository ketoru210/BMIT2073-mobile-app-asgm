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
  List<SavedAnalysis> _favorites = [];

  @override
  Future<void> init({bool useRemote = false}) async {
    _prefs ??= await SharedPreferences.getInstance();
    _nickname = _prefs!.getString(_nicknameKey);
    final roleName = _prefs!.getString(_roleKey);
    if (roleName != null) {
      _role = UserRole.values.firstWhere(
        (role) => role.name == roleName,
        orElse: () => UserRole.user,
      );
    }
    final rawFavorites = _prefs!.getString(_favoritesKey);
    if (rawFavorites == null || rawFavorites.isEmpty) {
      _favorites = [];
      return;
    }
    try {
      final decoded = jsonDecode(rawFavorites);
      if (decoded is! List) {
        _favorites = [];
        return;
      }
      _favorites = decoded.whereType<Map>().map(
          (item) => SavedAnalysis.fromJson(
          Map<String, dynamic>.from(item),
        )
      ).toList();
    } catch (_) {
      _favorites = [];
    }
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
    final value = name.trim();
    if (value.isEmpty) throw ArgumentError('Nickname cannot be empty.');
    _nickname = value;
    await _prefs!.setString(_nicknameKey, name);
  }

  @override
  Future<List<SavedAnalysis>> favorites() async {
    return List<SavedAnalysis>.unmodifiable(_favorites);
  }

  @override
  Future<void> saveFavorite(SavedAnalysis analysis) async {
    final index = _favorites.indexWhere((item) => item.id == analysis.id);
    if (index >= 0) {
      _favorites[index] = analysis;
    } else {
      _favorites.insert(0, analysis);
    }
    await _saveFavorites();
  }

  @override
  Future<void> removeFavorite(String id) async {
    _favorites.removeWhere((item) => item.id == id);
    await _saveFavorites();
  }

  Future<void> _saveFavorites() async {
    final encoded = jsonEncode(
      _favorites.map((item) => item.toJson()).toList(),
    );
    await _prefs?.setString(_favoritesKey, encoded);
  }
}
