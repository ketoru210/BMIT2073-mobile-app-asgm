// The filter page's location shortcut writes straight into the shared
// selection, so the tests check what AppState ends up holding — and that
// a fix that cannot be used leaves the old selection alone.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bmit2073_asgm/data/gdp_repository.dart';
import 'package:bmit2073_asgm/data/local_grant_reminder_repository.dart';
import 'package:bmit2073_asgm/data/local_grant_repository.dart';
import 'package:bmit2073_asgm/data/location_service.dart';
import 'package:bmit2073_asgm/data/policy_source.dart';
import 'package:bmit2073_asgm/data/user_repository.dart';
import 'package:bmit2073_asgm/pages/filter_page.dart';
import 'package:bmit2073_asgm/state/app_state.dart';

import 'fake_location_service.dart';
import 'fake_notification_service.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({
      'grant.seeded': true,
      'grant.grants': '[]',
    });
  });

  /// Pumps the filter page on its own, with [location] behind the
  /// shortcut, and hands back the state it writes into.
  Future<AppState> pumpFilter(
    WidgetTester tester,
    LocationService location,
  ) async {
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
      reminders: LocalGrantReminderRepository(),
      notifications: FakeNotificationService(),
      location: location,
    );
    await tester.runAsync(() async {
      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: app,
          child: const MaterialApp(home: FilterPage()),
        ),
      );
      await tester.pumpAndSettle();
    });
    await tester.pump();
    return app;
  }

  Future<void> tapLocate(WidgetTester tester) async {
    await tester.runAsync(() async {
      await tester.tap(find.text('Use my location'));
      await tester.pumpAndSettle();
    });
    await tester.pump();
  }

  testWidgets('a fix selects the state the device is in', (tester) async {
    // George Town, Pulau Pinang
    final app = await pumpFilter(
      tester,
      FakeLocationService.at(5.41, 100.34),
    );
    expect(app.stateA, isNot('Pulau Pinang'));

    await tapLocate(tester);

    expect(app.stateA, 'Pulau Pinang');
    expect(find.text('Located you in Pulau Pinang.'), findsOneWidget);
  });

  testWidgets('a refused permission keeps the current state', (tester) async {
    final app = await pumpFilter(
      tester,
      FakeLocationService.failing(LocationFailure.permissionDenied),
    );
    final before = app.stateA;

    await tapLocate(tester);

    expect(app.stateA, before);
    expect(find.text('Location permission denied.'), findsOneWidget);
  });

  testWidgets('a fix outside Malaysia keeps the current state', (tester) async {
    final app = await pumpFilter(tester, FakeLocationService.at(13.75, 100.50));
    final before = app.stateA;

    await tapLocate(tester);

    expect(app.stateA, before);
    expect(find.text('You do not appear to be in Malaysia.'), findsOneWidget);
  });
}
