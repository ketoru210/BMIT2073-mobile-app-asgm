import 'dart:async';
import 'dart:math' as math;

import 'package:sensors_plus/sensors_plus.dart';

/// Decides which accelerometer samples count as a deliberate shake.
///
/// Split from the sensor stream so the rule can be tested without a
/// platform channel: [accept] is a plain function of one sample and the
/// clock.
class ShakeDetector {
  ShakeDetector({
    this.threshold = 1.8,
    this.cooldown = const Duration(milliseconds: 1500),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  /// Total acceleration, in g, a sample must beat. A phone at rest reads
  /// 1g and a brisk walk peaks near 1.5g, so this asks for a real flick
  /// without demanding a hard swing.
  final double threshold;

  /// How long after a shake further samples are ignored. One shake is
  /// several samples over the threshold; without this, a single flick
  /// would fire a handful of times.
  final Duration cooldown;

  final DateTime Function() _now;

  DateTime? _lastShake;

  /// Gravity in m/s², the unit the sensor reports in.
  static const double _g = 9.80665;

  /// Whether this sample is a shake worth acting on.
  bool accept(double x, double y, double z) {
    final force = math.sqrt(x * x + y * y + z * z) / _g;
    if (force < threshold) return false;

    final now = _now();
    final last = _lastShake;
    if (last != null && now.difference(last) < cooldown) return false;
    _lastShake = now;
    return true;
  }

  /// One event per shake, from the device's accelerometer.
  ///
  /// Sampled at the game rate (50 Hz), not the plugin's 5 Hz default: the
  /// peak of a flick lasts well under 200 ms, so at the default rate most
  /// shakes fall between two samples and are never seen at all.
  Stream<void> shakes() {
    return accelerometerEventStream(samplingPeriod: SensorInterval.gameInterval)
        .where((e) => accept(e.x, e.y, e.z))
        .map((_) {});
  }
}
