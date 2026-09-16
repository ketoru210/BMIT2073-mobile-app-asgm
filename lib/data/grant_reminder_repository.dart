import '../models/grant_reminder.dart';
import '../models/sector.dart';

/// Grant reminders for the signed-in user (owned by C).
///
/// Every method acts on the current user only: a signed-out caller reads
/// nothing and cannot write. Whether a grant satisfies a reminder is not
/// decided here — that rule lives in [GrantReminder.matches].
abstract class GrantReminderRepository {
  /// Reminders still waiting for a matching grant, oldest first.
  Future<List<GrantReminder>> active();

  /// The waiting reminder for [state] and [sector], or `null` if none.
  Future<GrantReminder?> find({required String state, required Sector sector});

  /// Starts waiting for [state] and [sector] with the given options.
  ///
  /// Setting a pair that already has a reminder restarts it with the new
  /// options rather than adding a second one — including a pair whose
  /// earlier reminder fired.
  Future<GrantReminder> create({
    required String state,
    required Sector sector,
    bool includeAllStates = false,
    bool includeAllSectors = false,
    int? minAmountRm,
  });

  Future<void> cancel(String id);

  /// Records that [grantId] satisfied reminder [id], so it never fires
  /// twice.
  Future<void> fulfil(String id, String grantId);
}
