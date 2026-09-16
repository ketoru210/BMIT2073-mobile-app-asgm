// The card is deliberately deaf until it is opened, so the tests check
// both halves of that contract: a shake on Home does nothing, and a
// shake inside the sheet rolls.

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bmit2073_asgm/data/gdp_repository.dart';
import 'package:bmit2073_asgm/data/local_grant_reminder_repository.dart';
import 'package:bmit2073_asgm/data/local_grant_repository.dart';
import 'package:bmit2073_asgm/data/policy_source.dart';
import 'package:bmit2073_asgm/data/user_repository.dart';
import 'package:bmit2073_asgm/models/analysis_request.dart';
import 'package:bmit2073_asgm/state/app_state.dart';
import 'package:bmit2073_asgm/widgets/shake_analysis_card.dart';

import 'fake_location_service.dart';
import 'fake_notification_service.dart';

void main() {
  late StreamController<void> shakes;
  late AppState app;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    shakes = StreamController<void>.broadcast();
    final repository = GdpRepository();
    await repository.load();
    app = AppState(
      repository: repository,
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
      location: FakeLocationService.at(3.14, 101.69),
    );
    app.year = repository.years.last;
  });

  tearDown(() => shakes.close());

  Future<void> pumpCard(WidgetTester tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: app,
          child: MaterialApp(
            home: Scaffold(
              body: ShakeAnalysisCard(
                shakes: shakes.stream,
                random: Random(7),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    });
    await tester.pump();
  }

  Future<void> openSheet(WidgetTester tester) async {
    await tester.tap(find.text('Feeling lucky?'));
    await tester.pumpAndSettle();
  }

  testWidgets('the card tells the user to tap first', (tester) async {
    await pumpCard(tester);

    expect(find.text('Feeling lucky?'), findsOneWidget);
    expect(find.text('Tap, then shake for a random analysis'), findsOneWidget);
  });

  testWidgets('shaking without opening the card does nothing', (tester) async {
    await pumpCard(tester);
    final before = (app.mode, app.stateA, app.sector, app.year);

    shakes.add(null);
    await tester.pumpAndSettle();

    expect(find.text('FEELING LUCKY?'), findsNothing);
    expect((app.mode, app.stateA, app.sector, app.year), before);
  });

  testWidgets('the sheet opens asking for a shake, with nothing rolled', (
    tester,
  ) async {
    await pumpCard(tester);
    final before = (app.mode, app.stateA, app.sector, app.year);

    await openSheet(tester);

    expect(find.text('Shake your phone'), findsOneWidget);
    expect(find.text('Roll for me'), findsOneWidget);
    // nothing is decided until the user asks for it
    expect((app.mode, app.stateA, app.sector, app.year), before);
    expect(find.text('Open analysis'), findsNothing);
  });

  testWidgets('a shake inside the sheet rolls and shows an insight', (
    tester,
  ) async {
    await pumpCard(tester);
    await openSheet(tester);
    final before = (app.mode, app.stateA, app.sector, app.year);

    shakes.add(null);
    await tester.pumpAndSettle();

    expect(find.text('YOUR RANDOM ANALYSIS'), findsOneWidget);
    expect((app.mode, app.stateA, app.sector, app.year), isNot(before));
    expect(find.textContaining(app.stateA), findsWidgets);
    expect(find.text('Roll again'), findsOneWidget);
    expect(find.text('Open analysis'), findsOneWidget);
  });

  testWidgets('the button rolls for a device that cannot be shaken', (
    tester,
  ) async {
    await pumpCard(tester);
    await openSheet(tester);

    await tester.tap(find.text('Roll for me'));
    await tester.pumpAndSettle();

    expect(find.text('YOUR RANDOM ANALYSIS'), findsOneWidget);
    expect(find.text('Open analysis'), findsOneWidget);
  });

  testWidgets('shaking again re-rolls without closing the sheet', (
    tester,
  ) async {
    await pumpCard(tester);
    await openSheet(tester);
    shakes.add(null);
    await tester.pumpAndSettle();
    final first = (app.mode, app.stateA, app.sector, app.year);

    shakes.add(null);
    await tester.pumpAndSettle();

    expect(find.text('YOUR RANDOM ANALYSIS'), findsOneWidget);
    expect((app.mode, app.stateA, app.sector, app.year), isNot(first));
  });

  testWidgets('closing the sheet stops listening for shakes', (tester) async {
    await pumpCard(tester);
    await openSheet(tester);
    expect(shakes.hasListener, isTrue);

    Navigator.of(tester.element(find.text('Roll for me'))).pop();
    await tester.pumpAndSettle();

    expect(shakes.hasListener, isFalse);
  });

  testWidgets('a roll never lands on Policy Impact', (tester) async {
    await pumpCard(tester);

    // one roll could miss it by luck; a hundred could not
    for (var seed = 0; seed < 100; seed++) {
      app.randomize(Random(seed));
      expect(app.mode, isNot(AnalysisMode.policyImpact));
      expect(app.stateB, isNot(app.stateA));
    }
  });
}
