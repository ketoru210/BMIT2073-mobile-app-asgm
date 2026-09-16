// Smoke test: the app boots with the bundled snapshot and shows the
// home tab. Also exercises the repository's asset loading and join.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bmit2073_asgm/data/gdp_repository.dart';
import 'package:bmit2073_asgm/data/local_grant_reminder_repository.dart';
import 'package:bmit2073_asgm/data/local_grant_repository.dart';
import 'package:bmit2073_asgm/data/policy_source.dart';
import 'package:bmit2073_asgm/data/user_repository.dart';
import 'package:bmit2073_asgm/main.dart';
import 'package:bmit2073_asgm/state/app_state.dart';

import 'fake_location_service.dart';
import 'fake_notification_service.dart';

void main() {
  testWidgets('app boots and shows the home screen', (tester) async {
    SharedPreferences.setMockInitialValues({});

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
      location: FakeLocationService.at(6.44, 100.20),
    );
    // Asset loading and shared_preferences do real async I/O, which the
    // fake-async test zone blocks on — run init in the real async zone.
    await tester.runAsync(app.init);

    await tester.pumpWidget(GdpAnalyzerApp(appState: app));
    await tester.pump();

    // home hero CTA (docs/ui_spec.md §1.2)
    expect(find.text('Ready to analyze?'), findsOneWidget);
    expect(find.text('Start Analysis'), findsOneWidget);
  });
}
