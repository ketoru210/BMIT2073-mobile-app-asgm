import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/grant_reminder.dart';
import '../models/sector.dart';
import 'grant_reminder_repository.dart';

/// Cloud implementation of grant reminders, stored in `grant_reminders`.
///
/// Reminders follow the account rather than the device, the same way
/// applications do, so signing in elsewhere keeps them.
class SupabaseGrantReminderRepository implements GrantReminderRepository {
  SupabaseGrantReminderRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const _table = 'grant_reminders';

  @override
  Future<List<GrantReminder>> active() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];
    final rows = await _client
        .from(_table)
        .select()
        .eq('user_id', user.id)
        .isFilter('fulfilled_at', null)
        .order('created_at', ascending: true);
    return rows.map((row) => GrantReminder.fromJson(_fromSupabase(row))).toList();
  }

  @override
  Future<GrantReminder?> find({
    required String state,
    required Sector sector,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    final row = await _client
        .from(_table)
        .select()
        .eq('user_id', user.id)
        .eq('state', state)
        .eq('sector', sector.name)
        .isFilter('fulfilled_at', null)
        .maybeSingle();
    return row == null ? null : GrantReminder.fromJson(_fromSupabase(row));
  }

  /// Upserts on the (user, state, sector) key so a repeated or re-armed
  /// reminder reuses its row. The creation time is reset because only
  /// grants published after it count, and the fulfilment columns are
  /// cleared so an old reminder that already fired starts waiting again.
  @override
  Future<GrantReminder> create({
    required String state,
    required Sector sector,
    bool includeAllStates = false,
    bool includeAllSectors = false,
    int? minAmountRm,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('You must be signed in to set a reminder.');
    }
    final row = await _client
        .from(_table)
        .upsert({
          'user_id': user.id,
          'state': state,
          'sector': sector.name,
          'include_all_states': includeAllStates,
          'include_all_sectors': includeAllSectors,
          'min_amount_rm': minAmountRm,
          'created_at': DateTime.now().toUtc().toIso8601String(),
          'fulfilled_at': null,
          'grant_id': null,
        }, onConflict: 'user_id,state,sector')
        .select()
        .single();
    return GrantReminder.fromJson(_fromSupabase(row));
  }

  @override
  Future<void> cancel(String id) async {
    await _client.from(_table).delete().eq('id', id);
  }

  @override
  Future<void> fulfil(String id, String grantId) async {
    await _client
        .from(_table)
        .update({
          'fulfilled_at': DateTime.now().toUtc().toIso8601String(),
          'grant_id': grantId,
        })
        .eq('id', id);
  }

  /// Postgres column names to the model's own keys.
  Map<String, dynamic> _fromSupabase(Map<String, dynamic> row) {
    return {
      'id': row['id'],
      'userId': row['user_id'],
      'state': row['state'],
      'sector': row['sector'],
      'includeAllStates': row['include_all_states'],
      'includeAllSectors': row['include_all_sectors'],
      'minAmountRm': row['min_amount_rm'],
      'createdAt': row['created_at'],
      'fulfilledAt': row['fulfilled_at'],
      'grantId': row['grant_id'],
    };
  }
}
