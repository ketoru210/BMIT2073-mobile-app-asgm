import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/grant.dart';
import '../models/sector.dart';
import 'grant_admin_repository.dart';
import 'grant_repository.dart';
import 'user_repository.dart';

/// Offline stub of the grants backend, used until Supabase is wired in.
///
/// The user and admin sides each hold their own [LocalGrantStore], but both
/// read and write the same SharedPreferences keys — so publishing as admin
/// and applying as user still hit the same data. Owned by A as part of the
/// F2 contract handoff; C and B later add the Supabase implementations that
/// keep these interfaces.
class LocalGrantRepository implements GrantRepository {
  final LocalGrantStore _store = LocalGrantStore();

  @override
  Future<List<Grant>> available({String? state, Sector? sector}) async {
    final grants = await _store.loadGrants();
    final now = DateTime.now();
    return grants.where((g) {
      if (!g.isOpen) return false;
      if (g.deadline.isBefore(now)) return false;
      if (state != null && g.state != null && g.state != state) return false;
      if (sector != null && g.sector != null && g.sector != sector) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Future<void> apply(GrantApplication application) async {
    final apps = await _store.loadApplications();
    apps.add(application.copyWith(id: _store.newId()));
    await _store.saveApplications(apps);
  }

  @override
  Future<List<GrantApplication>> myApplications() async {
    final apps = await _store.loadApplications();
    // Filtered even though the offline user is the only one, so that
    // swapping in the Supabase implementation (where RLS does this) does
    // not change what the screen shows.
    final mine = apps
        .where((a) => a.userId == LocalUserRepository.localUserId)
        .toList();
    mine.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
    return mine;
  }
}

/// Local admin side: publish grants and decide applications.
class LocalGrantAdminRepository implements GrantAdminRepository {
  final LocalGrantStore _store = LocalGrantStore();

  @override
  Future<void> publish(Grant grant) async {
    final grants = await _store.loadGrants();
    grants.removeWhere((g) => g.id == grant.id);
    grants.add(grant);
    await _store.saveGrants(grants);
  }

  @override
  Future<List<GrantApplication>> pending() async {
    final apps = await _store.loadApplications();
    return apps.where((a) => a.status == ApplicationStatus.pending).toList();
  }

  @override
  Future<void> decide(String applicationId, ApplicationStatus status) async {
    final apps = await _store.loadApplications();
    final i = apps.indexWhere((a) => a.id == applicationId);
    if (i == -1) return;
    apps[i] = apps[i].copyWith(status: status, decidedAt: DateTime.now());
    await _store.saveApplications(apps);
  }
}

/// Shared backing store for the local grants stub.
///
/// Grants are seeded from assets/grants_seed.json on first run, then
/// published grants and applications persist in SharedPreferences so the
/// publish → apply → decide loop survives restarts.
class LocalGrantStore {
  static const _grantsKey = 'grant.grants';
  static const _applicationsKey = 'grant.applications';
  static const _seededKey = 'grant.seeded';

  final Random _random = Random();

  SharedPreferences? _cache;

  Future<SharedPreferences> _prefs() async {
    final cached = _cache;
    if (cached != null) return cached;
    final fresh = await SharedPreferences.getInstance();
    _cache = fresh;
    return fresh;
  }

  Future<List<Grant>> loadGrants() async {
    final p = await _prefs();
    if (!(p.getBool(_seededKey) ?? false)) {
      await _seed(p);
    }
    final raw = p.getString(_grantsKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.cast<Map<String, dynamic>>().map(Grant.fromJson).toList();
  }

  Future<void> saveGrants(List<Grant> grants) async {
    final p = await _prefs();
    final maps = grants.map((g) => g.toJson()).toList();
    await p.setString(_grantsKey, jsonEncode(maps));
  }

  Future<void> _seed(SharedPreferences p) async {
    final raw = await rootBundle.loadString('assets/grants_seed.json');
    final list = jsonDecode(raw) as List<dynamic>;
    await p.setString(_grantsKey, jsonEncode(list));
    await p.setBool(_seededKey, true);
  }

  Future<List<GrantApplication>> loadApplications() async {
    final p = await _prefs();
    final raw = p.getString(_applicationsKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .cast<Map<String, dynamic>>()
        .map(GrantApplication.fromJson)
        .toList();
  }

  /// Ids are assigned here rather than by the form, mirroring Supabase's
  /// server-side default. Time-ordered prefix plus randomness, so ids stay
  /// unique even when two applications are submitted in the same tick.
  String newId() {
    final stamp = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
    final noise = _random.nextInt(0xffffff).toRadixString(16).padLeft(6, '0');
    return '$stamp-$noise';
  }

  Future<void> saveApplications(List<GrantApplication> apps) async {
    final p = await _prefs();
    final maps = apps.map((a) => a.toJson()).toList();
    await p.setString(_applicationsKey, jsonEncode(maps));
  }
}
