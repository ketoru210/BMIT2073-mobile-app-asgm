import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/metrics.dart';
import '../models/sector.dart';
import '../state/app_state.dart';
import '../ui/palette.dart';
import '../widgets/back_chevron.dart';

/// About / data source tab: attribution, definitions, and credits.
///
/// Covers the citation requirement — dataset, units, and method are all
/// stated here in plain language.
class AboutPage extends StatelessWidget {
  const AboutPage({super.key, this.onBack});

  /// Asks the shell to return to the Home tab; null when the page is
  /// shown outside the tab shell.
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    // SafeArea keeps the title clear of the status bar.
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              BackChevron(onTap: () => _back(context)),
              const SizedBox(width: 6),
              const Text(
                'About',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Palette.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const _Section(
            title: 'Demo only',
            body:
                'This is a university coursework prototype. The grant '
                'listings and the application form are a demonstration — '
                'this app is not an official application channel, and '
                'nothing submitted here reaches any agency or fund.',
          ),
          _Section(
            title: 'Data source',
            body:
                'All GDP figures come from the official data.gov.my '
                'catalogue — dataset gdp_state_real_supply (DOSM, "Annual '
                'Real GDP by State & Economic Sector"). Values are RM '
                'million at constant 2015 prices. The app bundles a '
                'snapshot of the dataset so every screen works offline.',
            footnote: _dataSourceStatus(context),
          ),
          const _Section(
            title: 'What is "real GDP"?',
            body:
                'Real (constant-price) GDP removes the effect of '
                'inflation, so year-to-year changes reflect actual output '
                'growth, not price changes. All growth rates in this app '
                'are real year-on-year growth.',
          ),
          _Section(title: 'What is HHI?', body: _hhiExplainer()),
          const _Section(
            title: 'Policies',
            body:
                'Policy information is curated from official government '
                'sources; every policy card links to its source. Policy '
                'analysis shows an association between a policy year and '
                'sector growth — not a proven causal effect.',
          ),
          const _Section(
            title: 'Team',
            body:
                'BMIT2073 group project — members: Lam Yong Zhe, Lai Kang '
                'Yong, Fong Qin Wen, Lian Teck Wei. Theme: SDG 9 · '
                'Industry, Innovation and Infrastructure.',
          ),
        ],
      ),
    );
  }

  /// Pops when pushed as a route, otherwise hands control to the shell.
  void _back(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      onBack?.call();
    }
  }
}

/// One line reporting whether the dataset is live or the bundled baseline.
///
/// The wording lives on the repository, so this line can never disagree
/// with what [GdpRepository.load] actually did.
String _dataSourceStatus(BuildContext context) =>
    context.read<AppState>().repository.sourceLabel;

/// One titled text block, kept simple on purpose.
/// Plain-language HHI explainer.
///
/// The numbers are read from [HhiBands] and the sector list rather than
/// written out, so this text always agrees with the badges the ranking
/// screen shows.
String _hhiExplainer() {
  final sectorCount = Sector.values.length;
  final floor = HhiBands.floor.toStringAsFixed(3);
  final balanced = HhiBands.balanced.toStringAsFixed(3);
  final risk = HhiBands.risk.toStringAsFixed(3);
  return 'The Herfindahl–Hirschman Index measures how concentrated a '
      'state’s economy is: the sum of squared sector shares. Across '
      '$sectorCount sectors it can only run from $floor (an even split) to '
      '1.000 (one sector takes everything) — it never reaches 0. This '
      'app calls a state balanced below $balanced and concentrated above '
      '$risk.';
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.body, this.footnote});

  final String title;
  final String body;

  /// Optional one-line status shown below [body], e.g. the data-source
  /// freshness line. Kept separate from body so it can be computed at
  /// build time without touching the const explainer text above it.
  final String? footnote;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Palette.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              body,
              style: const TextStyle(
                fontSize: 13,
                color: Palette.muted,
                height: 1.5,
              ),
            ),
            if (footnote != null) ...[
              const SizedBox(height: 6),
              Text(
                footnote!,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Palette.ink,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
