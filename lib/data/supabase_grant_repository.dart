import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/grant.dart';
import '../models/sector.dart';
import 'grant_repository.dart';

/// Cloud implementation of the user-facing grants surface.
///
/// Replaces [LocalGrantRepository] so that the grants an administrator
/// publishes and the applications a user submits live in the same place.
/// With the two sides on different stores the approval loop could never
/// close: a published grant was invisible to users, and an application was
/// invisible to the administrator.
class SupabaseGrantRepository implements GrantRepository {
  SupabaseGrantRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  /// Open, in-date grants, narrowed the same way the offline stub narrows
  /// them.
  ///
  /// `is_open` and the deadline are filtered server-side because they hold
  /// for every caller. The state and sector rules stay in Dart: a grant
  /// whose own column is null is unrestricted on that axis, which PostgREST
  /// can only express as a second `or` group that would collide with the
  /// first. Fetching a few extra rows is cheaper than the two
  /// implementations disagreeing about who may apply.
  @override
  Future<List<Grant>> available({String? state, Sector? sector}) async {
    final rows = await _client
        .from('grants')
        .select()
        .eq('is_open', true)
        .gte('deadline', DateTime.now().toIso8601String())
        .order('deadline', ascending: true);
    return rows.map((row) => Grant.fromJson(_grantFromSupabase(row))).where((
      grant,
    ) {
      if (state != null && grant.state != null && grant.state != state) {
        return false;
      }
      if (sector != null && grant.sector != null && grant.sector != sector) {
        return false;
      }
      return true;
    }).toList();
  }

  /// Submits [application] for the signed-in user.
  ///
  /// The id, the status and the submission time are left to the server so a
  /// client cannot post an application that is already approved.
  @override
  Future<void> apply(GrantApplication application) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('You must be signed in to apply for a grant.');
    }
    await _client.from('applications').insert({
      'grant_id': application.grantId,
      'user_id': user.id,
      'project_name': application.projectName,
      'state': application.state,
      'sector': application.sector.name,
      'requested_amount_rm': application.requestedAmountRm,
      'note': application.note,
      'status': ApplicationStatus.pending.name,
    });
  }

  @override
  Future<List<GrantApplication>> myApplications() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];
    final rows = await _client
        .from('applications')
        .select()
        .eq('user_id', user.id)
        .order('submitted_at', ascending: false);
    return rows
        .map((row) => GrantApplication.fromJson(_applicationFromSupabase(row)))
        .toList();
  }

  /// Postgres column names to the model's own keys.
  ///
  /// `published_at` is written by a column default rather than by the
  /// publish form, so an older row may not carry one; the deadline is used
  /// as the last resort so the record still parses.
  Map<String, dynamic> _grantFromSupabase(Map<String, dynamic> row) {
    return {
      'id': row['id'],
      'name': row['name'],
      'agency': row['agency'],
      'state': row['state'],
      'sector': row['sector'],
      'maxAmountRm': row['max_amount_rm'],
      'deadline': row['deadline'],
      'sourceUrl': row['source_url'],
      'criteriaNote': row['criteria_note'],
      'description': row['description'],
      'publishedBy': row['published_by'],
      'publishedAt':
          row['published_at'] ?? row['created_at'] ?? row['deadline'],
      'isOpen': row['is_open'],
    };
  }

  Map<String, dynamic> _applicationFromSupabase(Map<String, dynamic> row) {
    return {
      'id': row['id'],
      'grantId': row['grant_id'],
      'userId': row['user_id'],
      'projectName': row['project_name'],
      'state': row['state'],
      'sector': row['sector'],
      'requestedAmountRm': row['requested_amount_rm'],
      'note': row['note'],
      'status': row['status'],
      'submittedAt': row['submitted_at'],
      'decidedAt': row['decided_at'],
    };
  }
}
