import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/csv_export.dart';
import '../data/gdp_repository.dart';
import '../data/metrics.dart';
import '../models/sector.dart';
import '../state/app_state.dart';
import '../ui/palette.dart';
import '../widgets/app_card.dart';
import '../widgets/back_chevron.dart';
import '../widgets/insight_strip.dart';

/// Mode 3 · Time Trend: one state, one sector over the full year range.
class TrendPage extends StatelessWidget {
  const TrendPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, app, child) {
        final repo = app.repository;
        final state = app.stateA;
        final sector = app.sector;
        final years = repo.years;

        return Scaffold(
          backgroundColor: Palette.ground,
          body: ListView(
            padding: EdgeInsets.zero,
            children: [
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          BackChevron(
                            onTap: () => Navigator.of(context).maybePop(),
                          ),
                          const Spacer(),
                          IconButton(
                            tooltip: 'Export CSV',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                            onPressed: () => _exportCsv(context, app),
                            icon: const Icon(
                              Icons.ios_share_rounded,
                              color: Palette.ink,
                              size: 26,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'ANALYSIS RESULT · TIME TREND',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          color: Palette.faint,
                          letterSpacing: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$state ${sector.label.toLowerCase()}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Palette.ink,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${years.first} – ${years.last}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Palette.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _AreaCard(state: state, sector: sector),
                    const SizedBox(height: 12),
                    InsightStrip(
                      lines: _insightLines(repo, state, sector, years),
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

  /// Shares the current selection as CSV; a SnackBar covers failure so
  /// the export never crashes the page.
  Future<void> _exportCsv(BuildContext context, AppState app) async {
    final ok = await CsvExport.share(app.repository, app.generate());
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not share the CSV export.')),
      );
    }
  }
}

/// The area chart card: gradArea fill, dashed
/// gridlines, every-other-year x labels.
class _AreaCard extends StatelessWidget {
  const _AreaCard({required this.state, required this.sector});

  final String state;
  final Sector sector;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, app, child) {
        final repo = app.repository;
        final years = repo.years;
        final values = [
          for (final y in years)
            repo.sectorValue(state: state, sector: sector, year: y) == null
                ? null
                : repo.sectorValue(state: state, sector: sector, year: y)! /
                      1000,
        ];

        return AppCard(
          radius: 20,
          padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Industrial GDP over time',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Palette.ink,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'RM billion · ${sector.label.toLowerCase()}',
                style: const TextStyle(fontSize: 10, color: Palette.faint),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 240,
                child: LineChart(_chartData(years, values)),
              ),
            ],
          ),
        );
      },
    );
  }

  LineChartData _chartData(List<int> years, List<double?> values) {
    final valid = <double>[
      for (final v in values)
        if (v != null) v,
    ];
    final maxY = valid.isEmpty
        ? 1.0
        : valid.reduce((a, b) => a > b ? a : b) * 1.15;
    final interval = maxY / 4;

    return LineChartData(
      minX: 0,
      maxX: (years.length - 1).toDouble(),
      minY: 0,
      maxY: maxY,
      gridData: FlGridData(
        drawVerticalLine: false,
        horizontalInterval: interval,
        getDrawingHorizontalLine: (value) => const FlLine(
          color: Palette.gridline,
          strokeWidth: 1,
          dashArray: [3, 4],
        ),
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
              if (i < 0 || i >= years.length || i.isOdd) {
                return const SizedBox.shrink();
              }
              // short label: '15 '17 '19 ...
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  "'${(years[i] % 100).toString().padLeft(2, '0')}",
                  style: const TextStyle(fontSize: 9, color: Palette.ghost),
                ),
              );
            },
          ),
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: [
            for (var x = 0; x < years.length; x++)
              values[x] == null
                  ? FlSpot.nullSpot
                  : FlSpot(x.toDouble(), values[x]!),
          ],
          color: Palette.primary,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, xPercentage, bar, index) =>
                FlDotCirclePainter(
                  // the last point gets a bigger dot
                  radius: index == values.length - 1 ? 5 : 4,
                  color: Colors.white,
                  strokeWidth: 2.5,
                  strokeColor: Palette.primary,
                ),
            checkToShowDot: (spot, bar) => spot.y.isFinite,
          ),
          belowBarData: BarAreaData(show: true, gradient: Palette.gradArea),
        ),
      ],
    );
  }
}

/// Two computed insight lines: consecutive
/// growth since a year, then the cumulative change across the whole
/// span the snapshot covers.
List<String> _insightLines(
  GdpRepository repo,
  String state,
  Sector sector,
  List<int> years,
) {
  final sectorName = sector.label.toLowerCase();
  final since = consecutiveGrowthSince(repo, state, sector);
  final line1 = since != null
      ? '$state $sectorName has grown every year since $since'
      : '$state $sectorName grew in '
            '${_positiveGrowthCount(repo, state, sector)} of the last '
            '${years.length - 1} years';

  final cum = cumulativeGrowth(repo, state, sector, years.first, years.last);
  // the span is measured, not called "the decade" — the snapshot may
  // cover more or fewer years than ten
  final span = years.last - years.first;
  final line2 = cum == null
      ? null
      : 'up ${cum.round()}% over $span years';

  return [line1, if (line2 != null) line2];
}

/// How many years (from the second year on) had positive growth.
int _positiveGrowthCount(GdpRepository repo, String state, Sector sector) {
  final years = repo.years;
  var count = 0;
  for (var i = 1; i < years.length; i++) {
    final g = repo.growth(state: state, sector: sector, year: years[i]);
    if (g != null && g > 0) count++;
  }
  return count;
}
