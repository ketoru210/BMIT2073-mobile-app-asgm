import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/saved_analysis.dart';
import '../models/grant.dart';
import 'user_repository.dart';

class SupabaseUserRepository implements UserRepository {
  SupabaseUserRepository({SupabaseClient? client,})
      : _client = client ?? Supabase.instance.client;
  final SupabaseClient _client;
  String? _nickname;
  UserRole _role = UserRole.user;

  @override
  Future<void> init({bool useRemote = false}) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      _nickname = null;
      _role = UserRole.user;
      return;
    }
    await _loadProfile(user.id);
  }

  Future<void> _loadProfile(String id) async {
    final response = await _client
        .from('profiles')
        .select('nickname, role')
        .eq('id', id)
        .maybeSingle();
    if (response == null) {
      _nickname = null;
      _role = UserRole.user;
      return;
    }
    _nickname = response['nickname'] as String?;
    final roleName = response['role'] as String?;
    _role = UserRole.values.firstWhere(
          (role) => role.name == roleName,
      orElse: () => UserRole.user,
    );
  }

  @override
  String? get nickname => _nickname;

  @override
  Future<void> setNickname(String name) async {
    final value = name.trim();
    if (value.isEmpty) throw ArgumentError('Nickname cannot be empty.');
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('No authenticated user.');
    await _client.rpc(
      'set_nickname',
      params: {
        'new_nickname': value,
      },
    );
    _nickname = value;
  }

  @override
  String? get userId => _client.auth.currentUser?.id;

  @override
  UserRole get role => _role;

  @override
  Future<List<SavedAnalysis>> favorites() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];
    final response = await _client
        .from('favorites')
        .select('id, payload, created_at')
        .eq('user_id', user.id)
        .order('created_at', ascending: false);
    return response.map<SavedAnalysis>((row) {
      final payload = Map<String, dynamic>.from(
        row['payload'] as Map,
      );
      return SavedAnalysis.fromJson(payload);
    }).toList();
  }

  @override
  Future<void> saveFavorite(SavedAnalysis analysis) async {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('You must be signed in to save favorites.');
    await _client.from('favorites').upsert(
      {
        'id': analysis.id,
        'user_id': user.id,
        'payload': analysis.toJson(),
      },
      onConflict: 'user_id,id',
    );
  }

  @override
  Future<void> removeFavorite(String id) async {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('You must be signed in to remove favorites.');
    await _client
        .from('favorites')
        .delete()
        .eq('user_id', user.id)
        .eq('id', id);
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    final user = response.user;
    if (user != null) await _loadProfile(user.id);
    return response;
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String nickname,
  }) async {
    final response = await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {
        'nickname': nickname.trim(),
      },
    );
    final user = response.user;
    if (user != null) {
      _nickname = nickname.trim();
      if (response.session != null) {
        await _loadProfile(user.id);
      }
    }
    return response;
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
    _nickname = null;
    _role = UserRole.user;
  }

  bool get isSignedIn => _client.auth.currentUser != null;

  String? get email => _client.auth.currentUser?.email;

  User? get currentUser => _client.auth.currentUser;
}