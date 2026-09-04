import '../models/analysis_request.dart';
import '../models/gdp_record.dart';
import 'gdp_repository.dart';
import 'metrics.dart';

/// Reshapes an analysis result into a flat CSV table.
///
/// The app's screens are shaped for reading — a donut, two compared
/// columns, a sparkline — and none of those shapes survive a copy-paste
/// into a spreadsheet. Export therefore flattens the same numbers into
/// one row per observation, which is the only form a spreadsheet can
/// pivot on.
///
/// Nothing here re-derives figures of its own: every value comes from
/// [GdpRepository] and [metrics], so an exported file and the screen it
/// came from can never disagree.
class AnalysisCsv {
  const AnalysisCsv._();

  /// The whole file, header row included, for [request].
  ///
  /// Diversity is the one mode with no sector axis — it compares whole
  /// state economies — so it gets its own table rather than being forced
  /// into a shape that would leave the sector column meaningless.
  static String build(GdpRepository repo, AnalysisRequest request) {
    if (request.mode == AnalysisMode.diversityDiagnosis) {
      return _diversityTable(repo, request);
    }
    return _recordTable(repo, request);
  }

  /// A suggested file name, e.g. `gdp-sector-breakdown-2023.csv`.
  ///
  /// Derived from the request so two exports from different selections
  /// never overwrite each other in the user's downloads.
  static String fileName(AnalysisRequest request) {
    final mode = _modeSlug(request.mode);
    final years = request.yearStart == request.yearEnd
        ? '${request.yearStart}'
        : '${request.yearStart}-${request.yearEnd}';
    return 'gdp-$mode-$years.csv';
  }

  /// One row per state x sector x year that carries data.
  static String _recordTable(GdpRepository repo, AnalysisRequest request) {
    final records = repo.query(
      states: request.states.isEmpty ? null : request.states,
      sector: request.sector,
      yearStart: request.yearStart,
      yearEnd: request.yearEnd,
    );

    final rows = <List<String>>[
      const ['State', 'Sector', 'Year', 'Value (RM million)', 'YoY growth (%)'],
    ];
    for (final GdpRecord r in records) {
      rows.add([
        r.state,
        r.sector.label,
        '${r.year}',
        _number(r.value),
        _number(r.growthYoy),
      ]);
    }
    return _encode(rows);
  }

  /// One row per state: size, concentration, and how the app reads it.
  ///
  /// The band is included because it is the diagnosis itself — a reader
  /// with the raw HHI alone would have to know the thresholds to use it.
  static String _diversityTable(GdpRepository repo, AnalysisRequest request) {
    final year = request.yearEnd;
    final rows = <List<String>>[
      const [
        'State',
        'Year',
        'Total GDP (RM million)',
        'HHI',
        'Concentration band',
      ],
    ];
    for (final state in GdpRepository.canonicalStates) {
      final hhi = repo.concentration(state: state, year: year);
      rows.add([
        state,
        '$year',
        _number(repo.totalValue(state: state, year: year)),
        _number(hhi, decimals: 4),
        _band(hhi),
      ]);
    }
    return _encode(rows);
  }

  /// The same three-way verdict the Diversity screen shows, read off the
  /// same [HhiBands] cuts. The middle band is blank on screen and blank
  /// here — inventing a word for it in the file only would make the
  /// export disagree with the page it came from.
  static String _band(double? hhi) {
    if (hhi == null) return '';
    if (hhi > HhiBands.risk) return 'Risk';
    if (hhi < HhiBands.balanced) return 'Balanced';
    return '';
  }

  /// A missing figure exports as an empty cell, never as `0` — the source
  /// genuinely has gaps, and a zero would read as a measured value.
  static String _number(double? value, {int decimals = 3}) =>
      value == null ? '' : value.toStringAsFixed(decimals);

  static String _modeSlug(AnalysisMode mode) {
    switch (mode) {
      case AnalysisMode.stateComparison:
        return 'state-comparison';
      case AnalysisMode.sectorBreakdown:
        return 'sector-breakdown';
      case AnalysisMode.timeTrend:
        return 'time-trend';
      case AnalysisMode.diversityDiagnosis:
        return 'diversity';
      case AnalysisMode.policyImpact:
        return 'policy-impact';
    }
  }

  /// Joins cells into RFC 4180 text: CRLF line endings, and any cell
  /// holding a comma, quote or newline wrapped in quotes with its own
  /// quotes doubled. Malaysian state names are plain today, but an
  /// exported file that breaks the first time a name changes is worse
  /// than three lines of escaping.
  static String _encode(List<List<String>> rows) {
    final buffer = StringBuffer();
    for (final row in rows) {
      buffer.write(row.map(_cell).join(','));
      buffer.write('\r\n');
    }
    return buffer.toString();
  }

  static String _cell(String value) {
    if (!value.contains(RegExp('[",\r\n]'))) return value;
    return '"${value.replaceAll('"', '""')}"';
  }
}
