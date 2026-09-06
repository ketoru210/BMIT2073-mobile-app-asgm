// F1 (live API channel) must never break offline use. load() is the
// bundled baseline and refresh() is the live upgrade, so these tests
// inject fake GdpApiClient results and check the app is left with a full,
// correct dataset whether the network is down, working, or lying.

import 'package:flutter_test/flutter_test.dart';

import 'package:bmit2073_asgm/data/api_client.dart';
import 'package:bmit2073_asgm/data/gdp_repository.dart';

/// Fake client that always fails, as if the device is offline.
class _FailingClient extends GdpApiClient {
  @override
  Future<List<dynamic>?> fetchRows() async => null;
}

/// Fake client that returns a small, valid, handcrafted row list.
class _ValidClient extends GdpApiClient {
  @override
  Future<List<dynamic>?> fetchRows() async => [
    {
      'date': '2020-01-01',
      'state': 'Selangor',
      'value': 123.0,
      'sector': 'p0',
      'series': 'abs',
    },
    {
      'date': '2021-01-01',
      'state': 'Selangor',
      'value': 456.0,
      'sector': 'p0',
      'series': 'abs',
    },
  ];
}

/// Fake client that returns a 200 with an empty array — the reshaped/empty
/// payload case the F1 card warns about.
class _EmptyClient extends GdpApiClient {
  @override
  Future<List<dynamic>?> fetchRows() async => [];
}

/// Fake client that returns a 200 whose rows are the wrong shape, as an
/// upstream schema change would look. Parsing these throws rather than
/// coming back empty, so it is a separate case from [_EmptyClient].
class _ReshapedClient extends GdpApiClient {
  @override
  Future<List<dynamic>?> fetchRows() async => [
    {'year': 2020, 'geography': 'Selangor', 'amount': 1.0},
  ];
}

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  test('a failing remote fetch leaves the bundled baseline in place', () async {
    final repo = GdpRepository(client: _FailingClient());
    await repo.load();
    expect(await repo.refresh(), isFalse);

    expect(repo.years.length, 11);
    expect(repo.isStale, isTrue);
    expect(repo.fetchedAt, isNull);
  });

  test('the baseline is on screen before the network is touched', () async {
    // The whole point of the split: load() is what startup awaits, and it
    // must be complete and usable on its own.
    final repo = GdpRepository(client: _FailingClient());
    await repo.load();

    expect(repo.isLoaded, isTrue);
    expect(repo.years.length, 11);
    expect(
      repo.totalValue(state: 'Selangor', year: repo.years.last),
      isNotNull,
    );
  });

  test(
    'a valid remote fetch replaces the baseline and marks it live',
    () async {
      final repo = GdpRepository(client: _ValidClient());
      await repo.load();
      expect(await repo.refresh(), isTrue);

      expect(repo.years, [2020, 2021]);
      expect(repo.totalValue(state: 'Selangor', year: 2020), 123.0);
      expect(repo.totalValue(state: 'Selangor', year: 2021), 456.0);
      expect(repo.isStale, isFalse);
      expect(repo.fetchedAt, isNotNull);
    },
  );

  test(
    'an empty remote array falls back to the asset, not an empty app',
    () async {
      final repo = GdpRepository(client: _EmptyClient());
      await repo.load();
      expect(await repo.refresh(), isFalse);

      expect(repo.years.length, 11);
      expect(repo.isStale, isTrue);
      expect(repo.fetchedAt, isNull);
    },
  );

  test('rows in an unexpected shape fall back instead of crashing', () async {
    final repo = GdpRepository(client: _ReshapedClient());
    await repo.load();
    // The failure here is a parse throw, not a null or empty result, so it
    // has to be caught rather than range-checked — a schema change upstream
    // must degrade to the baseline, never take the app down.
    expect(await repo.refresh(), isFalse);

    expect(repo.years.length, 11);
    expect(repo.isStale, isTrue);
    expect(repo.fetchedAt, isNull);
  });

  test('the source label follows what load actually did', () async {
    final live = GdpRepository(client: _ValidClient());
    await live.load();
    await live.refresh();
    expect(live.sourceLabel, startsWith('Live · data.gov.my · fetched '));

    final offline = GdpRepository(client: _FailingClient());
    await offline.load();
    await offline.refresh();
    expect(offline.sourceLabel, 'Bundled baseline · data.gov.my snapshot');
  });
}
