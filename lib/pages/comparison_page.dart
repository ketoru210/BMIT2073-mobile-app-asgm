import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/gdp_repository.dart';
import '../data/metrics.dart';
import '../models/sector.dart';
import '../state/app_state.dart';
import '../ui/palette.dart';
import '../widgets/app_card.dart';
import '../widgets/dropdown_card.dart';
import '../widgets/hero_band.dart';
import '../widgets/insight_strip.dart';
import '../widgets/state_pill.dart';

/// Mode 1 · State Comparison: two states side by side
class ComparisonPage extends StatelessWidget {
  const ComparisonPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, app, child) {
        final states = app.compareEnabled
            ? [app.stateA, app.stateB]
            : [app.stateA];
        final year = app.year;
        final sector = app.sector;

        return Scaffold(
          backgroundColor: Palette.ground,
          body: ListView(
            padding: EdgeInsets.zero,
            children: [
              HeroBand(
                eyebrow: 'ANALYSIS RESULT · STATE COMPARISON',
                title: states.length == 2
                    ? '${states[0]} vs ${states[1]}'
                    : states[0],
                subtitle: '${sector.label} · $year',
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: StatePill(
                            state: states[0],
                            dotColor: Palette.primary,
                            onTap: () => _pickState(context, app, isA: true),
                          ),
                        ),
                        if (states.length == 2) ...[
                          const SizedBox(width: 10),
                          Expanded(
                            child: StatePill(
                              state: states[1],
                              dotColor: Palette.cyan,
                              onTap: () => _pickState(context, app, isA: false),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    _StatsTable(states: states, year: year, sector: sector),
                    const SizedBox(height: 12),
                    _TrendCard(states: states, year: year, sector: sector),
                    const SizedBox(height: 12),
                    InsightStrip(
                      lines: _insightLines(app, states, year, sector),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickState(
    BuildContext context,
    AppState app, {
    required bool isA,
  }) async {
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

/// The three-row metrics table.
class _StatsTable extends StatelessWidget {
  const _StatsTable({
    required this.states,
    required this.year,
    required this.sector,
  });

  final List<String> states;
  final int year;
  final Sector sector;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, app, child) {
        final repo = app.repository;

        double? totalOf(String s) => repo.totalValue(state: s, year: year);
        double? growthOf(String s) => stateTotalYoY(repo, s, year);
        double? shareOf(String s) => nationalShare(repo, s, year);

        return AppCard(
          radius: 20,
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
          child: Column(
            children: [
              _headerRow(),
              const SizedBox(height: 9),
              const Divider(height: 1, color: Palette.gridline),
              const SizedBox(height: 9),
              _row('GDP $year (RM B)', [
                for (final s in states) formatRm(totalOf(s) ?? 0.0),
              ]),
              _row('Growth YoY', [for (final s in states) _pct(growthOf(s))]),
              _row('National share', [
                for (final s in states)
                  shareOf(s) == null
                      ? '—'
                      : '${shareOf(s)!.toStringAsFixed(1)}%',
              ]),
            ],
          ),
        );
      },
    );
  }

  Widget _headerRow() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'METRIC',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Palette.faint,
              letterSpacing: 0.6,
            ),
          ),
        ),
        for (var i = 0; i < states.length; i++)
          SizedBox(
            width: 96,
            child: Text(
              states[i],
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: i == 0 ? Palette.periText : Palette.cyanText,
              ),
            ),
          ),
      ],
    );
  }

  Widget _row(String label, List<String> values) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Palette.body),
            ),
          ),
          for (final v in values)
            SizedBox(
              width: 96,
              child: Text(
                v,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Palette.ink,
                ),
              ),
            ),
        ],
      ),
    );
  }

  static String _pct(double? v) =>
      v == null ? '—' : '${v >= 0 ? '+' : ''}${v.toStringAsFixed(1)}%';
}

/// How many years the dual-line chart shows. A layout choice — six
/// x-labels are what fits the card width — not a property of the data.
const _trendYears = 6;

/// Dual-line trend chart card: the last [_trendYears] years, state A
/// primary and state B cyan.
class _TrendCard extends StatelessWidget {
  const _TrendCard({
    required this.states,
    required this.year,
    required this.sector,
  });

  final List<String> states;
  final int year;
  final Sector sector;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, app, child) {
        final repo = app.repository;
        final years = repo.recentYears(_trendYears);
        // chart values are in RM billion (source is RM million)
        final series = [
          for (final s in states)
            [
              for (final y in years)
                repo.sectorValue(state: s, sector: sector, year: y) == null
                    ? null
                    : repo.sectorValue(state: s, sector: sector, year: y)! /
                          1000,
            ],
        ];

        return AppCard(
          radius: 20,
          padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Industrial GDP trend',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Palette.ink,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'RM billion · ${years.first} – ${years.last}',
                style: const TextStyle(fontSize: 10, color: Palette.faint),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 138,
                child: LineChart(_chartData(years, series)),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _legendDot(Palette.primary),
                  const SizedBox(width: 6),
                  Text(
                    states[0],
                    style: const TextStyle(fontSize: 10, color: Palette.body),
                  ),
                  if (states.length == 2) ...[
                    const SizedBox(width: 18),
                    _legendDot(Palette.cyan),
                    const SizedBox(width: 6),
                    Text(
                      states[1],
                      style: const TextStyle(fontSize: 10, color: Palette.body),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _legendDot(Color color) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  LineChartData _chartData(List<int> years, List<List<double?>> series) {
    final all = [
      for (final s in series)
        for (final v in s)
          if (v != null) v,
    ];
    final maxY = all.isEmpty ? 1.0 : all.reduce((a, b) => a > b ? a : b) * 1.15;
    final interval = maxY / 4;

    return LineChartData(
      minX: 0,
      maxX: (years.length - 1).toDouble(),
      minY: 0,
      maxY: maxY,
      gridData: FlGridData(
        drawVerticalLine: false,
        horizontalInterval: interval,
        getDrawingHorizontalLine: (value) =>
            const FlLine(color: Palette.gridline, strokeWidth: 1),
      ),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 38,
            interval: interval,
            getTitlesWidget: (value, meta) => Align(
              alignment: Alignment.centerRight,
              // right gap keeps the label clear of the first data dot,
              // which is drawn on the chart's left edge
              child: Padding(
                padding: const EdgeInsets.only(right: 7),
                child: Text(
                  value.toStringAsFixed(0),
                  style: const TextStyle(fontSize: 8.5, color: Palette.ghost),
                ),
              ),
            ),
          ),
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 24,
            interval: 1,
            getTitlesWidget: (value, meta) {
              final i = value.toInt();
              if (i < 0 || i >= years.length) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '${years[i]}',
                  style: const TextStyle(fontSize: 9, color: Palette.ghost),
                ),
              );
            },
          ),
        ),
      ),
      lineBarsData: [
        for (var i = 0; i < series.length; i++)
          if (series[i].any((v) => v != null))
            LineChartBarData(
              spots: [
                for (var x = 0; x < years.length; x++)
                  series[i][x] == null
                      ? FlSpot.nullSpot
                      : FlSpot(x.toDouble(), series[i][x]!),
              ],
              color: i == 0 ? Palette.primary : Palette.cyan,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, xPercentage, bar, index) =>
                    FlDotCirclePainter(
                      radius: 4,
                      color: Colors.white,
                      strokeWidth: 2.5,
                      strokeColor: i == 0 ? Palette.primary : Palette.cyan,
                    ),
              ),
              belowBarData: BarAreaData(show: false),
            ),
      ],
    );
  }
}

/// Two computed insight lines. X is the state
/// with the larger sector value, so the ratio is always >= 1.
List<String> _insightLines(
  AppState app,
  List<String> states,
  int year,
  Sector sector,
) {
  if (states.length == 1) {
    final value = app.repository.sectorValue(
      state: states[0],
      sector: sector,
      year: year,
    );
    return [
      if (value != null)
        "${states[0]}'s ${sector.label.toLowerCase()} GDP is ${formatRm(value)} in $year.",
    ];
  }

  final repo = app.repository;
  final a = repo.sectorValue(state: states[0], sector: sector, year: year);
  final b = repo.sectorValue(state: states[1], sector: sector, year: year);
  if (a == null || b == null || a <= 0 || b <= 0) {
    return [
      'No ${sector.label.toLowerCase()} data for ${states[0]} or ${states[1]} in $year yet.',
    ];
  }

  final x = a >= b ? states[0] : states[1];
  final y = a >= b ? states[1] : states[0];
  final ratio = a >= b ? a / b : b / a;
  final line1 =
      "$x's ${sector.label.toLowerCase()} output is ${ratio.toStringAsFixed(1)}× $y's in $year";

  final xGrowth = stateTotalYoY(repo, x, year);
  final yGrowth = stateTotalYoY(repo, y, year);
  final line2 = (xGrowth != null && yGrowth != null && yGrowth > xGrowth)
      ? 'though $y is closing the gap.'
      : 'and the gap is widening.';
  return [line1, line2];
}
