// Every insight is a sentence with a number in it, and the number has to
// come out of the dataset — a wrong one would be read out loud in a demo
// and believed. Each rule is therefore checked against the figure the
// repository itself reports.

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:bmit2073_asgm/data/gdp_repository.dart';
import 'package:bmit2073_asgm/data/insights.dart';
import 'package:bmit2073_asgm/data/metrics.dart';
import 'package:bmit2073_asgm/models/sector.dart';

void main() {
  late GdpRepository repo;
  late int year;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    repo = GdpRepository();
    await repo.load();
    year = repo.years.last;
  });

  /// The insight a given rule would produce, by rolling until it comes
  /// up — [randomInsight] picks among whichever rules can be computed.
  Insight? insightOfKind(
    String kind, {
    String state = 'Selangor',
    Sector sector = Sector.manufacturing,
  }) {
    for (var seed = 0; seed < 50; seed++) {
      final insight = randomInsight(
        repo,
        state: state,
        sector: sector,
        year: year,
        random: Random(seed),
      );
      if (insight?.kind == kind) return insight;
    }
    return null;
  }

  test('the sector share matches what the repository reports', () {
    final insight = insightOfKind('sectorShare')!;
    final total = repo.totalValue(state: 'Selangor', year: year)!;
    final value = repo.sectorValue(
      state: 'Selangor',
      sector: Sector.manufacturing,
      year: year,
    )!;
    final share = (value / total * 100).toStringAsFixed(1);

    expect(insight.text, contains('$share%'));
    expect(insight.text, contains('Manufacturing'));
    expect(insight.text, contains('Selangor'));
  });

  test('the national rank is the state\'s real place', () {
    final insight = insightOfKind('nationalRank')!;
    final ranked =
        GdpRepository.canonicalStates
            .map(
              (s) => (
                state: s,
                value: repo.sectorValue(
                  state: s,
                  sector: Sector.manufacturing,
                  year: year,
                ),
              ),
            )
            .where((e) => e.value != null)
            .toList()
          ..sort((a, b) => b.value!.compareTo(a.value!));

    // Selangor is the country's manufacturing heartland; if the data ever
    // says otherwise this test should be the thing that notices
    expect(ranked.first.state, 'Selangor');
    expect(insight.text, contains('largest manufacturing'));
  });

  test('growth reports the same figure as the repository', () {
    final insight = insightOfKind('sectorGrowth')!;
    final growth = repo.growth(
      state: 'Selangor',
      sector: Sector.manufacturing,
      year: year,
    )!;

    expect(insight.text, contains(growth.abs().toStringAsFixed(1)));
    expect(insight.text, contains(growth < 0 ? 'shrank' : 'grew'));
  });

  test('the share of national output is computed over every geography', () {
    final insight = insightOfKind('shareOfNational')!;
    var national = 0.0;
    for (final geography in GdpRepository.allGeography) {
      national +=
          repo.sectorValue(
            state: geography,
            sector: Sector.manufacturing,
            year: year,
          ) ??
          0;
    }
    final value = repo.sectorValue(
      state: 'Selangor',
      sector: Sector.manufacturing,
      year: year,
    )!;

    expect(
      insight.text,
      contains('${(value / national * 100).toStringAsFixed(1)}%'),
    );
  });

  test('concentration uses the same bands as the diversity page', () {
    final insight = insightOfKind('concentration')!;
    final hhi = repo.concentration(state: 'Selangor', year: year)!;

    expect(insight.text, contains(hhi.toStringAsFixed(3)));
    final balanced = insight.text.contains('balanced economies');
    expect(balanced, hhi < HhiBands.balanced);
  });

  test('a state and year with no data produces no insight', () {
    expect(
      randomInsight(
        repo,
        state: 'Nowhere',
        sector: Sector.mining,
        year: year,
        random: Random(1),
      ),
      isNull,
    );
  });

  test('the smallest sector of a state is named as such', () {
    // Mining is negligible in Selangor; whichever year is last, it should
    // still be the tail of the six
    final insight = insightOfKind('sectorShare', sector: Sector.mining);
    expect(insight, isNotNull);
    expect(insight!.text, contains('smallest'));
  });
}
