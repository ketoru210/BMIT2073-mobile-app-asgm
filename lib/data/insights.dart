import 'dart:math';

import '../models/sector.dart';
import 'gdp_repository.dart';
import 'metrics.dart';

/// One sentence about a state, sector and year, computed from the loaded
/// dataset.
class Insight {
  const Insight({required this.kind, required this.text});

  /// Which rule produced it — carried for tests and for the walkthrough,
  /// never shown to the user.
  final String kind;

  final String text;
}

/// A random true statement about [state] · [sector] · [year].
///
/// Every candidate below is computed from the dataset at call time; none
/// of the numbers are written down anywhere. A candidate that cannot be
/// computed — the source leaves plenty of state-year cells empty — drops
/// out, and if all of them drop out this returns null rather than
/// inventing something to say.
Insight? randomInsight(
  GdpRepository repository, {
  required String state,
  required Sector sector,
  required int year,
  Random? random,
}) {
  final candidates = <Insight>[
    ?_sectorShare(repository, state, sector, year),
    ?_nationalRank(repository, state, sector, year),
    ?_sectorGrowth(repository, state, sector, year),
    ?_shareOfNational(repository, state, sector, year),
    ?_concentration(repository, state, year),
  ];
  if (candidates.isEmpty) return null;
  return candidates[(random ?? Random()).nextInt(candidates.length)];
}

/// How much of the state's own output this sector is, and where that
/// puts it among the six.
Insight? _sectorShare(
  GdpRepository repository,
  String state,
  Sector sector,
  int year,
) {
  final total = repository.totalValue(state: state, year: year);
  final value = repository.sectorValue(
    state: state,
    sector: sector,
    year: year,
  );
  if (total == null || total == 0 || value == null) return null;

  final ranked =
      Sector.values
          .map(
            (s) => (
              sector: s,
              value: repository.sectorValue(
                state: state,
                sector: s,
                year: year,
              ),
            ),
          )
          .where((e) => e.value != null)
          .toList()
        ..sort((a, b) => b.value!.compareTo(a.value!));
  final place = ranked.indexWhere((e) => e.sector == sector);

  final share = _percent(value / total * 100);
  final rank = _placeWords(place, ranked.length);
  return Insight(
    kind: 'sectorShare',
    text:
        '${sector.label} is $share of $state’s economy in $year, '
        'its $rank of ${ranked.length} sectors.',
  );
}

/// Where the state sits among the 16 for this sector.
Insight? _nationalRank(
  GdpRepository repository,
  String state,
  Sector sector,
  int year,
) {
  final ranked =
      GdpRepository.canonicalStates
          .map(
            (s) => (
              state: s,
              value: repository.sectorValue(
                state: s,
                sector: sector,
                year: year,
              ),
            ),
          )
          .where((e) => e.value != null)
          .toList()
        ..sort((a, b) => b.value!.compareTo(a.value!));
  final place = ranked.indexWhere((e) => e.state == state);
  if (place < 0 || ranked.length < 2) return null;

  return Insight(
    kind: 'nationalRank',
    text:
        '$state has the ${_ordinal(place + 1)}-largest ${sector.label.toLowerCase()} '
        'output of the ${ranked.length} states with $year data '
        '(${_ringgit(ranked[place].value!)}).',
  );
}

/// This sector's year-on-year move, against the state's own.
Insight? _sectorGrowth(
  GdpRepository repository,
  String state,
  Sector sector,
  int year,
) {
  final growth = repository.growth(state: state, sector: sector, year: year);
  if (growth == null) return null;
  final overall = stateTotalYoY(repository, state, year);

  final verb = growth < 0 ? 'shrank' : 'grew';
  final sentence =
      '$state’s ${sector.label.toLowerCase()} output $verb '
      '${_percent(growth.abs())} in $year';
  if (overall == null) {
    return Insight(kind: 'sectorGrowth', text: '$sentence.');
  }
  final overallVerb = overall < 0 ? 'shrank' : 'grew';
  return Insight(
    kind: 'sectorGrowth',
    text:
        '$sentence, while the state as a whole $overallVerb '
        '${_percent(overall.abs())}.',
  );
}

/// How much of the country's output in this sector comes from here.
Insight? _shareOfNational(
  GdpRepository repository,
  String state,
  Sector sector,
  int year,
) {
  final value = repository.sectorValue(
    state: state,
    sector: sector,
    year: year,
  );
  if (value == null) return null;

  var national = 0.0;
  // Supra included: it is real output, so leaving it out would inflate
  // every state's share of the country.
  for (final geography in GdpRepository.allGeography) {
    national +=
        repository.sectorValue(
          state: geography,
          sector: sector,
          year: year,
        ) ??
        0;
  }
  if (national == 0) return null;

  return Insight(
    kind: 'shareOfNational',
    text:
        '$state produces ${_percent(value / national * 100)} of Malaysia’s '
        '${sector.label.toLowerCase()} output in $year.',
  );
}

/// How evenly the state's output is spread, in the same bands the
/// Diversity page uses.
Insight? _concentration(GdpRepository repository, String state, int year) {
  final hhi = repository.concentration(state: state, year: year);
  if (hhi == null) return null;

  final verdict = hhi > HhiBands.risk
      ? 'leaning heavily on one or two sectors'
      : hhi < HhiBands.balanced
      ? 'one of the more balanced economies in the country'
      : 'neither especially balanced nor especially concentrated';
  return Insight(
    kind: 'concentration',
    text:
        '$state scores ${hhi.toStringAsFixed(3)} on the concentration index '
        'in $year — $verdict.',
  );
}

/// `1.2%`, or `0.04%` when rounding to one place would read as zero.
String _percent(double value) {
  if (value > 0 && value < 0.05) return '${value.toStringAsFixed(2)}%';
  return '${value.toStringAsFixed(1)}%';
}

/// Values arrive in RM million; billions read better past a thousand.
String _ringgit(double million) {
  if (million >= 1000) return 'RM ${(million / 1000).toStringAsFixed(1)}B';
  return 'RM ${million.toStringAsFixed(0)}M';
}

String _placeWords(int index, int length) {
  if (index == 0) return 'largest';
  if (index == length - 1) return 'smallest';
  return '${_ordinal(index + 1)}-largest';
}

String _ordinal(int n) {
  if (n >= 11 && n <= 13) return '${n}th';
  switch (n % 10) {
    case 1:
      return '${n}st';
    case 2:
      return '${n}nd';
    case 3:
      return '${n}rd';
    default:
      return '${n}th';
  }
}
