import 'package:bmit2073_asgm/data/location_service.dart';

/// Hands back a fixed answer so tests can exercise both the "we found
/// you" and "we could not" paths without a platform channel.
class FakeLocationService implements LocationService {
  FakeLocationService.at(double latitude, double longitude)
    : _result = LocationResult.success(GeoPoint(latitude, longitude));

  FakeLocationService.failing(LocationFailure failure)
    : _result = LocationResult.failed(failure);

  final LocationResult _result;

  /// How many fixes were asked for, so a test can prove the button does
  /// not call out again when it is only clearing the filter.
  int calls = 0;

  @override
  Future<LocationResult> current() async {
    calls++;
    return _result;
  }
}
