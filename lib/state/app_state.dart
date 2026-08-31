import 'package:flutter/foundation.dart';

import '../data/gdp_repository.dart';
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
    required this.policies,
    required this.users,
  });

  final GdpRepository repository;
  final List<PolicyRecord> policies;
  final UserRepository users;

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
  Future<void> init() async {
    await repository.load();
    // start on the newest year the snapshot carries rather than a year
    // typed into the source
    year = repository.years.last;
    await users.init();
    favorites = await users.favorites();
    ready = true;
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
          sector: sector,
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
