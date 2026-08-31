import '../models/grant.dart';
import '../models/sector.dart';

/// User-facing grants surface (owned by C).
abstract class GrantRepository {
  /// Grants a user may still apply to, narrowed to the analysis context.
  ///
  /// A `null` argument means "don't filter on this axis"; a grant whose own
  /// field is `null` is unrestricted there, so it still matches. Closed
  /// grants and grants past their deadline are never returned — that rule
  /// lives here so the user and admin sides cannot disagree about it.
  Future<List<Grant>> available({String? state, Sector? sector});

  /// Submits an application built with [GrantApplication.draft].
  ///
  /// The repository assigns the id, as Supabase does server-side; whatever
  /// id the caller sets is ignored.
  Future<void> apply(GrantApplication application);

  /// The signed-in user's own applications, newest first.
  Future<List<GrantApplication>> myApplications();
}
