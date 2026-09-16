// A shake is several samples over the threshold, so the cooldown is what
// stops one flick from firing a handful of times — and the threshold is
// what stops walking from firing at all.

import 'package:flutter_test/flutter_test.dart';

import 'package:bmit2073_asgm/data/shake_detector.dart';

void main() {
  late DateTime clock;

  ShakeDetector build({double threshold = 2.0}) {
    clock = DateTime(2026, 9, 16, 12);
    return ShakeDetector(
      threshold: threshold,
      cooldown: const Duration(milliseconds: 1500),
      now: () => clock,
    );
  }

  test('a phone at rest never shakes', () {
    final detector = build();
    // 1g straight down is what a phone lying on a table reports
    expect(detector.accept(0, 0, 9.81), isFalse);
  });

  test('a walking-speed jostle does not shake', () {
    final detector = build();
    // about 1.5g, the peak of a brisk walk
    expect(detector.accept(0, 5, 13.5), isFalse);
  });

  test('a flick shakes', () {
    final detector = build();
    expect(detector.accept(15, 12, 9.81), isTrue);
  });

  test('the rest of one flick is swallowed by the cooldown', () {
    final detector = build();
    expect(detector.accept(15, 12, 9.81), isTrue);

    clock = clock.add(const Duration(milliseconds: 200));
    expect(detector.accept(18, 10, 9.81), isFalse);
    clock = clock.add(const Duration(milliseconds: 600));
    expect(detector.accept(20, 14, 9.81), isFalse);
  });

  test('a second flick after the cooldown shakes again', () {
    final detector = build();
    expect(detector.accept(15, 12, 9.81), isTrue);

    clock = clock.add(const Duration(milliseconds: 1600));
    expect(detector.accept(15, 12, 9.81), isTrue);
  });
}
