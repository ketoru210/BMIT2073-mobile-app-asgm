// The home screen, the About text and the diversity footnote all quote
// counts from the dataset. These tests pin what those counts are so a
// literal typed into a widget cannot silently disagree with the data.

import 'package:flutter_test/flutter_test.dart';

import 'package:bmit2073_asgm/data/gdp_repository.dart';
import 'package:bmit2073_asgm/models/sector.dart';

void main() {
  test('the sector list matches what DOSM publishes', () {
    // p1..p6 — the stat card used to say five
    expect(Sector.values.length, 6);
  });

  test('the canonical state list covers all 16 states', () {
    expect(GdpRepository.canonicalStates.length, 16);
    // Supra is the source's offshore catch-all, not a state
    expect(GdpRepository.canonicalStates, isNot(contains('Supra')));
    expect(GdpRepository.allGeography.length, 17);
  });

  test('the snapshot loads the full year range', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final repo = GdpRepository();
    await repo.load();

    expect(repo.years.length, 11);
    expect(repo.years.first, 2015);
    // the default year follows this, so it must be a year with data
    expect(repo.totalValue(state: 'Selangor', year: repo.years.last), isNotNull);
  });
}
