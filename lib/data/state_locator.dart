import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/services.dart' show rootBundle;

import 'location_service.dart';

/// One state's reference point.
///
/// [radiusKm] marks an enclave: a federal territory small enough, and
/// surrounded closely enough by another state, that the nearest-centroid
/// rule would give the wrong answer downtown.
class StateCentroid {
  const StateCentroid({
    required this.state,
    required this.latitude,
    required this.longitude,
    this.radiusKm,
  });

  final String state;
  final double latitude;
  final double longitude;
  final double? radiusKm;

  bool get isEnclave => radiusKm != null;

  GeoPoint get point => GeoPoint(latitude, longitude);

  factory StateCentroid.fromJson(Map<String, dynamic> json) {
    return StateCentroid(
      state: json['state'] as String,
      latitude: (json['lat'] as num).toDouble(),
      longitude: (json['lon'] as num).toDouble(),
      radiusKm: (json['radiusKm'] as num?)?.toDouble(),
    );
  }
}

/// Turns a GPS fix into one of the 16 canonical state names, offline.
///
/// No geocoding service is called: a reverse-geocode would need the
/// network and a key, and the app must keep working without either. The
/// price is that the borders are approximate — see [nearest].
class StateLocator {
  const StateLocator(this.centroids);

  final List<StateCentroid> centroids;

  /// Anything further than this from every centroid is not in Malaysia.
  ///
  /// Generous on purpose: Sarawak alone runs more than 300 km from its own
  /// centre, so a tighter guard would reject people who really are in it.
  static const double _maxDistanceKm = 400;

  static const String _asset = 'assets/state_centroids.json';

  /// Reads the bundled centroids. Fast, offline, and always succeeds.
  static Future<StateLocator> load() async {
    final raw = await rootBundle.loadString(_asset);
    final list = (jsonDecode(raw) as List)
        .map((e) => StateCentroid.fromJson(e as Map<String, dynamic>))
        .toList();
    return StateLocator(list);
  }

  /// The state [point] is most likely in, or `null` when it is outside
  /// Malaysia.
  ///
  /// Enclaves win first: a fix inside Kuala Lumpur's or Putrajaya's radius
  /// is that territory, even though the Selangor centroid that surrounds
  /// them may be nearer. Smaller radii are tested first, so Putrajaya is
  /// not swallowed by the larger Kuala Lumpur circle. Everything else is
  /// the nearest centroid, which puts the border roughly — but not
  /// exactly — between two neighbours.
  String? nearest(GeoPoint point) {
    final enclaves = centroids.where((c) => c.isEnclave).toList()
      ..sort((a, b) => a.radiusKm!.compareTo(b.radiusKm!));
    for (final enclave in enclaves) {
      if (distanceKm(point, enclave.point) <= enclave.radiusKm!) {
        return enclave.state;
      }
    }

    StateCentroid? best;
    var bestDistance = double.infinity;
    for (final centroid in centroids.where((c) => !c.isEnclave)) {
      final distance = distanceKm(point, centroid.point);
      if (distance < bestDistance) {
        bestDistance = distance;
        best = centroid;
      }
    }
    if (best == null || bestDistance > _maxDistanceKm) return null;
    return best.state;
  }

  /// Great-circle distance in kilometres (haversine).
  ///
  /// Straight-line degrees would do here, but they shrink east-west the
  /// further from the equator you go, which would bias every comparison
  /// the same way; haversine costs a handful of trig calls and removes
  /// the question.
  static double distanceKm(GeoPoint a, GeoPoint b) {
    const earthRadiusKm = 6371.0;
    final dLat = _radians(b.latitude - a.latitude);
    final dLon = _radians(b.longitude - a.longitude);
    final h =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_radians(a.latitude)) *
            math.cos(_radians(b.latitude)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return 2 * earthRadiusKm * math.asin(math.min(1, math.sqrt(h)));
  }

  static double _radians(double degrees) => degrees * math.pi / 180;
}
