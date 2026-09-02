import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;

import '../models/policy_record.dart';

/// One loaded snapshot of the policy catalogue: its version, the parsed
/// records, and whether it came from the network or the bundled asset.
class PolicyCatalogue {
  const PolicyCatalogue({
    required this.version,
    required this.policies,
    required this.isRemote,
  });

  final int version;
  final List<PolicyRecord> policies;
  final bool isRemote;

  /// The one sentence the Policy page shows about which catalogue is in
  /// effect. Built here rather than in the page so the wording can never
  /// disagree with what was actually loaded.
  String get label =>
      'Policy catalogue v$version · ${isRemote ? 'Remote' : 'Local'}';
}

/// Talks to the remote policy catalogue.
///
/// Mirrors `GdpApiClient`: this class never throws — any failure (timeout,
/// bad status, malformed body) collapses to `null` so [PolicySource] can
/// fall back to the bundled asset without the UI ever seeing an exception.
class PolicyApiClient {
  /// Remote copy of `assets/policy_catalogue.json`, hosted on GitHub raw so
  /// it can evolve independently of the bundled asset.
  static const _endpoint =
      'https://raw.githubusercontent.com/ketoru210/BMIT2073-mobile-app-asgm/main/assets/policy_catalogue.json';

  static const _timeout = Duration(seconds: 8);

  /// Fetches the raw decoded body, or `null` on any failure.
  Future<dynamic> fetchBody() async {
    try {
      final response = await http.get(Uri.parse(_endpoint)).timeout(_timeout);
      if (response.statusCode != 200) return null;
      return jsonDecode(response.body);
    } catch (_) {
      // Any failure — timeout, socket error, malformed JSON — is treated
      // the same way: the caller falls back to the bundled catalogue.
      return null;
    }
  }
}

/// Owns the policy catalogue: loads the bundled asset, upgrades it with a
/// live fetch when the remote carries a newer version, and never lets the
/// network hold up the first frame.
///
/// [loadBundled] is the only step startup awaits. [load] additionally
/// tries the remote and only takes it when it is strictly newer than the
/// bundled version — otherwise the bundled catalogue wins, silently.
class PolicySource {
  PolicySource({PolicyApiClient? client})
    : _client = client ?? PolicyApiClient();

  final PolicyApiClient _client;

  /// Reads the bundled asset. Fast, offline, and always succeeds.
  Future<PolicyCatalogue> loadBundled() async {
    final raw = await rootBundle.loadString('assets/policy_catalogue.json');
    return _parse(jsonDecode(raw), isRemote: false);
  }

  /// Fetches the remote catalogue, or `null` on any failure — including a
  /// payload that decodes but does not carry a usable shape.
  Future<PolicyCatalogue?> fetchRemote() async {
    final body = await _client.fetchBody();
    if (body == null) return null;
    try {
      final catalogue = _parse(body, isRemote: true);
      if (catalogue.policies.isEmpty) return null;
      return catalogue;
    } catch (_) {
      return null;
    }
  }

  /// Loads the bundled catalogue, then upgrades it if the remote is newer.
  Future<PolicyCatalogue> load() async {
    final bundled = await loadBundled();
    return await upgrade(bundled) ?? bundled;
  }

  /// The remote catalogue if it is strictly newer than [current], else
  /// `null` meaning "keep what you have".
  ///
  /// This is the version comparison the F8 card asks for, and it lives in
  /// exactly one place: the running app upgrades through this method and
  /// so do the tests, so the rule they pin is the rule that ships.
  Future<PolicyCatalogue?> upgrade(PolicyCatalogue current) async {
    final remote = await fetchRemote();
    if (remote == null || remote.version <= current.version) return null;
    return remote;
  }

  /// Parses either shape: `{"version": n, "policies": [...]}` or a bare
  /// array, which is treated as version 0. The bare-array shape is the
  /// legacy format the remote file must never fail to match.
  PolicyCatalogue _parse(dynamic decoded, {required bool isRemote}) {
    final int version;
    final List<dynamic> rows;
    if (decoded is List) {
      version = 0;
      rows = decoded;
    } else {
      final map = decoded as Map<String, dynamic>;
      version = map['version'] as int;
      rows = map['policies'] as List<dynamic>;
    }
    final policies = rows
        .cast<Map<String, dynamic>>()
        .map(PolicyRecord.fromJson)
        .toList();
    return PolicyCatalogue(
      version: version,
      policies: policies,
      isRemote: isRemote,
    );
  }
}
