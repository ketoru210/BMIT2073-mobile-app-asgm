import '../models/sector.dart';
import 'gdp_repository.dart';

/// Result of comparing a sector's growth before and after a policy year.
class PolicyGrowth {
  const PolicyGrowth({this.beforeAvg, this.afterAvg, required this.afterYears});

  /// Average national YoY growth in the 3 years before the policy
  /// (null when too little history exists).
  final double? beforeAvg;

  /// Average national YoY growth in the up-to-3 years after the policy.
  final double? afterAvg;

  /// How many post-policy years actually have data (0..3).
  final int afterYears;
}

/// National absolute sum of [sector] per year, index-aligned with
/// [GdpRepository.years]. Includes Supra (offshore oil & gas).
///
/// National values are summed in-app because the source only publishes
/// state rows — the sum over all geography is the national figure.
List<double?> nationalSums(GdpRepository repository, Sector sector) {
  final sums = <double?>[];
  for (final year in repository.years) {
    double? sum;
    var any = false;
    for (final state in GdpRepository.allGeography) {
      final v = repository.sectorValue(
        state: state,
        sector: sector,
        year: year,
      );
      if (v == null) continue;
      sum = (sum ?? 0) + v;
      any = true;
    }
    sums.add(any ? sum : null);
  }
  return sums;
}

/// National YoY growth (percent) per year; the first year is null.
///
/// Growth of a sum is computed from the summed series — averaging state
/// growth rates instead would over-weight small states.
List<double?> nationalYoY(GdpRepository repository, Sector sector) {
  final sums = nationalSums(repository, sector);
  final yoy = <double?>[null];
  for (var i = 1; i < sums.length; i++) {
    final cur = sums[i];
    final prev = sums[i - 1];
    yoy.add(
      (cur == null || prev == null || prev == 0)
          ? null
          : (cur / prev - 1) * 100,
    );
  }
  return yoy;
}

/// National YoY growth of [sector] around [effectiveYear].
///
/// The effective year itself is skipped — a policy takes time to bite and
/// its launch year is noisy.
///
/// Neither window is guaranteed to be three years: LSS (2016) has only one
/// year of history in this dataset and the 2023-24 policies have one or two
/// years after, so both sides fall back to what data exists and
/// [PolicyGrowth.afterYears] reports how thin the after-window really is.
///
/// NOTE: this is an association, not a causal claim.
PolicyGrowth growthAroundPolicy(
  GdpRepository repository, {
  required Sector sector,
  required int effectiveYear,
}) {
  final years = repository.years;
  final yoy = nationalYoY(repository, sector);

  double? average(int from, int to) {
    final vals = <double>[];
    for (var i = from; i <= to; i++) {
      final y = yoy[i];
      if (y != null) vals.add(y);
    }
    if (vals.isEmpty) return null;
    return vals.reduce((a, b) => a + b) / vals.length;
  }

  final idx = years.indexOf(effectiveYear);
  final lastIdx = years.length - 1;

  double? before;
  if (idx >= 3) {
    before = average(idx - 3, idx - 1);
  } else if (idx >= 2) {
    // not enough history for a full 3-year window — use what exists
    before = average(1, idx - 1);
  }

  final afterYears = (lastIdx - idx).clamp(0, 3);
  final after = afterYears > 0 ? average(idx + 1, idx + afterYears) : null;

  return PolicyGrowth(
    beforeAvg: before,
    afterAvg: after,
    afterYears: afterYears,
  );
}
