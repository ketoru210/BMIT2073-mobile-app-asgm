import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemNavigator;
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'data/gdp_repository.dart';
import 'data/local_grant_repository.dart';
import 'data/policy_source.dart';
import 'data/supabase_user_repository.dart';
import 'pages/about_page.dart';
import 'pages/filter_page.dart';
import 'pages/home_page.dart';
import 'pages/profile_page.dart';
import 'state/app_state.dart';
import 'ui/palette.dart';
import 'widgets/bottom_nav.dart';

/// Entry point: brings up Supabase, loads the bundled dataset + policy
/// catalogue, wires the provider, and launches the tab shell.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://hlkakrrlahounqqpukwi.supabase.co',
    publishableKey: 'sb_publishable_sbGp4hVepEIOZN3hYxgXJg_PzcQaG_C',
  );

  // Asset only, instant — startup awaits nothing else. The live catalogue
  // (if any) arrives in the background via AppState.init/_refreshPolicies.
  final policySource = PolicySource();
  final app = AppState(
    repository: GdpRepository(),
    policySource: policySource,
    catalogue: await policySource.loadBundled(),
    users: SupabaseUserRepository(),
    grants: LocalGrantRepository(),
  );
  await app.init();

  runApp(GdpAnalyzerApp(appState: app));
}

class GdpAnalyzerApp extends StatelessWidget {
  const GdpAnalyzerApp({super.key, required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => appState,
      child: MaterialApp(
        title: 'State GDP Analyzer',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Palette.primary),
          scaffoldBackgroundColor: Palette.ground,
        ),
        home: const HomeShell(),
      ),
    );
  }
}

/// Bottom tab shell: Home / Analyze / About.
///
/// [IndexedStack] keeps each tab alive, so filter selections survive
/// tab switches. The Analyze tab is its own [Navigator] rooted at the
/// filter page; result pages push on top of it,
/// so the shell-level bottom nav stays visible on every screen.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  /// Lets the shell drive the Analyze tab's history (system back,
  /// and the filter page's own back arrow).
  final GlobalKey<NavigatorState> _analyzeNav = GlobalKey<NavigatorState>();

  void _selectTab(int index) => setState(() => _index = index);

  /// True while the Analyze tab has a result page stacked on the filter.
  bool get _analyzeCanPop =>
      _index == 1 && (_analyzeNav.currentState?.canPop() ?? false);

  /// System back: unwind the Analyze stack first, then fall back to the
  /// Home tab. The root navigator is never popped, so the screen is
  /// never left blank.
  void _handleSystemBack() {
    if (_analyzeCanPop) {
      _analyzeNav.currentState!.pop();
      return;
    }
    if (_index != 0) {
      _selectTab(0);
      return;
    }
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleSystemBack();
      },
      child: Scaffold(
        body: IndexedStack(
          index: _index,
          children: [
            HomePage(
              onStartAnalysis: () => _selectTab(1),
              onProfile: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const ProfilePage()),
                );
              },
            ),
            AnalyzeNavigator(
              navigatorKey: _analyzeNav,
              onExit: () => _selectTab(0),
            ),
            AboutPage(onBack: () => _selectTab(0)),
          ],
        ),
        bottomNavigationBar: BottomNav(
          activeIndex: _index,
          onSelect: _selectTab,
        ),
      ),
    );
  }
}

/// Nested navigator for the Analyze tab: root is the filter page and
/// result pages push on top, so the shell's bottom nav stays visible.
class AnalyzeNavigator extends StatelessWidget {
  const AnalyzeNavigator({
    super.key,
    required this.navigatorKey,
    required this.onExit,
  });

  final GlobalKey<NavigatorState> navigatorKey;

  /// Called when the filter page (this navigator's root) is backed out
  /// of; the shell then returns to the Home tab.
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      onGenerateRoute: (settings) =>
          MaterialPageRoute<void>(builder: (_) => FilterPage(onExit: onExit)),
    );
  }
}
