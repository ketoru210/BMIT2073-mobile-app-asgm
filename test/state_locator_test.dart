// The whole "near me" feature rests on this one function, and its two
// interesting cases are the ones a plain nearest-centroid search gets
// wrong: the federal-territory enclaves, and a fix outside Malaysia.

import 'package:flutter_test/flutter_test.dart';

import 'package:bmit2073_asgm/data/location_service.dart';
import 'package:bmit2073_asgm/data/state_locator.dart';

void main() {
  late StateLocator locator;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    locator = await StateLocator.load();
  });

  test('the bundled asset covers all 16 states', () {
    expect(locator.centroids, hasLength(16));
  });

  test('a fix in a state resolves to that state', () {
    // Kangar, Perlis
    expect(locator.nearest(const GeoPoint(6.44, 100.20)), 'Perlis');
    // George Town, Pulau Pinang
    expect(locator.nearest(const GeoPoint(5.41, 100.34)), 'Pulau Pinang');
    // Kota Kinabalu, Sabah
    expect(locator.nearest(const GeoPoint(5.98, 116.07)), 'Sabah');
    // Kuching, Sarawak — over 300 km from the Sarawak centroid
    expect(locator.nearest(const GeoPoint(1.55, 110.35)), 'Sarawak');
    // Johor Bahru
    expect(locator.nearest(const GeoPoint(1.49, 103.74)), 'Johor');
  });

  test('a fix downtown resolves to the enclave, not the state around it', () {
    // KLCC — nearer the Kuala Lumpur centroid than the Selangor one, but
    // only because the enclave rule runs first
    expect(locator.nearest(const GeoPoint(3.158, 101.712)), 'W.P. Kuala Lumpur');
    // Putrajaya sits inside the Kuala Lumpur radius; the smaller circle
    // has to be tested first
    expect(locator.nearest(const GeoPoint(2.926, 101.696)), 'W.P. Putrajaya');
    // Labuan is an island off Sabah
    expect(locator.nearest(const GeoPoint(5.28, 115.24)), 'W.P. Labuan');
  });

  test('a fix in Selangor but outside the enclaves stays Selangor', () {
    // Shah Alam
    expect(locator.nearest(const GeoPoint(3.073, 101.518)), 'Selangor');
  });

  test('a fix outside Malaysia resolves to nothing', () {
    expect(locator.nearest(const GeoPoint(13.75, 100.50)), isNull); // Bangkok
    expect(locator.nearest(const GeoPoint(-6.21, 106.85)), isNull); // Jakarta
  });

  test('the distance between two known points is right', () {
    // Kuala Lumpur to Singapore is about 315 km
    final km = StateLocator.distanceKm(
      const GeoPoint(3.139, 101.687),
      const GeoPoint(1.352, 103.820),
    );
    expect(km, closeTo(315, 10));
  });
}
