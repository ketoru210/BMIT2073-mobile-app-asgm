import '../models/sector.dart';
import 'gdp_repository.dart';

/// One row of [hhiRanking]: a state and its concentration score.
class HhiEntry {
  const HhiEntry({required this.state, required this.hhi});

  final String state;
  final double hhi;
}

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
/// NOTE: this is an association, not a causal claimmd.
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

/// National total GDP (p0) across all geographies including Supra,
/// in RM million.
double? nationalTotal(GdpRepository repository, int year) {
  double? sum;
  for (final state in GdpRepository.allGeography) {
    final v = repository.totalValue(state: state, year: year);
    if (v == null) continue;
    sum = (sum ?? 0) + v;
  }
  return sum;
}

/// One state's total GDP as a percent of the national total
double? nationalShare(GdpRepository repository, String state, int year) {
  final total = nationalTotal(repository, year);
  final value = repository.totalValue(state: state, year: year);
  if (total == null || total == 0 || value == null) return null;
  return value / total * 100;
}

/// Year-on-year growth (percent) of a state's total GDP.
///
/// The source publishes a p0 growth row, but GdpRepository only exposes
/// sector-level growth, so the rate is computed from the absolute
/// totals — the same numbers the source derives its row from.
double? stateTotalYoY(GdpRepository repository, String state, int year) {
  final current = repository.totalValue(state: state, year: year);
  final previous = repository.totalValue(state: state, year: year - 1);
  if (current == null || previous == null || previous == 0) return null;
  return (current / previous - 1) * 100;
}

/// Cumulative percent growth of [sector] in [state] from [fromYear]
/// to [toYear].
double? cumulativeGrowth(
  GdpRepository repository,
  String state,
  Sector sector,
  int fromYear,
  int toYear,
) {
  final from = repository.sectorValue(
    state: state,
    sector: sector,
    year: fromYear,
  );
  final to = repository.sectorValue(state: state, sector: sector, year: toYear);
  if (from == null || to == null || from == 0) return null;
  return (to / from - 1) * 100;
}

/// First year of the unbroken run of positive year-on-year growth ending
/// at the last year with data, or null when the run has already broken.
///
/// e.g. returns 2021 when 2021..2025 all grew but 2020 did not.
int? consecutiveGrowthSince(
  GdpRepository repository,
  String state,
  Sector sector,
) {
  final years = repository.years;
  for (var i = years.length - 1; i >= 1; i--) {
    final growth = repository.growth(
      state: state,
      sector: sector,
      year: years[i],
    );
    if (growth == null || growth <= 0) {
      return i == years.length - 1 ? null : years[i + 1];
    }
  }
  return years[1];
}

/// The two cuts that split an HHI score into balanced / moderate /
/// concentrated.
///
/// HHI over N sectors cannot fall below 1/N — that is an even split,
/// the most diversified an economy can be — so its reachable span is
/// 1/N to 1, not 0 to 1. The cuts sit at the quarter and half marks of
/// that span. They are derived here rather than written as literals so
/// no rounding creeps in: for six sectors they work out exactly to
/// 3/8 and 7/12.
class HhiBands {
  HhiBands._();

  /// Lowest score the index can produce: every sector an equal share.
  static final double floor = 1 / Sector.values.length;

  /// Below this the economy spreads widely enough to call it balanced.
  static final double balanced = floor + (1 - floor) * 0.25;

  /// Above this the economy leans on one or two sectors.
  static final double risk = floor + (1 - floor) * 0.5;
}

/// HHI for every canonical state with data in [year], sorted from most
/// to least concentrated.
List<HhiEntry> hhiRanking(GdpRepository repository, int year) {
  final entries = <HhiEntry>[];
  for (final state in GdpRepository.canonicalStates) {
    final hhi = repository.concentration(state: state, year: year);
    if (hhi == null) continue;
    entries.add(HhiEntry(state: state, hhi: hhi));
  }
  entries.sort((a, b) => b.hhi.compareTo(a.hhi));
  return entries;
}
