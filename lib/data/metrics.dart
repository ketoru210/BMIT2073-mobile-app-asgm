import '../models/sector.dart';
import 'gdp_repository.dart';

/// One row of [hhiRanking]: a state and its concentration score.
class HhiEntry {
  const HhiEntry({required this.state, required this.hhi});

  final String state;
  final double hhi;
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
