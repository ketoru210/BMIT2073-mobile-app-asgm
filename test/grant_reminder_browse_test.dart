// The reminder card has to appear whenever no grant is aimed at the exact
// pair — even with nationwide grants listed — and survive a refused
// notification prompt: both paths a user would hit without an error.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bmit2073_asgm/data/gdp_repository.dart';
import 'package:bmit2073_asgm/data/local_grant_reminder_repository.dart';
import 'package:bmit2073_asgm/data/local_grant_repository.dart';
import 'package:bmit2073_asgm/data/policy_source.dart';
import 'package:bmit2073_asgm/data/user_repository.dart';
import 'package:bmit2073_asgm/models/grant.dart';
import 'package:bmit2073_asgm/models/sector.dart';
import 'package:bmit2073_asgm/pages/grants/browse_page.dart';
import 'package:bmit2073_asgm/state/app_state.dart';
import 'package:bmit2073_asgm/widgets/toggle_switch.dart';

import 'fake_notification_service.dart';

void main() {
  late LocalGrantReminderRepository reminders;

  /// An already-seeded grants store holding exactly [grants], so the
  /// bundled seed does not decide what the list shows.
  void seedGrants(List<Grant> grants) {
    SharedPreferences.setMockInitialValues({
      'grant.seeded': true,
      'grant.grants': jsonEncode(grants.map((g) => g.toJson()).toList()),
    });
  }

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

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    seedGrants([]);
    reminders = LocalGrantReminderRepository();
  });

  Future<void> pumpBrowse(
    WidgetTester tester, {
    bool permissionGranted = true,
  }) async {
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
      reminders: reminders,
      notifications: FakeNotificationService(
        permissionGranted: permissionGranted,
      ),
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

  testWidgets('a reminder can be set from the sheet and cancelled', (
    tester,
  ) async {
    await pumpBrowse(tester);
    expect(find.text('Set reminder'), findsOneWidget);

    await tapAndSettle(tester, find.text('Set reminder'));
    expect(find.text('Reminder for Perlis · Mining'), findsOneWidget);

    await tapAndSettle(tester, find.text('Save reminder'));
    expect(find.text('Reminder on for Perlis · Mining'), findsOneWidget);
    expect(find.textContaining("We'll notify you when a grant"), findsOneWidget);
    expect(await tester.runAsync(reminders.active), hasLength(1));

    await tapAndSettle(tester, find.text('Cancel'));
    expect(find.text('Set reminder'), findsOneWidget);
    expect(await tester.runAsync(reminders.active), isEmpty);
  });

  testWidgets('the sheet saves the scope and minimum amount', (tester) async {
    await pumpBrowse(tester);
    await tapAndSettle(tester, find.text('Set reminder'));

    await tapAndSettle(tester, find.byType(ToggleSwitch).first);
    await tester.enterText(find.byType(TextField), '80000');
    await tapAndSettle(tester, find.text('Save reminder'));

    final saved = (await tester.runAsync(reminders.active))!.single;
    expect(saved.includeAllStates, isTrue);
    expect(saved.includeAllSectors, isFalse);
    expect(saved.minAmountRm, 80000);
    expect(find.textContaining('Nationwide included'), findsOneWidget);
  });

  testWidgets('a refused notification prompt still saves the reminder', (
    tester,
  ) async {
    await pumpBrowse(tester, permissionGranted: false);

    await tapAndSettle(tester, find.text('Set reminder'));
    await tapAndSettle(tester, find.text('Save reminder'));

    expect(find.text('Reminder on for Perlis · Mining'), findsOneWidget);
    expect(find.textContaining('Turn on notifications'), findsOneWidget);
    expect(await tester.runAsync(reminders.active), hasLength(1));
  });

  testWidgets('a listed nationwide grant does not hide the reminder', (
    tester,
  ) async {
    seedGrants([grant(name: 'Nationwide Fund')]);
    await pumpBrowse(tester);

    expect(find.text('Nationwide Fund'), findsOneWidget);
    expect(find.text('Set reminder'), findsOneWidget);
  });

  testWidgets('a grant aimed at the exact pair hides the reminder', (
    tester,
  ) async {
    seedGrants([
      grant(name: 'Perlis Mining Fund', state: 'Perlis', sector: Sector.mining),
    ]);
    await pumpBrowse(tester);

    expect(find.text('Perlis Mining Fund'), findsOneWidget);
    expect(find.text('Set reminder'), findsNothing);
  });

  testWidgets('clearing the filter hides the reminder', (tester) async {
    await pumpBrowse(tester);

    await tapAndSettle(tester, find.text('Clear'));
    expect(find.text('Set reminder'), findsNothing);
  });
}
