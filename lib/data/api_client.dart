import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Talks to the live data.gov.my GDP endpoint.
///
/// The bundled asset (`assets/gdp_snapshot.json`) is already shaped exactly
/// like this endpoint's rows, so [GdpRepository] can hand either source to
/// the same parsing code. This class never throws — any failure (timeout,
/// bad status, malformed body) collapses to `null` so the caller can fall
/// back to the asset without the UI ever seeing an exception.
class GdpApiClient {
  /// Real GDP by state & economic sector, DOSM's data.gov.my catalogue.
  static const _endpoint =
      'https://api.data.gov.my/data-catalogue/?id=gdp_state_real_supply';
  // The trailing slash matters: without it the API answers 301 and the
  // request pays for a second round trip before any data arrives.

  static const _timeout = Duration(seconds: 8);

  /// Fetches the raw row array, or `null` on any failure.
  Future<List<dynamic>?> fetchRows() async {
    try {
      final response = await http.get(Uri.parse(_endpoint)).timeout(_timeout);
      if (response.statusCode != 200) return null;

      final decoded = jsonDecode(response.body);
      if (decoded is! List) return null;
      return decoded;
    } catch (_) {
      // Any failure — timeout, socket error, malformed JSON — is treated
      // the same way: the repository falls back to the bundled snapshot.
      return null;
    }
  }
}
