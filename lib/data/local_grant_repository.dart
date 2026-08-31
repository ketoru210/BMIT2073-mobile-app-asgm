import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/grant.dart';
import '../models/sector.dart';
import 'grant_admin_repository.dart';
import 'grant_repository.dart';

/// Offline stub of the grants backend, used until Supabase is wired in.
///
/// Both sides share one [LocalGrantStore], so publishing as admin and
/// applying as user hit the same data. Owned by A as part of the F2
/// contract handoff; C and B later add the Supabase implementations that
/// keep these interfaces.
class LocalGrantRepository implements GrantRepository {
  final LocalGrantStore _store = LocalGrantStore();

  @override
  Future<List<Grant>> available({String? state, Sector? sector}) async {
    final grants = await _store.loadGrants();
    return grants.where((g) {
      if (!g.isOpen) return false;
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
    apps.add(application);
    await _store.saveApplications(apps);
  }

  @override
  Future<List<GrantApplication>> myApplications() async {
    // A single offline user, so "mine" is every application. The Supabase
    // implementation narrows this to `user_id = auth.uid()`.
    return _store.loadApplications();
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
    final old = apps[i];
    apps[i] = GrantApplication(
      id: old.id,
      grantId: old.grantId,
      userId: old.userId,
      projectName: old.projectName,
      state: old.state,
      sector: old.sector,
      requestedAmountRm: old.requestedAmountRm,
      note: old.note,
      status: status,
      submittedAt: old.submittedAt,
      decidedAt: DateTime.now(),
    );
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

  Future<void> saveApplications(List<GrantApplication> apps) async {
    final p = await _prefs();
    final maps = apps.map((a) => a.toJson()).toList();
    await p.setString(_applicationsKey, jsonEncode(maps));
  }
}
