import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/gdp_repository.dart';
import '../data/location_service.dart';
import '../data/state_locator.dart';
import '../models/analysis_request.dart';
import '../models/sector.dart';
import '../state/app_state.dart';
import '../ui/palette.dart';
import '../widgets/app_card.dart';
import '../widgets/back_chevron.dart';
import '../widgets/dropdown_card.dart';
import '../widgets/section_label.dart';
import '../widgets/toggle_switch.dart';
import 'breakdown_page.dart';
import 'comparison_page.dart';
import 'diversity_page.dart';
import 'policy_page.dart';
import 'trend_page.dart';

/// Human label for every [AnalysisMode], in filter order
const Map<AnalysisMode, String> _modeLabels = {
  AnalysisMode.stateComparison: 'State Comparison',
  AnalysisMode.sectorBreakdown: 'Sector Breakdown',
  AnalysisMode.timeTrend: 'Time Trend',
  AnalysisMode.diversityDiagnosis: 'Diversity Diagnosis',
  AnalysisMode.policyImpact: 'Policy Impact',
};

/// Analysis Filter — the Analyze tab's root page.
///
/// The back arrow always shows: it pops when this page was pushed, and
/// otherwise asks the shell to go back to Home ([onExit]).
class FilterPage extends StatelessWidget {
  const FilterPage({super.key, this.onExit});

  /// Supplied by the shell for the tab-root instance; null when the
  /// page is pushed as an ordinary route.
  final VoidCallback? onExit;

  /// Pops the pushed route, or leaves the tab when this is its root.
  void _back(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      onExit?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, app, child) {
        final repo = app.repository;
        final showStateSection = app.mode == AnalysisMode.stateComparison;
        final showStateRowOnly =
            app.mode == AnalysisMode.sectorBreakdown ||
            app.mode == AnalysisMode.timeTrend;
        final showSectorSection = 
            app.mode == AnalysisMode.stateComparison || 
            app.mode == AnalysisMode.timeTrend;
        final showYearSection = 
            app.mode != AnalysisMode.policyImpact && 
            app.mode != AnalysisMode.timeTrend;

        return Scaffold(
          backgroundColor: Palette.ground,
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              children: [
                // Arrow beside the title so the header costs no extra
                // height; the subtitle sits in the same column as the title.
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BackChevron(onTap: () => _back(context)),
                    const SizedBox(width: 6),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'New analysis',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Palette.ink,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Pick filters, then generate charts',
                            style: TextStyle(
                              fontSize: 12,
                              color: Palette.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const SectionLabel(text: 'ANALYSIS MODE'),
                const SizedBox(height: 10),
                DropdownCard<AnalysisMode>(
                  value: app.mode,
                  options: AnalysisMode.values,
                  labelBuilder: (m) => _modeLabels[m]!,
                  onChanged: app.selectMode,
                ),
                if (showStateSection || showStateRowOnly) ...[
                  const SizedBox(height: 22),
                  SectionLabel(
                    text: showStateSection ? 'COMPARE STATES' : 'STATE',
                  ),
                  const SizedBox(height: 10),
                  _StateSectionCard(app: app, withToggle: showStateSection),
                ],
                if (showSectorSection) ...[
                  const SizedBox(height: 22),
                  const SectionLabel(text: 'ECONOMIC SECTOR'),
                  const SizedBox(height: 10),
                  DropdownCard<Sector>(
                    value: app.sector,
                    options: Sector.values,
                    labelBuilder: (s) => s.label,
                    onChanged: app.selectSector,
                  ),
                ],
                if (showYearSection) ...[
                  const SizedBox(height: 22),
                  const SectionLabel(text: 'YEAR'),
                  const SizedBox(height: 10),
                  DropdownCard<int>(
                    value: app.year,
                    options: repo.years.reversed.toList(),
                    labelBuilder: (y) => '$y',
                    onChanged: app.selectYear,
                  ),
                ],
                const SizedBox(height: 30),
                _GenerateButton(onTap: () => _generate(context, app)),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Pushes the result page for the selected mode.
  void _generate(BuildContext context, AppState app) {
    Widget route;
    switch (app.mode) {
      case AnalysisMode.stateComparison:
        route = const ComparisonPage();
        break;
      case AnalysisMode.sectorBreakdown:
        route = const BreakdownPage();
        break;
      case AnalysisMode.timeTrend:
        route = const TrendPage();
        break;
      case AnalysisMode.diversityDiagnosis:
        route = const DiversityPage();
        break;
      case AnalysisMode.policyImpact:
        // SafeArea keeps the back row below the status bar
        route = const Scaffold(
          backgroundColor: Palette.ground,
          body: SafeArea(child: PolicyPage()),
        );
        break;
    }
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => route));
  }
}

/// State picker card: State A row, optional
/// compare toggle, and State B row when the toggle is on.
class _StateSectionCard extends StatelessWidget {
  const _StateSectionCard({required this.app, required this.withToggle});

  final AppState app;

  /// False for breakdown/trend modes, which only show the single row.
  final bool withToggle;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      radius: 16,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'State A',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: Palette.muted,
            ),
          ),
          const SizedBox(height: 8),
          _StateInputRow(
            state: app.stateA,
            dotColor: Palette.primary,
            borderColor: Palette.border,
            onTap: () => _pickState(context, isA: true),
          ),
          const SizedBox(height: 8),
          // Only State A: "my location" answers where the user is, and
          // State B is whoever they are comparing themselves against.
          _UseMyLocationButton(onLocated: app.selectStateA),
          if (withToggle) ...[
            const SizedBox(height: 18),
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Compare with a second state',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Palette.ink,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Off = view one state on its own',
                        style: TextStyle(fontSize: 9.5, color: Palette.muted),
                      ),
                    ],
                  ),
                ),
                ToggleSwitch(
                  value: app.compareEnabled,
                  onChanged: app.setCompareEnabled,
                ),
              ],
            ),
            if (app.compareEnabled) ...[
              const SizedBox(height: 14),
              const Text(
                'State B',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: Palette.muted,
                ),
              ),
              const SizedBox(height: 8),
              _StateInputRow(
                state: app.stateB,
                dotColor: Palette.cyan,
                borderColor: Palette.primary,
                onTap: () => _pickState(context, isA: false),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Future<void> _pickState(BuildContext context, {required bool isA}) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => OptionSheet<String>(
        options: GdpRepository.canonicalStates,
        current: isA ? app.stateA : app.stateB,
      ),
    );
    if (picked == null) return;
    if (isA) {
      app.selectStateA(picked);
    } else {
      app.selectStateB(picked);
    }
  }
}

/// Fills the State A row from the device's GPS, so a user analysing
/// their own state does not have to find it in a list of sixteen.
///
/// Uses the same [LocationService] and [StateLocator] as the grants
/// Browse page; the rule for turning a fix into a state lives there and
/// is not repeated here.
class _UseMyLocationButton extends StatefulWidget {
  const _UseMyLocationButton({required this.onLocated});

  /// Called with the canonical state name once a fix resolves to one.
  final ValueChanged<String> onLocated;

  @override
  State<_UseMyLocationButton> createState() => _UseMyLocationButtonState();
}

class _UseMyLocationButtonState extends State<_UseMyLocationButton> {
  bool _busy = false;

  /// Loaded on the first tap and kept: the centroid list never changes.
  StateLocator? _locator;

  Future<void> _locate() async {
    setState(() => _busy = true);
    final result = await context.read<AppState>().location.current();
    final locator = _locator ??= await StateLocator.load();
    if (!mounted) return;

    final point = result.point;
    final state = point == null ? null : locator.nearest(point);
    setState(() => _busy = false);
    if (state == null) {
      _say(locationFailureMessage(result.failure));
      return;
    }
    widget.onLocated(state);
    // The row may already have said this state, so say it out loud
    // rather than leaving a tap that looks like it did nothing.
    _say('Located you in $state.');
  }


  void _say(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        onTap: _busy ? null : _locate,
        behavior: HitTestBehavior.opaque,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // the spinner takes the icon's place so the row never
            // changes width mid-tap
            SizedBox(
              width: 13,
              height: 13,
              child: _busy
                  ? const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Palette.primary,
                    )
                  : const Icon(
                      Icons.near_me_outlined,
                      size: 13,
                      color: Palette.primary,
                    ),
            ),
            const SizedBox(width: 6),
            const Text(
              'Use my location',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Palette.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One bordered input row: colour dot + state name + chevron.
class _StateInputRow extends StatelessWidget {
  const _StateInputRow({
    required this.state,
    required this.dotColor,
    required this.borderColor,
    required this.onTap,
  });

  final String state;
  final Color dotColor;
  final Color borderColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Palette.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                state,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: Palette.ink,
                ),
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Palette.primary,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

/// The gradient "Generate Analysis" button.
class _GenerateButton extends StatelessWidget {
  const _GenerateButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: Palette.gradHero,
          borderRadius: BorderRadius.circular(25),
          boxShadow: const [Palette.heroShadow],
        ),
        child: const Text(
          'Generate Analysis',
          style: TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
