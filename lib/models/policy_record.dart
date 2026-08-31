import 'sector.dart';

/// One entry of the bundled policy catalogue
/// (assets/policy_catalogue.json, plan_v2.md appendix A).
///
/// Policies are static, curated, and every entry carries its official
/// source URL — the analysis only ever claims association, not causation.
class PolicyRecord {
  const PolicyRecord({
    required this.policyId,
    required this.name,
    required this.abbreviation,
    required this.effectiveYear,
    required this.targetSectorNames,
    required this.summary,
    required this.sourceUrl,
  });

  final String policyId;
  final String name;
  final String abbreviation;
  final int effectiveYear;

  /// Enum names (e.g. `"manufacturing"`) from the JSON file.
  final List<String> targetSectorNames;
  final String summary;
  final String sourceUrl;

  /// The sectors this policy targets, mapped to the frozen enum.
  List<Sector> get targetSectors =>
      targetSectorNames.map((n) => Sector.values.byName(n)).toList();

  factory PolicyRecord.fromJson(Map<String, dynamic> json) {
    return PolicyRecord(
      policyId: json['policyId'] as String,
      name: json['name'] as String,
      abbreviation: json['abbreviation'] as String,
      effectiveYear: json['effectiveYear'] as int,
      targetSectorNames: (json['targetSectors'] as List<dynamic>)
          .cast<String>(),
      summary: json['summary'] as String,
      sourceUrl: json['sourceUrl'] as String,
    );
  }
}
