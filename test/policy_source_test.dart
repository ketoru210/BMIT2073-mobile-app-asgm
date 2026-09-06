// F8 (remote policy catalogue) must never break offline use. loadBundled()
// is the offline baseline and fetchRemote()/load() are the live upgrade, so
// these tests inject fake PolicyApiClient bodies and check the catalogue
// only upgrades when the remote is strictly newer, and never throws.

import 'package:flutter_test/flutter_test.dart';

import 'package:bmit2073_asgm/data/policy_source.dart';

/// Fake client that always fails, as if the device is offline.
class _FailingClient extends PolicyApiClient {
  @override
  Future<dynamic> fetchBody() async => null;
}

/// Fake client returning a valid, higher-version catalogue.
class _NewerClient extends PolicyApiClient {
  @override
  Future<dynamic> fetchBody() async => {
    'version': 99,
    'policies': [
      {
        'policyId': 'newpolicy',
        'name': 'New Remote Policy',
        'abbreviation': 'NRP',
        'effectiveYear': 2025,
        'targetSectors': ['manufacturing'],
        'summary': 'A policy that only exists remotely.',
        'sourceUrl': 'https://example.com/nrp',
      },
    ],
  };
}

/// Fake client returning a valid catalogue at the same version as bundled.
class _SameVersionClient extends PolicyApiClient {
  @override
  Future<dynamic> fetchBody() async => {
    'version': 1,
    'policies': [
      {
        'policyId': 'newpolicy',
        'name': 'New Remote Policy',
        'abbreviation': 'NRP',
        'effectiveYear': 2025,
        'targetSectors': ['manufacturing'],
        'summary': 'A policy that only exists remotely.',
        'sourceUrl': 'https://example.com/nrp',
      },
    ],
  };
}

/// Fake client returning a version lower than the bundled one.
class _OlderClient extends PolicyApiClient {
  @override
  Future<dynamic> fetchBody() async => {
    'version': 0,
    'policies': [
      {
        'policyId': 'oldpolicy',
        'name': 'Old Remote Policy',
        'abbreviation': 'ORP',
        'effectiveYear': 2010,
        'targetSectors': ['manufacturing'],
        'summary': 'Stale.',
        'sourceUrl': 'https://example.com/orp',
      },
    ],
  };
}

/// Fake client returning a malformed payload — decodes, but not the
/// expected shape (missing required fields).
class _MalformedClient extends PolicyApiClient {
  @override
  Future<dynamic> fetchBody() async => {
    'version': 99,
    'policies': [
      {'unexpected': 'shape'},
    ],
  };
}

/// Fake client returning a 200 with zero policies — must be rejected the
/// same way an empty GDP payload is in F1.
class _EmptyClient extends PolicyApiClient {
  @override
  Future<dynamic> fetchBody() async => {'version': 99, 'policies': <dynamic>[]};
}

/// Fake client returning the legacy bare-array shape (version 0).
class _LegacyArrayClient extends PolicyApiClient {
  @override
  Future<dynamic> fetchBody() async => [
    {
      'policyId': 'legacypolicy',
      'name': 'Legacy Array Policy',
      'abbreviation': 'LAP',
      'effectiveYear': 2015,
      'targetSectors': ['manufacturing'],
      'summary': 'Parsed from a bare array.',
      'sourceUrl': 'https://example.com/lap',
    },
  ];
}

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  test('bundled load works offline and yields the full policy list', () async {
    final source = PolicySource(client: _FailingClient());
    final catalogue = await source.loadBundled();

    expect(catalogue.isRemote, isFalse);
    expect(catalogue.policies, isNotEmpty);
    expect(catalogue.version, 1);
  });

  test(
    'a failing remote fetch leaves the bundled catalogue in place',
    () async {
      final source = PolicySource(client: _FailingClient());
      final loaded = await source.load();

      expect(loaded.isRemote, isFalse);
      expect(loaded.version, 1);
    },
  );

  test('a remote with a higher version replaces the bundled one', () async {
    final source = PolicySource(client: _NewerClient());
    final loaded = await source.load();

    expect(loaded.isRemote, isTrue);
    expect(loaded.version, 99);
    expect(loaded.policies.single.policyId, 'newpolicy');
  });

  test('a remote at an equal version is ignored — bundled wins', () async {
    final source = PolicySource(client: _SameVersionClient());
    final loaded = await source.load();

    expect(loaded.isRemote, isFalse);
    expect(loaded.version, 1);
  });

  test('a remote at a lower version is ignored — bundled wins', () async {
    final source = PolicySource(client: _OlderClient());
    final loaded = await source.load();

    expect(loaded.isRemote, isFalse);
    expect(loaded.version, 1);
  });

  test('a malformed remote payload falls back instead of throwing', () async {
    final source = PolicySource(client: _MalformedClient());
    final loaded = await source.load();

    expect(loaded.isRemote, isFalse);
    expect(loaded.version, 1);
  });

  test('a remote with zero policies is rejected', () async {
    final source = PolicySource(client: _EmptyClient());
    expect(await source.fetchRemote(), isNull);
  });

  test('the bare-array legacy shape still parses as version 0', () async {
    final source = PolicySource(client: _LegacyArrayClient());
    final remote = await source.fetchRemote();

    expect(remote, isNotNull);
    expect(remote!.version, 0);
    expect(remote.policies.single.policyId, 'legacypolicy');
  });
}
