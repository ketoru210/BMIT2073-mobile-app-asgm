import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/grant.dart';

/// Admin-facing grants surface (owned by B).
///
/// Permission is enforced server-side by RLS; these methods assume the
/// caller is already an admin. The client only uses role to hide UI.
abstract class GrantAdminRepository {
  Future<void> publish(Grant grant);

  /// Every application still awaiting a decision, across all users.
  Future<List<GrantApplication>> pending();

  Future<void> decide(String applicationId, ApplicationStatus status);
}

/// Supabase implementation of the admin-facing grants surface.
class SupabaseGrantAdminRepository implements GrantAdminRepository {
  SupabaseGrantAdminRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;
  final SupabaseClient _client;

  @override
  Future<void> publish(Grant grant) async {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('You must be signed in to publish a grant.');
    await _client.from('grants').insert({
      'id': grant.id,
      'name': grant.name,
      'agency': grant.agency,
      'state': grant.state,
      'sector': grant.sector?.name,
      'max_amount_rm': grant.maxAmountRm,
      'deadline': grant.deadline.toIso8601String(),
      'source_url': grant.sourceUrl,
      'criteria_note': grant.criteriaNote,
      'description': grant.description,
      'published_by': user.id,
      'is_open': grant.isOpen,
    });
  }

  @override
  Future<List<GrantApplication>> pending() async {
    final rows = await _client
        .from('applications')
        .select('*, grants(name)')
        .eq('status', ApplicationStatus.pending.name)
        .order('submitted_at', ascending: true);
    return rows
        .map(
          (row) => GrantApplication.fromJson(_applicationFromSupabase(row),
        ),
    ).toList();
  }

  @override
  Future<void> decide(String applicationId, ApplicationStatus status) async {
    if (status == ApplicationStatus.pending) throw ArgumentError('An application decision cannot be pending.');
    await _client.from('applications').update({
      'status': status.name,
      'decided_at': DateTime.now().toIso8601String(),
    }).eq('id', applicationId);
  }

  Map<String, dynamic> _applicationFromSupabase(Map<String, dynamic> row,) {
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