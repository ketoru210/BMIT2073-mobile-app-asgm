import '../models/grant.dart';
import '../models/sector.dart';

/// User-facing grants surface (owned by C).
///
/// [available] lists grants that match the current analysis context.
/// A `null` argument means "don't filter on this axis"; a grant whose own
/// field is `null` is unrestricted there, so it still matches.
abstract class GrantRepository {
  Future<List<Grant>> available({String? state, Sector? sector});
  Future<void> apply(GrantApplication application);
  Future<List<GrantApplication>> myApplications();
}
