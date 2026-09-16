import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/gdp_repository.dart';
import '../data/grant_reminder_repository.dart';
import '../data/grant_repository.dart';
import '../data/location_service.dart';
import '../data/notification_service.dart';
import '../data/policy_source.dart';
import '../data/user_repository.dart';
import '../models/analysis_request.dart';
import '../models/policy_record.dart';
import '../models/saved_analysis.dart';
import '../models/sector.dart';

/// The one shared state object: dataset, policy catalogue, favourites,
/// and the current filter selection.
///
/// Pages read selection from here and never mutate each other's state —
/// the filter layer (this class) is the single gate.
class AppState extends ChangeNotifier {
  AppState({
    required this.repository,
    required this.policySource,
    required PolicyCatalogue catalogue,
    required this.users,
    required this.grants,
    required this.reminders,
    required this.notifications,
    required this.location,
  }) {
    _catalogue = catalogue;
  }

  final GdpRepository repository;

  /// Loads and upgrades the policy catalogue; held here so the background
  /// refresh in [init] can reach it the same way it reaches [repository].
  final PolicySource policySource;
  final UserRepository users;

  late PolicyCatalogue _catalogue;

  /// The catalogue currently in effect — bundled until a newer remote one
  /// lands. The Policy page reads [PolicyCatalogue.label] off this so the
  /// version shown can never drift from what was actually loaded.
  PolicyCatalogue get catalogue => _catalogue;

  /// Convenience for the many readers that only ever wanted the records.
  List<PolicyRecord> get policies => _catalogue.policies;

  /// Grants backend. Held here so the grant screens reach it the same way
  /// every other page reaches the dataset, and so swapping the local stub
  /// for the Supabase implementation is a one-line change in main().
  final GrantRepository grants;

  /// The signed-in user's grant reminders, read by the Browse page and
  /// checked by [checkGrantReminders].
  final GrantReminderRepository reminders;

  /// Shows the system notification when a reminder is fulfilled.
  final NotificationService notifications;

  /// Device location, used by the Browse page to narrow grants to the
  /// state the user is standing in.
  final LocationService location;

  /// Launch, sign-in and resume can land on top of each other; this stops
  /// two overlapping checks from notifying about the same grant.
  bool _checkingReminders = false;

  bool ready = false;
  List<SavedAnalysis> favorites = [];

  // filter selection
  AnalysisMode mode = AnalysisMode.stateComparison;
  String stateA = 'Selangor';
  String stateB = 'Johor';
  bool compareEnabled = true;
  Sector sector = Sector.manufacturing;

  /// Selected year; [init] points it at the newest year in the snapshot.
  int year = 0;
  PolicyRecord? selectedPolicy;

  /// Loads the dataset and user data once at startup.
  ///
  /// Only the bundled baseline is awaited, so the first frame is never
  /// held up by the network; the live fetch runs after and repaints the
  /// app if it lands.
  Future<void> init() async {
    await repository.load();
    // start on the newest year the snapshot carries rather than a year
    // typed into the source
    year = repository.years.last;
    await users.init();
    favorites = await users.favorites();
    ready = true;
    notifyListeners();

    unawaited(_refreshDataset());
    unawaited(_refreshPolicies());
    unawaited(checkGrantReminders());
  }

  /// Pulls live data in the background and repaints if it arrives.
  ///
  /// The year selection is re-pinned afterwards because a live fetch can
  /// carry a year the bundled snapshot did not have, and a selection
  /// pointing at a year the dataset no longer holds renders as empty.
  Future<void> _refreshDataset() async {
    if (!await repository.refresh()) return;
    if (!repository.years.contains(year)) {
      year = repository.years.last;
    }
    notifyListeners();
  }

  /// Pulls the live policy catalogue in the background and repaints if a
  /// newer version arrives. Runs after the first frame, same as
  /// [_refreshDataset] — the network must never hold up startup.
  Future<void> _refreshPolicies() async {
    final newer = await policySource.upgrade(_catalogue);
    if (newer == null) return;

    _catalogue = newer;
    // A selection pointing at a policy the new catalogue no longer carries
    // would render the detail page empty, so drop it.
    final selected = selectedPolicy;
    if (selected != null &&
        !_catalogue.policies.any((p) => p.policyId == selected.policyId)) {
      selectedPolicy = null;
    }
    notifyListeners();
  }

  void selectMode(AnalysisMode newMode) {
    mode = newMode;
    notifyListeners();
  }

  void selectStateA(String state) {
    stateA = state;
    notifyListeners();
  }

  void selectStateB(String state) {
    stateB = state;
    notifyListeners();
  }

  void setCompareEnabled(bool enabled) {
    compareEnabled = enabled;
    notifyListeners();
  }

  void selectSector(Sector newSector) {
    sector = newSector;
    notifyListeners();
  }

  void selectYear(int newYear) {
    year = newYear;
    notifyListeners();
  }

  void selectPolicy(PolicyRecord policy) {
    selectedPolicy = policy;
    notifyListeners();
  }

  /// Builds the request the current filter describes
  AnalysisRequest generate() {
    final allYears = repository.years;
    switch (mode) {
      case AnalysisMode.stateComparison:
        return AnalysisRequest(
          mode: mode,
          states: compareEnabled ? [stateA, stateB] : [stateA],
          sector: sector,
          yearStart: year,
          yearEnd: year,
        );
      case AnalysisMode.sectorBreakdown:
        return AnalysisRequest(
          mode: mode,
          states: [stateA],
          yearStart: year,
          yearEnd: year,
        );
      case AnalysisMode.timeTrend:
        return AnalysisRequest(
          mode: mode,
          states: [stateA],
          sector: sector,
          yearStart: allYears.first,
          yearEnd: allYears.last,
        );
      case AnalysisMode.diversityDiagnosis:
        return AnalysisRequest(mode: mode, yearStart: year, yearEnd: year);
      case AnalysisMode.policyImpact:
        return AnalysisRequest(
          mode: mode,
          yearStart: year,
          yearEnd: year,
          policyId: selectedPolicy?.policyId,
        );
    }
  }

  /// Repaints after the account screens change profile data on [users].
  ///
  /// That write happens on the repository, not here, so this state has no
  /// way to notice it; the screen calls this instead of reaching for the
  /// protected [notifyListeners].
  void profileChanged() => notifyListeners();

  /// Re-reads the profile and favourites after a sign-in or sign-out.
  ///
  /// The auth screens hold their own repository instance, so the Supabase
  /// session changes underneath this one without its cached nickname and
  /// role ever being refreshed. Without this the app keeps behaving as the
  /// previous user — an administrator would not see the admin entries until
  /// the next cold start.
  Future<void> accountChanged() async {
    await users.init();
    favorites = await users.favorites();
    notifyListeners();
    unawaited(checkGrantReminders());
  }

  /// Notifies about every waiting reminder that a new grant now satisfies.
  ///
  /// Candidates come from [GrantRepository.available], so closed and
  /// expired grants never fire a reminder; the reminder's own options
  /// (nationwide, any sector, minimum amount, published after it was set)
  /// then narrow them. The reminder is marked fulfilled before the
  /// notification is shown: if that write fails, nothing is shown and the
  /// next check retries, instead of a reminder that notifies on every
  /// launch. Errors are logged and swallowed — the check runs again on the
  /// next launch, sign-in or resume.
  Future<void> checkGrantReminders() async {
    if (_checkingReminders || users.userId == null) return;
    _checkingReminders = true;
    try {
      for (final reminder in await reminders.active()) {
        final candidates = await grants.available(
          state: reminder.state,
          sector: reminder.sector,
        );
        final matches = candidates.where(reminder.matches);
        if (matches.isEmpty) continue;
        final grant = matches.first;
        await reminders.fulfil(reminder.id, grant.id);
        await notifications.show(
          // the plugin wants a non-negative 32-bit id; stable per reminder
          id: reminder.id.hashCode & 0x7fffffff,
          title: 'New grant for ${reminder.state} · ${reminder.sector.label}',
          body: '${grant.name} is now open for applications.',
        );
      }
    } catch (error) {
      debugPrint('Grant reminder check failed: $error');
    } finally {
      _checkingReminders = false;
    }
  }

  /// Saves the current selection as a favourite and refreshes the list.
  Future<void> saveCurrentFavorite() async {
    final label = _describeSelection();
    await users.saveFavorite(
      SavedAnalysis(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        label: label,
        request: generate(),
        savedAt: DateTime.now(),
      ),
    );
    favorites = await users.favorites();
    notifyListeners();
  }

  String _describeSelection() {
    final policy = selectedPolicy;
    if (mode == AnalysisMode.policyImpact) {
      return policy == null
          ? 'Policy impact'
          : '${policy.abbreviation} policy impact';
    }
    final sectorName = sector.label.toLowerCase();
    switch (mode) {
      case AnalysisMode.stateComparison:
        return compareEnabled
            ? 'Compare: $stateA vs $stateB · $sectorName $year'
            : '$stateA · $sectorName $year';
      case AnalysisMode.sectorBreakdown:
        return 'Sector breakdown: $stateA $year';
      case AnalysisMode.timeTrend:
        return 'Trend: $stateA $sectorName';
      case AnalysisMode.diversityDiagnosis:
        return 'Diversity: all states $year';
      case AnalysisMode.policyImpact:
        return 'Policy impact';
    }
  }
}
