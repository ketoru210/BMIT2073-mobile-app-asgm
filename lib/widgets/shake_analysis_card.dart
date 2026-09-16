import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/insights.dart';
import '../data/shake_detector.dart';
import '../models/analysis_request.dart';
import '../pages/filter_page.dart';
import '../state/app_state.dart';
import '../ui/palette.dart';
import 'app_card.dart';

/// Human label for every [AnalysisMode], for the roll sheet's header.
const Map<AnalysisMode, String> _modeLabels = {
  AnalysisMode.stateComparison: 'State Comparison',
  AnalysisMode.sectorBreakdown: 'Sector Breakdown',
  AnalysisMode.timeTrend: 'Time Trend',
  AnalysisMode.diversityDiagnosis: 'Diversity Diagnosis',
  AnalysisMode.policyImpact: 'Policy Impact',
};

/// Home entry point for a random analysis.
///
/// The card itself listens to nothing: the accelerometer is only read
/// while the sheet it opens is on screen. A phone that rolls an analysis
/// every time it is put down in a pocket would be worse than no feature
/// at all, and a sensor stream that runs for the life of the Home tab
/// costs battery for a gesture nobody asked for yet.
class ShakeAnalysisCard extends StatefulWidget {
  const ShakeAnalysisCard({super.key, this.shakes, this.random});

  /// One event per shake. Injected by tests; the sheet builds its own
  /// from the accelerometer.
  final Stream<void>? shakes;

  /// Injected by tests so a roll is reproducible.
  final Random? random;

  @override
  State<ShakeAnalysisCard> createState() => _ShakeAnalysisCardState();
}

class _ShakeAnalysisCardState extends State<ShakeAnalysisCard> {
  /// Opens the sheet, which is where shaking starts being listened for.
  Future<void> _open() async {
    final app = context.read<AppState>();
    final rolled = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _RollSheet(shakes: widget.shakes, random: widget.random),
    );
    if (!mounted || rolled != true) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => analysisPageFor(app.mode)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      radius: 16,
      onTap: _open,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Palette.chipPeri,
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.casino_rounded,
              size: 19,
              color: Palette.primary,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Feeling lucky?',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Palette.ink,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Tap, then shake for a random analysis',
                  style: TextStyle(fontSize: 11, color: Palette.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The roll in one line, naming only what the chosen mode actually uses.
///
/// Every mode reads a different slice of the filter — Time Trend plots
/// every year, Diversity ranks every state — so printing the whole roll
/// would promise the result page things it does not show.
String _rollLabel(AppState app) {
  final mode = _modeLabels[app.mode];
  switch (app.mode) {
    case AnalysisMode.stateComparison:
      return '$mode · ${app.stateA} vs ${app.stateB} · ${app.year}';
    case AnalysisMode.sectorBreakdown:
      return '$mode · ${app.stateA} · ${app.year}';
    case AnalysisMode.timeTrend:
      return '$mode · ${app.stateA} · ${app.sector.label}';
    case AnalysisMode.diversityDiagnosis:
      // the page ranks every state; naming the rolled one keeps the
      // header and the insight below it talking about the same place
      return '$mode · ${app.stateA} among all 16 · ${app.year}';
    case AnalysisMode.policyImpact:
      // never rolled, but the switch has to be total
      return '$mode · ${app.stateA}';
  }
}

/// Asks for a shake, then shows what it rolled and one fact about it.
///
/// The accelerometer is subscribed here and nowhere else, so it starts
/// when the sheet opens and stops when it closes.
class _RollSheet extends StatefulWidget {
  const _RollSheet({this.shakes, this.random});

  final Stream<void>? shakes;
  final Random? random;

  @override
  State<_RollSheet> createState() => _RollSheetState();
}

class _RollSheetState extends State<_RollSheet> {
  StreamSubscription<void>? _subscription;

  /// False until the first roll: the sheet opens asking for a shake.
  bool _rolled = false;

  @override
  void initState() {
    super.initState();
    _listen();
  }

  /// Sensors are not available on every platform this app builds for, and
  /// a missing accelerometer must not take the sheet down with it — the
  /// button below works either way.
  void _listen() {
    try {
      final stream = widget.shakes ?? ShakeDetector().shakes();
      _subscription = stream.listen((_) {
        if (mounted) _roll();
      });
    } catch (error) {
      debugPrint('Shake detection unavailable: $error');
    }
  }

  @override
  void dispose() {
    // without this the sensor keeps streaming after the sheet is gone
    _subscription?.cancel();
    super.dispose();
  }

  void _roll() {
    context.read<AppState>().randomize(widget.random);
    setState(() => _rolled = true);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final insight = _rolled
        ? randomInsight(
            app.repository,
            state: app.stateA,
            sector: app.sector,
            year: app.year,
            random: widget.random,
          )
        : null;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
      decoration: const BoxDecoration(
        color: Palette.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: Palette.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _rolled ? 'YOUR RANDOM ANALYSIS' : 'FEELING LUCKY?',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              color: Palette.faint,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _rolled ? _rollLabel(app) : 'Shake your phone',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Palette.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _rolled
                ? 'Shake again for another one.'
                : 'Or use the button below — a phone in a stand cannot be '
                      'shaken, and neither can an emulator.',
            style: const TextStyle(
              fontSize: 11,
              height: 1.4,
              color: Palette.muted,
            ),
          ),
          const SizedBox(height: 14),
          // No insight at all beats a made-up one: some state-year cells
          // in the source are simply empty.
          if (insight != null)
            Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              decoration: BoxDecoration(
                color: Palette.chipGreenBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.lightbulb_outline_rounded,
                    size: 16,
                    color: Palette.green,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      insight.text,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.45,
                        color: Palette.body,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: _SheetButton(
                  label: _rolled ? 'Roll again' : 'Roll for me',
                  filled: !_rolled,
                  onTap: _roll,
                ),
              ),
              if (_rolled) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: _SheetButton(
                    label: 'Open analysis',
                    filled: true,
                    onTap: () => Navigator.of(context).pop(true),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _SheetButton extends StatelessWidget {
  const _SheetButton({
    required this.label,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? Palette.primary : Palette.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Palette.primary, width: 1.5),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: filled ? Colors.white : Palette.primary,
          ),
        ),
      ),
    );
  }
}
