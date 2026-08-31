// The grants stub is what C builds against before Supabase exists, so the
// two things that would fail silently are pinned here: the null-means-
// unrestricted matching rule, and seed values that must agree with the
// canonical state and sector lists.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bmit2073_asgm/data/gdp_repository.dart';
import 'package:bmit2073_asgm/data/local_grant_repository.dart';
import 'package:bmit2073_asgm/data/user_repository.dart';
import 'package:bmit2073_asgm/models/grant.dart';
import 'package:bmit2073_asgm/models/sector.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  test('seed grants only name states and sectors the dataset knows', () async {
    final grants = await LocalGrantStore().loadGrants();
    expect(grants, isNotEmpty);

    for (final g in grants) {
      if (g.state != null) {
        // a grant scoped to a state the filter can never produce is
        // unreachable — 'Penang' instead of 'Pulau Pinang' did exactly this
        expect(GdpRepository.canonicalStates, contains(g.state));
      }
    }
  });

  test('a null field on either side means no restriction', () async {
    final repo = LocalGrantRepository();

    // nationwide + any-sector grants must survive every filter
    final selangorMfg = await repo.available(
      state: 'Selangor',
      sector: Sector.manufacturing,
    );
    final ids = selangorMfg.map((g) => g.id).toList();
    expect(ids, contains('sme-general-digitalisation')); // state & sector null
    expect(ids, contains('diaf-manufacturing')); // state null
    expect(ids, contains('selangor-smart-manufacturing')); // both match

    // and a grant scoped to another state must not
    expect(ids, isNot(contains('penang-industrial-development')));
  });

  test('a state-scoped grant is reachable from its own state', () async {
    final repo = LocalGrantRepository();
    final penang = await repo.available(
      state: 'Pulau Pinang',
      sector: Sector.manufacturing,
    );
    expect(
      penang.map((g) => g.id),
      contains('penang-industrial-development'),
    );
  });

  test('no filter returns every open grant', () async {
    final repo = LocalGrantRepository();
    final all = await repo.available();
    final seeded = await LocalGrantStore().loadGrants();
    expect(all.length, seeded.where((g) => g.isOpen).length);
  });

  test('an expired grant is not offered', () async {
    final admin = LocalGrantAdminRepository();
    await admin.publish(_expiredGrant);

    final all = await LocalGrantRepository().available();
    expect(all.map((g) => g.id), isNot(contains('expired-demo')));
  });

  test('the repository assigns the application id, not the form', () async {
    final repo = LocalGrantRepository();
    await repo.apply(_draft('First project'));
    await repo.apply(_draft('Second project'));

    final mine = await repo.myApplications();
    expect(mine.length, 2);
    // the draft leaves id empty; two applications must not collide on it
    expect(mine.every((a) => a.id.isNotEmpty), isTrue);
    expect(mine[0].id, isNot(mine[1].id));
    expect(mine.every((a) => a.status == ApplicationStatus.pending), isTrue);
  });

  test('an approval is visible to the applicant', () async {
    final repo = LocalGrantRepository();
    await repo.apply(_draft('Line upgrade'));

    final admin = LocalGrantAdminRepository();
    final queue = await admin.pending();
    expect(queue.length, 1);
    await admin.decide(queue.first.id, ApplicationStatus.approved);

    final mine = await repo.myApplications();
    expect(mine.single.status, ApplicationStatus.approved);
    expect(mine.single.decidedAt, isNotNull);
    // and it leaves the pending queue
    expect(await admin.pending(), isEmpty);
  });
}

GrantApplication _draft(String projectName) {
  return GrantApplication.draft(
    grantId: 'diaf-manufacturing',
    userId: LocalUserRepository.localUserId,
    projectName: projectName,
    state: 'Selangor',
    sector: Sector.manufacturing,
    requestedAmountRm: 250000,
    note: 'demo',
  );
}

final Grant _expiredGrant = Grant(
  id: 'expired-demo',
  name: 'Closed Demo Grant',
  agency: 'Demo',
  state: null,
  sector: null,
  maxAmountRm: null,
  deadline: DateTime(2020, 1, 1),
  sourceUrl: 'https://example.com',
  criteriaNote: 'Demo criteria.',
  description: 'Deadline already passed.',
  publishedBy: 'admin',
  publishedAt: DateTime(2019, 1, 1),
  isOpen: true,
);
