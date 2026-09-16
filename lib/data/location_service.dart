import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// One GPS fix, in decimal degrees.
@immutable
class GeoPoint {
  const GeoPoint(this.latitude, this.longitude);

  final double latitude;
  final double longitude;

  @override
  bool operator ==(Object other) =>
      other is GeoPoint &&
      other.latitude == latitude &&
      other.longitude == longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);

  @override
  String toString() => 'GeoPoint($latitude, $longitude)';
}

/// Why a fix could not be taken, so the caller can say something useful
/// rather than one catch-all error.
enum LocationFailure {
  /// The user said no, or Android never asked because they said no for good.
  permissionDenied,

  /// Location is switched off device-wide.
  serviceDisabled,

  /// Permission was there but no fix arrived — indoors, or the emulator
  /// was never given a position.
  noFix,
}

/// The result of [LocationService.current]: exactly one of the two fields
/// is set.
@immutable
class LocationResult {
  const LocationResult.success(GeoPoint this.point) : failure = null;
  const LocationResult.failed(LocationFailure this.failure) : point = null;

  final GeoPoint? point;
  final LocationFailure? failure;
}

/// Device location, behind an interface so tests never touch the platform
/// channel (widget tests have no plugin implementation).
abstract class LocationService {
  /// A single fix, asking for permission first if it has not been granted.
  ///
  /// Never throws: every failure comes back as a [LocationFailure].
  Future<LocationResult> current();
}

/// [LocationService] backed by geolocator.
class DeviceLocationService implements LocationService {
  /// Long enough for a cold GPS fix, short enough that the button does not
  /// look stuck. A fix that has not arrived by then is reported as [noFix].
  static const _timeout = Duration(seconds: 10);

  @override
  Future<LocationResult> current() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return const LocationResult.failed(LocationFailure.serviceDisabled);
      }
      if (!await _hasPermission()) {
        return const LocationResult.failed(LocationFailure.permissionDenied);
      }
      final position = await _fix();
      if (position == null) {
        return const LocationResult.failed(LocationFailure.noFix);
      }
      return LocationResult.success(
        GeoPoint(position.latitude, position.longitude),
      );
    } catch (error) {
      // platform errors that are not a timeout land here
      debugPrint('Location fix failed: $error');
      return const LocationResult.failed(LocationFailure.noFix);
    }
  }

  /// How old the remembered fix may be before a fresh one is worth
  /// waiting for. Short on purpose: it exists to make a second tap
  /// instant, not to answer with where the phone used to be. A longer
  /// window would keep reporting the old state after the user moved.
  static const _staleAfter = Duration(seconds: 30);

  /// The remembered fix while it is recent, otherwise a fresh one —
  /// falling back to the stale fix if none arrives.
  ///
  /// Indoors a fresh fix can simply never turn up; an old position still
  /// names the right state far more often than an error does.
  Future<Position?> _fix() async {
    final known = await Geolocator.getLastKnownPosition();
    if (known != null &&
        DateTime.now().difference(known.timestamp) < _staleAfter) {
      return known;
    }
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          // GPS-priority: coarser settings are served by the fused
          // provider, which has nothing to give when wifi and cell
          // positioning are unavailable.
          accuracy: LocationAccuracy.high,
          timeLimit: _timeout,
        ),
      );
    } catch (error) {
      debugPrint('No fresh fix, falling back to the last known one: $error');
      return known;
    }
  }

  /// Asks only when Android has not already answered for us.
  Future<bool> _hasPermission() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }
}
