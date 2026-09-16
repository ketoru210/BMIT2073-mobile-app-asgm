// "Near me" rewrites what the whole Browse page is about, so the tests
// check the list, the label and the reminder card together — and that a
// refused fix leaves every one of them alone.

import 'dart:convert';

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
import 'package:bmit2073_asgm/models/grant.dart';
import 'package:bmit2073_asgm/models/sector.dart';
import 'package:bmit2073_asgm/pages/grants/browse_page.dart';
import 'package:bmit2073_asgm/state/app_state.dart';

import 'fake_location_service.dart';
import 'fake_notification_service.dart';

void main() {
  /// Kangar, Perlis and George Town, Pulau Pinang.
  const perlis = (lat: 6.44, lon: 100.20);
  const penang = (lat: 5.41, lon: 100.34);

  Grant grant({required String name, String? state, Sector? sector}) {
    return Grant(
      id: 'grant-$name',
      name: name,
      agency: 'Demo Agency',
      state: state,
      sector: sector,
      maxAmountRm: 50000,
      deadline: DateTime.now().add(const Duration(days: 30)),
      sourceUrl: 'https://example.com',
      criteriaNote: 'Demo criteria.',
      description: 'Demo grant.',
      publishedBy: 'admin',
      publishedAt: DateTime.now(),
      isOpen: true,
    );
  }

  /// An already-seeded grants store holding exactly [grants], so the
  /// bundled seed does not decide what the list shows.
  void seedGrants(List<Grant> grants) {
    SharedPreferences.setMockInitialValues({
      'grant.seeded': true,
      'grant.grants': jsonEncode(grants.map((g) => g.toJson()).toList()),
    });
  }

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    seedGrants([
      grant(name: 'Perlis Mining Fund', state: 'Perlis', sector: Sector.mining),
      grant(
        name: 'Penang Mining Fund',
        state: 'Pulau Pinang',
        sector: Sector.mining,
      ),
    ]);
  });

  Future<void> pumpBrowse(WidgetTester tester, LocationService location) async {
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
          child: const MaterialApp(
            home: BrowsePage(state: 'Perlis', sector: Sector.mining),
          ),
        ),
      );
      await tester.pumpAndSettle();
    });
    await tester.pump();
  }

  /// Taps [finder] and lets the real I/O behind it finish.
  Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
    await tester.runAsync(() async {
      await tester.tap(finder);
      await tester.pumpAndSettle();
    });
    await tester.pump();
  }

  testWidgets('a fix narrows the list to the state the device is in', (
    tester,
  ) async {
    await pumpBrowse(tester, FakeLocationService.at(penang.lat, penang.lon));
    expect(find.text('Perlis Mining Fund'), findsOneWidget);

    await tapAndSettle(tester, find.text('Near me'));

    expect(find.text('Pulau Pinang · Mining'), findsOneWidget);
    expect(find.text('Penang Mining Fund'), findsOneWidget);
    expect(find.text('Perlis Mining Fund'), findsNothing);
    expect(find.text('Located'), findsOneWidget);
  });

  testWidgets('tapping again hands the page back to its own context', (
    tester,
  ) async {
    final location = FakeLocationService.at(penang.lat, penang.lon);
    await pumpBrowse(tester, location);

    await tapAndSettle(tester, find.text('Near me'));
    await tapAndSettle(tester, find.text('Located'));

    expect(find.text('Perlis · Mining'), findsOneWidget);
    expect(find.text('Perlis Mining Fund'), findsOneWidget);
    // clearing must not cost another fix
    expect(location.calls, 1);
  });

  testWidgets('a refused permission leaves the list as it was', (tester) async {
    await pumpBrowse(
      tester,
      FakeLocationService.failing(LocationFailure.permissionDenied),
    );

    await tapAndSettle(tester, find.text('Near me'));

    expect(find.text('Location permission denied.'), findsOneWidget);
    expect(find.text('Perlis · Mining'), findsOneWidget);
    expect(find.text('Perlis Mining Fund'), findsOneWidget);
    expect(find.text('Near me'), findsOneWidget);
  });

  testWidgets('a fix outside Malaysia says so and changes nothing', (
    tester,
  ) async {
    await pumpBrowse(tester, FakeLocationService.at(13.75, 100.50)); // Bangkok

    await tapAndSettle(tester, find.text('Near me'));

    expect(find.text('You do not appear to be in Malaysia.'), findsOneWidget);
    expect(find.text('Perlis · Mining'), findsOneWidget);
  });

  testWidgets('a located state with no grants offers the reminder', (
    tester,
  ) async {
    seedGrants([
      grant(name: 'Perlis Mining Fund', state: 'Perlis', sector: Sector.mining),
    ]);
    await pumpBrowse(tester, FakeLocationService.at(penang.lat, penang.lon));

    await tapAndSettle(tester, find.text('Near me'));

    expect(find.text('Set reminder'), findsOneWidget);
    expect(find.textContaining('Pulau Pinang · Mining'), findsWidgets);
  });

  testWidgets('a fix in the state already shown keeps the list', (
    tester,
  ) async {
    await pumpBrowse(tester, FakeLocationService.at(perlis.lat, perlis.lon));

    await tapAndSettle(tester, find.text('Near me'));

    expect(find.text('Perlis · Mining'), findsOneWidget);
    expect(find.text('Perlis Mining Fund'), findsOneWidget);
  });
}
