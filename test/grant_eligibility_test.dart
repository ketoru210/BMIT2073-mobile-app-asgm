import 'package:flutter_test/flutter_test.dart';

import 'package:bmit2073_asgm/data/grant_eligibility.dart';
import 'package:bmit2073_asgm/models/grant.dart';
import 'package:bmit2073_asgm/models/sector.dart';

void main() {
  test('a nationwide grant passes the state check for any state', () {
    final r = GrantEligibility.evaluate(
      grant: _grant(state: null),
      state: 'Pulau Pinang',
      asOf: _now,
    );
    expect(r.isEligible, isTrue);
  });

  test('a state-scoped grant names both sides when it rules you out', () {
    final r = GrantEligibility.evaluate(
      grant: _grant(state: 'Selangor'),
      state: 'Pulau Pinang',
      asOf: _now,
    );
    expect(r.isEligible, isFalse);
    final reason = r.blockers.single.detail;
    expect(reason, contains('Selangor'));
    expect(reason, contains('Pulau Pinang'));
  });

  test('an unset sector is unknown, not a failure', () {
    final r = GrantEligibility.evaluate(
      grant: _grant(sector: Sector.manufacturing),
      state: 'Selangor',
      sector: null,
      asOf: _now,
    );
    expect(r.isEligible, isTrue);
    expect(r.unchecked.map((c) => c.label), contains('Sector'));
  });

  test('an over-ceiling amount fails and says by how much', () {
    final r = GrantEligibility.evaluate(
      grant: _grant(maxAmountRm: 200000),
      state: 'Selangor',
      requestedAmountRm: 250000,
      asOf: _now,
    );
    expect(r.isEligible, isFalse);
    expect(r.blockers.single.detail, contains('RM 50,000'));
  });

  test('an expired grant fails on the deadline', () {
    final r = GrantEligibility.evaluate(
      grant: _grant(deadline: DateTime(2020, 1, 1)),
      state: 'Selangor',
      asOf: _now,
    );
    expect(r.blockers.single.label, 'Deadline');
  });

  test('ringgit are grouped in threes', () {
    expect(formatRinggit(250000), 'RM 250,000');
    expect(formatRinggit(500), 'RM 500');
  });
}

final DateTime _now = DateTime(2026, 9, 1);

Grant _grant({
  String? state,
  Sector? sector,
  int? maxAmountRm,
  DateTime? deadline,
}) {
  return Grant(
    id: 'test-grant',
    name: 'Test Grant',
    agency: 'Test Agency',
    state: state,
    sector: sector,
    maxAmountRm: maxAmountRm,
    deadline: deadline ?? DateTime(2026, 12, 31),
    sourceUrl: 'https://example.com',
    criteriaNote: 'Demo conditions, not official criteria.',
    description: 'For tests.',
    publishedBy: 'admin',
    publishedAt: DateTime(2026, 1, 1),
    isOpen: true,
  );
}
