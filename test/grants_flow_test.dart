// analyze cannot see a page that throws when it is built, and the three
// grant screens are the only ones with no design-time counterpart to
// eyeball. These tests boot them for real against the local stub.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bmit2073_asgm/data/gdp_repository.dart';
import 'package:bmit2073_asgm/data/local_grant_repository.dart';
import 'package:bmit2073_asgm/data/policy_source.dart';
import 'package:bmit2073_asgm/data/user_repository.dart';
import 'package:bmit2073_asgm/models/sector.dart';
import 'package:bmit2073_asgm/pages/grants/browse_page.dart';
import 'package:bmit2073_asgm/state/app_state.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  /// Wraps a page in the provider it reads from. The dataset is not
  /// loaded: the grant screens only touch `grants` and `users`, and
  /// loading the snapshot would just slow every test down.
  Widget host(Widget page) {
    final app = AppState(
      repository: GdpRepository(),
      policySource: PolicySource(),
      catalogue: const PolicyCatalogue(
        version: 0,
        policies: [],
        isRemote: false,
      ),
      users: LocalUserRepository(),
      grants: LocalGrantRepository(),
    );
    return ChangeNotifierProvider<AppState>.value(
      value: app,
      child: MaterialApp(home: page),
    );
  }

  testWidgets('browse lists the seeded grants for a state and sector', (
    tester,
  ) async {
    // Seeding reads an asset and shared_preferences — real I/O, which the
    // fake-async zone blocks on.
    await tester.runAsync(() async {
      await tester.pumpWidget(
        host(const BrowsePage(state: 'Selangor', sector: Sector.manufacturing)),
      );
      await tester.pumpAndSettle();
    });
    await tester.pump();

    expect(find.text('Grants'), findsOneWidget);
    // the filter pill echoes the context it was opened with
    expect(find.text('Selangor · Manufacturing'), findsOneWidget);
    // the stub seeds open grants, so the empty state must not show
    expect(find.textContaining('no open grants'), findsNothing);
  });

  testWidgets('clearing the filter widens the list and can be reapplied', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(
        host(const BrowsePage(state: 'Perlis', sector: Sector.mining)),
      );
      await tester.pumpAndSettle();
    });
    await tester.pump();

    await tester.runAsync(() async {
      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();
    });
    await tester.pump();
    expect(find.text('Showing all open grants'), findsOneWidget);

    await tester.runAsync(() async {
      await tester.tap(find.text('Reapply'));
      await tester.pumpAndSettle();
    });
    await tester.pump();
    expect(find.text('Perlis · Mining'), findsOneWidget);
  });

  testWidgets('opening a grant shows the eligibility verdict', (tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(
        host(const BrowsePage(state: 'Selangor', sector: Sector.manufacturing)),
      );
      await tester.pumpAndSettle();
    });
    await tester.pump();

    await tester.runAsync(() async {
      // 'Closes <date>' is unique to a grant row, so this cannot
      // land on the header's my-applications button by accident.
      await tester.tap(find.textContaining('Closes ').first);
      await tester.pumpAndSettle();
    });
    await tester.pump();

    expect(find.text('Eligibility'), findsOneWidget);
    // every criterion is rendered, not just the failing ones
    expect(find.text('Deadline'), findsOneWidget);
    expect(find.text('Apply'), findsOneWidget);
  });
}
