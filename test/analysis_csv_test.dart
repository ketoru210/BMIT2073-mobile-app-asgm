// Export is the one feature whose output nobody looks at on screen, so
// the shape of the file is pinned here: real figures, honest gaps, and
// text a spreadsheet can read back without guessing.

import 'package:flutter_test/flutter_test.dart';

import 'package:bmit2073_asgm/data/analysis_csv.dart';
import 'package:bmit2073_asgm/data/gdp_repository.dart';
import 'package:bmit2073_asgm/models/analysis_request.dart';
import 'package:bmit2073_asgm/models/sector.dart';

void main() {
  late GdpRepository repo;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    repo = GdpRepository();
    await repo.load();
  });

  List<String> lines(String csv) =>
      csv.split('\r\n').where((l) => l.isNotEmpty).toList();

  test('a breakdown exports one row per sector of the chosen state', () {
    final csv = AnalysisCsv.build(
      repo,
      AnalysisRequest(
        mode: AnalysisMode.sectorBreakdown,
        states: const ['Selangor'],
        yearStart: 2023,
        yearEnd: 2023,
      ),
    );
    final rows = lines(csv);

    expect(rows.first, 'State,Sector,Year,Value (RM million),YoY growth (%)');
    // one row per sector, and no other state leaks in
    expect(rows.length, Sector.values.length + 1);
    for (final row in rows.skip(1)) {
      expect(row, startsWith('Selangor,'));
    }
  });

  test('exported values match what the repository reports', () {
    final csv = AnalysisCsv.build(
      repo,
      AnalysisRequest(
        mode: AnalysisMode.sectorBreakdown,
        states: const ['Johor'],
        sector: Sector.manufacturing,
        yearStart: 2015,
        yearEnd: 2015,
      ),
    );
    final expected = repo.sectorValue(
      state: 'Johor',
      sector: Sector.manufacturing,
      year: 2015,
    )!;

    // the figure is carried through, not recomputed or rounded away
    expect(lines(csv)[1], contains(expected.toStringAsFixed(3)));
  });

  test('a comparison spans exactly the states asked for', () {
    final csv = AnalysisCsv.build(
      repo,
      AnalysisRequest(
        mode: AnalysisMode.stateComparison,
        states: const ['Selangor', 'Johor'],
        sector: Sector.services,
        yearStart: 2023,
        yearEnd: 2023,
      ),
    );
    final states = lines(csv).skip(1).map((r) => r.split(',').first).toSet();

    expect(states, {'Selangor', 'Johor'});
  });

  test('a trend exports every year in the window', () {
    final csv = AnalysisCsv.build(
      repo,
      AnalysisRequest(
        mode: AnalysisMode.timeTrend,
        states: const ['Perlis'],
        sector: Sector.agriculture,
        yearStart: repo.years.first,
        yearEnd: repo.years.last,
      ),
    );

    expect(lines(csv).length, repo.years.length + 1);
  });

  test('diversity exports one row per state with its band', () {
    final csv = AnalysisCsv.build(
      repo,
      const AnalysisRequest(
        mode: AnalysisMode.diversityDiagnosis,
        yearStart: 2023,
        yearEnd: 2023,
      ),
    );
    final rows = lines(csv);

    expect(rows.first, endsWith('HHI,Concentration band'));
    expect(rows.length, GdpRepository.canonicalStates.length + 1);
    // the band column only ever carries the two words the screen shows
    for (final row in rows.skip(1)) {
      expect(['Risk', 'Balanced', ''], contains(row.split(',').last));
    }
  });

  test('a figure the source does not publish is empty, never a zero', () {
    // 2015 is the first year in the dataset, so no row in it can carry a
    // year-on-year growth figure.
    final csv = AnalysisCsv.build(
      repo,
      AnalysisRequest(
        mode: AnalysisMode.sectorBreakdown,
        states: const ['Johor'],
        sector: Sector.manufacturing,
        yearStart: 2015,
        yearEnd: 2015,
      ),
    );
    final row = lines(csv)[1].split(',');

    expect(row[3], isNotEmpty); // the value is published
    expect(row[4], isEmpty); // the growth is not
    expect(row[4], isNot('0.000'));
  });

  test('an observation with no data at all is left out entirely', () {
    // W.P. Putrajaya manufacturing 2023 is the source's one hole. The
    // repository drops rows with neither a value nor a growth figure, and
    // the export follows it rather than inventing a blank row — the file
    // has to agree with the screen, which reads the same query.
    final csv = AnalysisCsv.build(
      repo,
      AnalysisRequest(
        mode: AnalysisMode.sectorBreakdown,
        states: const ['W.P. Putrajaya'],
        sector: Sector.manufacturing,
        yearStart: 2023,
        yearEnd: 2023,
      ),
    );

    expect(
      repo.sectorValue(
        state: 'W.P. Putrajaya',
        sector: Sector.manufacturing,
        year: 2023,
      ),
      isNull,
    );
    expect(lines(csv).length, 1); // header only
  });

  test('the file name describes the selection it came from', () {
    expect(
      AnalysisCsv.fileName(
        const AnalysisRequest(
          mode: AnalysisMode.sectorBreakdown,
          yearStart: 2023,
          yearEnd: 2023,
        ),
      ),
      'gdp-sector-breakdown-2023.csv',
    );
    expect(
      AnalysisCsv.fileName(
        const AnalysisRequest(
          mode: AnalysisMode.timeTrend,
          yearStart: 2015,
          yearEnd: 2023,
        ),
      ),
      'gdp-time-trend-2015-2023.csv',
    );
  });

  test('rows end in CRLF so a spreadsheet reads them back intact', () {
    final csv = AnalysisCsv.build(
      repo,
      const AnalysisRequest(
        mode: AnalysisMode.diversityDiagnosis,
        yearStart: 2023,
        yearEnd: 2023,
      ),
    );

    expect(csv, endsWith('\r\n'));
  });
}
