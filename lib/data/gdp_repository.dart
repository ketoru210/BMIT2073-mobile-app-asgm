import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/gdp_record.dart';
import '../models/sector.dart';
import 'api_client.dart';
import 'sector_mapping.dart';

/// Owns the dataset: loads the bundled snapshot, joins the abs and
/// growth_yoy rows into [GdpRecord]s, and answers every query.
///
/// Loading is deliberately split in two. [load] reads the bundled asset
/// and is the only step startup waits on, so the first screen never waits
/// on a network. [refresh] then replaces that baseline with live
/// data.gov.my data if it can, and is a no-op the app can ignore when it
/// cannot — pages see no difference either way, since they only talk to
/// this class.
///
/// `Supra` is the source's "not attributable to a state" catch-all.
class GdpRepository {
  GdpRepository({GdpApiClient? client}) : _client = client ?? GdpApiClient();

  final GdpApiClient _client;

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

  bool _isStale = true;
  DateTime? _fetchedAt;

  /// True when the app is running on the bundled baseline rather than a
  /// live fetch — the About page reads this to tell the user which one.
  bool get isStale => _isStale;

  /// When the live fetch that is currently in effect completed, or null
  /// when the app is on the bundled baseline.
  DateTime? get fetchedAt => _fetchedAt;

  /// The one sentence the About page shows about where the numbers came
  /// from. Built here rather than in the page so the wording cannot drift
  /// away from which source is actually in effect.
  String get sourceLabel {
    final at = _fetchedAt;
    if (_isStale || at == null) {
      return 'Bundled baseline · data.gov.my snapshot';
    }
    final m = at.month.toString().padLeft(2, '0');
    final d = at.day.toString().padLeft(2, '0');
    return 'Live · data.gov.my · fetched ${at.year}-$m-$d';
  }

  /// Whether [load] has completed.
  bool get isLoaded => _loaded;

  /// Years present in the snapshot, ascending.
  List<int> get years => List.unmodifiable(_years);

  /// The most recent [count] years, or every year when the snapshot
  /// holds fewer. Charts that show a fixed-width window use this so a
  /// shorter dataset still renders instead of throwing.
  List<int> recentYears(int count) =>
      _years.length <= count ? years : _years.sublist(_years.length - count);

  /// Loads the bundled baseline. Fast, offline, and always succeeds —
  /// startup awaits this and nothing else.
  Future<void> load() async {
    final raw = await rootBundle.loadString('assets/gdp_snapshot.json');
    _commit(_parse(jsonDecode(raw) as List<dynamic>));
    _isStale = true;
    _fetchedAt = null;
  }

  /// Replaces the baseline with live data if the fetch works. Returns
  /// whether it did, and leaves the dataset untouched when it did not.
  ///
  /// Called after the UI is already on screen, never before it: an
  /// awaited network call in `main()` shows the user a blank screen for
  /// as long as the request takes, which is exactly what a dataset that
  /// ships in the APK should never do.
  Future<bool> refresh() async {
    final rows = await _client.fetchRows();
    if (rows == null) return false;

    // Parsed into a detached dataset first: a 200 carrying a reshaped
    // payload throws in [_parse] rather than arriving null or empty, and
    // half-ingesting it would leave the app worse off than not trying.
    final _Dataset parsed;
    try {
      parsed = _parse(rows);
    } catch (_) {
      return false;
    }
    // An empty array would otherwise blank every screen, which reads to
    // the user as a broken app rather than as stale data.
    if (parsed.years.isEmpty || parsed.abs.isEmpty) return false;

    _commit(parsed);
    _isStale = false;
    _fetchedAt = DateTime.now();
    return true;
  }

  /// Parses rows in the data.gov.my shape. Throws if they are not in it.
  ///
  /// Shared by the bundled and live paths — the asset is a copy of that
  /// endpoint's response, so one parser serves both.
  _Dataset _parse(List<dynamic> rows) {
    final abs = <String, double?>{};
    final growth = <String, double?>{};
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
        abs[key] = value;
      } else {
        growth[key] = value;
      }
    }

    return _Dataset(abs, growth, yearsSeen.toList()..sort());
  }

  /// Swaps [parsed] in as the dataset every query reads from.
  void _commit(_Dataset parsed) {
    _abs
      ..clear()
      ..addAll(parsed.abs);
    _growth
      ..clear()
      ..addAll(parsed.growth);
    _years
      ..clear()
      ..addAll(parsed.years);
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

/// One parsed dataset, held apart from the repository until it is known
/// to be good. Keeps a failed [GdpRepository.refresh] from leaving the
/// app with half of a bad payload.
class _Dataset {
  const _Dataset(this.abs, this.growth, this.years);

  final Map<String, double?> abs;
  final Map<String, double?> growth;
  final List<int> years;
}
