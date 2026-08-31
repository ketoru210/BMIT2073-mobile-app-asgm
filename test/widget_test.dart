// Smoke test: the app boots with the bundled snapshot and shows the
// home tab. Also exercises the repository's asset loading and join.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bmit2073_asgm/data/gdp_repository.dart';
import 'package:bmit2073_asgm/data/user_repository.dart';
import 'package:bmit2073_asgm/main.dart';
import 'package:bmit2073_asgm/state/app_state.dart';

void main() {
  testWidgets('app boots and shows the home screen', (tester) async {
    SharedPreferences.setMockInitialValues({});

    final app = AppState(
      repository: GdpRepository(),
      policies: const [],
      users: LocalUserRepository(),
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
