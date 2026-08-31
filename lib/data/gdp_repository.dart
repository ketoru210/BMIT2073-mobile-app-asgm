import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/gdp_record.dart';
import '../models/sector.dart';
import 'sector_mapping.dart';

/// Owns the dataset: loads the bundled snapshot, joins the abs and
/// growth_yoy rows into [GdpRecord]s, and answers every query.
///
/// The live API (api.data.gov.my) can replace the asset later; pages
/// never see the difference because they only talk to this class.
///
/// `Supra` is the source's "not attributable to a state" catch-all.
class GdpRepository {
  GdpRepository();

  /// Canonical state names in a fixed order, Supra excluded.
  static const List<String> canonicalStates = [
    'Johor',
    'Kedah',
    'Kelantan',
    'Melaka',
    'Negeri Sembilan',
    'Pahang',
    'Perak',
    'Perlis',
    'Pulau Pinang',
    'Sabah',
    'Sarawak',
    'Selangor',
    'Terengganu',
    'W.P. Kuala Lumpur',
    'W.P. Labuan',
    'W.P. Putrajaya',
  ];

  /// Every geography in the source, including Supra (offshore oil & gas) —
  /// used for national aggregates.
  static const List<String> allGeography = [...canonicalStates, 'Supra'];

  // key: `year|state|code` (e.g. `2023|Johor|p3`)
  final Map<String, double?> _abs = {};
  final Map<String, double?> _growth = {};

  final List<int> _years = [];
  bool _loaded = false;

  /// Whether [load] has completed.
  bool get isLoaded => _loaded;

  /// Years present in the snapshot, ascending.
  List<int> get years => List.unmodifiable(_years);

  /// The most recent [count] years, or every year when the snapshot
  /// holds fewer. Charts that show a fixed-width window use this so a
  /// shorter dataset still renders instead of throwing.
  List<int> recentYears(int count) =>
      _years.length <= count ? years : _years.sublist(_years.length - count);

  /// Loads assets/gdp_snapshot.json into memory.
  Future<void> load() async {
    final raw = await rootBundle.loadString('assets/gdp_snapshot.json');
    final rows = jsonDecode(raw) as List<dynamic>;

    final yearsSeen = <int>{};
    for (final row in rows.cast<Map<String, dynamic>>()) {
      // date is "YYYY-01-01" — annual data, so only the year matters.
      final year = int.parse((row['date'] as String).substring(0, 4));
      final state = row['state'] as String;
      final code = row['sector'] as String;
      final value = (row['value'] as num?)?.toDouble();
      final key = '$year|$state|$code';

      yearsSeen.add(year);
      if (row['series'] == 'abs') {
        _abs[key] = value;
      } else {
        _growth[key] = value;
      }
    }

    _years
      ..clear()
      ..addAll(yearsSeen)
      ..sort();
    _loaded = true;
  }

  /// All records matching the optional filters, sorted by year then state.
  /// A record is included when it has a value, a growth figure, or both.
  List<GdpRecord> query({
    List<String>? states,
    Sector? sector,
    int? yearStart,
    int? yearEnd,
  }) {
    final wantedStates = states ?? allGeography;
    final wantedCodes = sector == null
        ? Sector.values.map(sectorCode).toList()
        : [sectorCode(sector)];

    final result = <GdpRecord>[];
    for (final year in years) {
      if (yearStart != null && year < yearStart) continue;
      if (yearEnd != null && year > yearEnd) continue;

      for (final state in wantedStates) {
        for (final code in wantedCodes) {
          final mapped = sectorFromCode(code);
          if (mapped == null) continue; // p0 is not a sector

          final key = '$year|$state|$code';
          final value = _abs[key];
          final growth = _growth[key];
          if (value == null && growth == null) continue;

          result.add(
            GdpRecord(
              state: state,
              sector: mapped,
              year: year,
              value: value,
              growthYoy: growth,
            ),
          );
        }
      }
    }
    return result;
  }

  /// Total GDP (p0) for one state and year, RM million.
  double? totalValue({required String state, required int year}) =>
      _abs['$year|$state|p0'];

  /// Value of one sector for one state and year, RM million.
  double? sectorValue({
    required String state,
    required Sector sector,
    required int year,
  }) => _abs['$year|$state|${sectorCode(sector)}'];

  /// Year-on-year growth (percent) for one state, sector and year.
  double? growth({
    required String state,
    required Sector sector,
    required int year,
  }) => _growth['$year|$state|${sectorCode(sector)}'];

  /// Manufacturing as a share of total GDP, in percent.
  double? industryShare({required String state, required int year}) {
    final total = totalValue(state: state, year: year);
    final mfg = sectorValue(
      state: state,
      sector: Sector.manufacturing,
      year: year,
    );
    if (total == null || total == 0 || mfg == null) return null;
    return mfg / total * 100;
  }

  /// HHI concentration over every sector (higher = less diverse).
  ///
  /// With N sectors the value can only fall between 1/N (an even split)
  /// and 1.0 (one sector takes everything) — it never reaches 0. The
  /// bands that read this score live in `HhiBands`.
  double? concentration({required String state, required int year}) {
    final total = totalValue(state: state, year: year);
    if (total == null || total == 0) return null;

    var sumSquares = 0.0;
    for (final sector in Sector.values) {
      final v = _abs['$year|$state|${sectorCode(sector)}'];
      if (v == null) continue;
      final share = v / total;
      sumSquares += share * share;
    }
    return sumSquares;
  }
}
