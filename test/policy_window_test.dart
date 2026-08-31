// The policy windows are the one place the app makes a before/after claim,
// so the honest-degradation rules are pinned here: the effective year is
// never counted, and a window that runs off the end of the dataset shrinks
// instead of silently borrowing years it does not have.

import 'package:flutter_test/flutter_test.dart';

import 'package:bmit2073_asgm/data/gdp_repository.dart';
import 'package:bmit2073_asgm/data/policy_metrics.dart';
import 'package:bmit2073_asgm/models/sector.dart';

void main() {
  late GdpRepository repo;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    repo = GdpRepository();
    await repo.load();
  });

  test('the national series lines up with the year axis', () {
    final sums = nationalSums(repo, Sector.manufacturing);
    final yoy = nationalYoY(repo, Sector.manufacturing);

    expect(sums.length, repo.years.length);
    expect(yoy.length, repo.years.length);
    // the first year has no predecessor to grow from
    expect(yoy.first, isNull);
  });

  test('a policy near the end of the data gets a shortened after-window', () {
    // 2025 is the last year, so 2023 leaves two after-years and 2024 one
    final netr = growthAroundPolicy(
      repo,
      sector: Sector.manufacturing,
      effectiveYear: 2023,
    );
    final nss = growthAroundPolicy(
      repo,
      sector: Sector.manufacturing,
      effectiveYear: 2024,
    );

    expect(netr.afterYears, 2);
    expect(nss.afterYears, 1);
    // a thin window still reports a number — the page must say how thin
    expect(nss.afterAvg, isNotNull);
  });

  test('a policy with room on both sides gets full three-year windows', () {
    final industry4wrd = growthAroundPolicy(
      repo,
      sector: Sector.manufacturing,
      effectiveYear: 2018,
    );

    expect(industry4wrd.afterYears, 3);
    expect(industry4wrd.beforeAvg, isNotNull);
    expect(industry4wrd.afterAvg, isNotNull);
  });

  test('a policy in the second year of data has no before-window', () {
    // LSS took effect in 2016 and the data starts in 2015, so the only
    // computable growth rate before 2017 is 2016's own — the effective
    // year, which is excluded. There is nothing honest to average.
    final lss = growthAroundPolicy(
      repo,
      sector: Sector.services,
      effectiveYear: 2016,
    );

    expect(lss.beforeAvg, isNull);
    expect(lss.afterYears, 3);
  });
}
