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
