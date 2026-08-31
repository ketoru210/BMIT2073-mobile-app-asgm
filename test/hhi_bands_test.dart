// The concentration bands are derived from the sector count, not typed
// in as rounded numbers. These tests pin the exact values so a rounded
// literal cannot creep back in.

import 'package:flutter_test/flutter_test.dart';

import 'package:bmit2073_asgm/data/metrics.dart';
import 'package:bmit2073_asgm/models/sector.dart';

void main() {
  test('floor is an even split across every sector', () {
    // six sectors sharing equally: 6 x (1/6)^2 = 1/6
    expect(HhiBands.floor, 1 / 6);
    expect(Sector.values.length, 6);
  });

  test('bands sit at the quarter and half marks of the reachable span', () {
    // span is 1/6 to 1, so the marks are 3/8 and 7/12 exactly
    expect(HhiBands.balanced, 3 / 8);
    expect(HhiBands.risk, 7 / 12);
  });

  test('bands are ordered and inside the reachable span', () {
    expect(HhiBands.floor, lessThan(HhiBands.balanced));
    expect(HhiBands.balanced, lessThan(HhiBands.risk));
    expect(HhiBands.risk, lessThan(1.0));
  });

  test('a score just above the balanced cut is not called balanced', () {
    // Melaka 2018 (0.3783) and Johor 2020 (0.3784) sit here; rounding
    // the cut up to 0.38 used to mislabel both as Balanced.
    expect(0.3783, greaterThan(HhiBands.balanced));
    expect(0.3784, greaterThan(HhiBands.balanced));
  });
}
