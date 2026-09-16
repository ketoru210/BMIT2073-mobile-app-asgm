import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/grant_reminder.dart';
import '../models/sector.dart';
import 'grant_reminder_repository.dart';
import 'user_repository.dart';

/// Offline grant reminders backed by SharedPreferences.
///
/// Keeps the same contract as the Supabase implementation so the tests
/// and the offline build exercise the real set, restart and fulfil rules.
class LocalGrantReminderRepository implements GrantReminderRepository {
  static const _key = 'grant.reminders';

  SharedPreferences? _cache;

  Future<SharedPreferences> _prefs() async {
    return _cache ??= await SharedPreferences.getInstance();
  }

  Future<List<GrantReminder>> _load() async {
    final raw = (await _prefs()).getString(_key);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.cast<Map<String, dynamic>>().map(GrantReminder.fromJson).toList();
  }

  Future<void> _save(List<GrantReminder> reminders) async {
    final maps = reminders.map((r) => r.toJson()).toList();
    await (await _prefs()).setString(_key, jsonEncode(maps));
  }

  @override
  Future<List<GrantReminder>> active() async {
    final all = await _load();
    return all.where((r) => r.isActive).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  @override
  Future<GrantReminder?> find({
    required String state,
    required Sector sector,
  }) async {
    for (final reminder in await active()) {
      if (reminder.state == state && reminder.sector == sector) {
        return reminder;
      }
    }
    return null;
  }

  /// Replaces any row for the same pair, mirroring the Supabase upsert on
  /// (user, state, sector).
  @override
  Future<GrantReminder> create({
    required String state,
    required Sector sector,
    bool includeAllStates = false,
    bool includeAllSectors = false,
    int? minAmountRm,
  }) async {
    final all = await _load();
    all.removeWhere((r) => r.state == state && r.sector == sector);
    final now = DateTime.now();
    final reminder = GrantReminder(
      id: now.microsecondsSinceEpoch.toRadixString(16),
      userId: LocalUserRepository.localUserId,
      state: state,
      sector: sector,
      includeAllStates: includeAllStates,
      includeAllSectors: includeAllSectors,
      minAmountRm: minAmountRm,
      createdAt: now,
      fulfilledAt: null,
      grantId: null,
    );
    all.add(reminder);
    await _save(all);
    return reminder;
  }

  @override
  Future<void> cancel(String id) async {
    final all = await _load();
    all.removeWhere((r) => r.id == id);
    await _save(all);
  }

  @override
  Future<void> fulfil(String id, String grantId) async {
    final all = await _load();
    final i = all.indexWhere((r) => r.id == id);
    if (i == -1) return;
    final old = all[i];
    all[i] = GrantReminder(
      id: old.id,
      userId: old.userId,
      state: old.state,
      sector: old.sector,
      includeAllStates: old.includeAllStates,
      includeAllSectors: old.includeAllSectors,
      minAmountRm: old.minAmountRm,
      createdAt: old.createdAt,
      fulfilledAt: DateTime.now(),
      grantId: grantId,
    );
    await _save(all);
  }
}
