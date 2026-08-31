import 'sector.dart';

/// The four original analysis modes plus the policy-impact mode
/// added after tutor feedback.
enum AnalysisMode {
  stateComparison,
  sectorBreakdown,
  timeTrend,
  diversityDiagnosis,
  policyImpact,
}

/// The one object every analysis page reads.
///
/// The filter layer builds and validates it; pages never re-validate.
class AnalysisRequest {
  const AnalysisRequest({
    required this.mode,
    this.states = const [],
    this.sector,
    required this.yearStart,
    required this.yearEnd,
    this.policyId,
  });

  final AnalysisMode mode;
  final List<String> states;
  final Sector? sector;

  /// Single year when [yearStart] == [yearEnd].
  final int yearStart;
  final int yearEnd;

  /// Policy catalogue id, only set for [AnalysisMode.policyImpact].
  final String? policyId;
}
