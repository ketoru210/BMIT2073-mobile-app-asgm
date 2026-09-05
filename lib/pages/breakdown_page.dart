import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/csv_export.dart';
import '../data/gdp_repository.dart';
import '../data/metrics.dart';
import '../models/grant.dart';
import '../models/sector.dart';
import '../state/app_state.dart';
import '../ui/palette.dart';
import '../widgets/app_card.dart';
import '../widgets/dropdown_card.dart';
import '../widgets/hero_band.dart';
import '../widgets/icon_chip.dart';
import '../widgets/insight_strip.dart';
import 'grants/browse_page.dart';

/// Mode 2 · Sector Breakdown: one state, one year — KPI, a donut of
/// every sector, and two insight lines.
class BreakdownPage extends StatelessWidget {
  const BreakdownPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, app, child) {
        final repo = app.repository;
        final state = app.stateA;
        final year = app.year;

        return Scaffold(
          backgroundColor: Palette.ground,
          body: ListView(
            padding: EdgeInsets.zero,
            children: [
              HeroBand(
                gradient: Palette.gradDetail,
                height: 210,
                eyebrow: 'ANALYSIS RESULT · SECTOR BREAKDOWN',
                title: state,
                titleSize: 27,
                trailing: _YearPill(
                  year: year,
                  onTap: () => _pickYear(context, app),
                ),
                footer: const _CompositionChip(),
                onExport: () => _exportCsv(context, app),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _KpiCard(state: state, year: year),
                    const SizedBox(height: 12),
                    _DonutCard(state: state, year: year),
                    const SizedBox(height: 12),
                    InsightStrip(lines: _insightLines(repo, state, year)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickYear(BuildContext context, AppState app) async {
    final picked = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => OptionSheet<int>(
        options: app.repository.years.reversed.toList(),
        current: app.year,
        labelBuilder: (y) => '$y',
      ),
    );
    if (picked != null) app.selectYear(picked);
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

/// The "YYYY ⌄" year pill inside the hero band.
class _YearPill extends StatelessWidget {
  const _YearPill({required this.year, required this.onTap});

  final int year;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$year',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 3),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}

/// The "Sector composition" chip under the hero title.
class _CompositionChip extends StatelessWidget {
  const _CompositionChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Text(
          'Sector composition',
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

/// How many years the sparkline shows. It is a layout choice — the
/// 120px strip fits about this many points before they merge — not a
/// property of the data.
const _sparklineYears = 6;

/// KPI card: total in RM B, growth chip, and a sparkline of the last
/// [_sparklineYears] years.
class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.state, required this.year});

  final String state;
  final int year;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, app, child) {
        final repo = app.repository;
        final total = repo.totalValue(state: state, year: year);
        final growth = stateTotalYoY(repo, state, year);
        final years = repo.recentYears(_sparklineYears);
        final series = [
          for (final y in years)
            repo.totalValue(state: state, year: y) == null
                ? null
                : repo.totalValue(state: state, year: y)! / 1000,
        ];

        return AppCard(
          radius: 20,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'INDUSTRIAL GDP · $year',
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: Palette.faint,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      total == null ? '—' : formatRm(total),
                      style: const TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w700,
                        color: Palette.ink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (growth != null) _GrowthChip(growth: growth, year: year),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 120,
                    height: 40,
                    child: _Sparkline(series: series),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${years.first} – ${years.last}',
                    style: const TextStyle(fontSize: 8, color: Palette.ghost),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Green chip with a ▲/▼ growth vs the previous year.
class _GrowthChip extends StatelessWidget {
  const _GrowthChip({required this.growth, required this.year});

  final double growth;
  final int year;

  @override
  Widget build(BuildContext context) {
    final up = growth >= 0;
    return Container(
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Palette.chipGreenBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          '${up ? '▲' : '▼'} ${growth.abs().toStringAsFixed(1)}% vs ${year - 1}',
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Palette.green,
          ),
        ),
      ),
    );
  }
}

/// Mini line chart of the recent totals; only the last point is drawn,
/// solid primary.
class _Sparkline extends StatelessWidget {
  const _Sparkline({required this.series});

  final List<double?> series;

  @override
  Widget build(BuildContext context) {
    final valid = <double>[
      for (final v in series)
        if (v != null) v,
    ];
    if (valid.isEmpty) return const SizedBox.shrink();
    final minY = valid.reduce((a, b) => a < b ? a : b) * 0.95;
    final maxY = valid.reduce((a, b) => a > b ? a : b) * 1.05;

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (series.length - 1).toDouble(),
        minY: minY,
        maxY: maxY,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var x = 0; x < series.length; x++)
                series[x] == null
                    ? FlSpot.nullSpot
                    : FlSpot(x.toDouble(), series[x]!),
            ],
            color: Palette.primary,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              checkToShowDot: (spot, bar) =>
                  spot.y.isFinite && spot.x == (series.length - 1).toDouble(),
              getDotPainter: (spot, xPercentage, bar, index) =>
                  FlDotCirclePainter(
                    radius: 3,
                    color: Palette.primary,
                    strokeWidth: 0,
                  ),
            ),
            belowBarData: BarAreaData(show: false),
          ),
        ],
      ),
    );
  }
}

/// Donut card: ~20-thick ring with the year in the centre and a legend
/// of every sector that has a value this year.
///
/// Stateful so a legend row can be tapped to "drill down" into that one
/// sector — the drill-down detail is where the F6 grants hook card
/// lives, per the feature plan's sector-breakdown entry point.
class _DonutCard extends StatefulWidget {
  const _DonutCard({required this.state, required this.year});

  final String state;
  final int year;

  @override
  State<_DonutCard> createState() => _DonutCardState();
}

class _DonutCardState extends State<_DonutCard> {
  /// The legend row currently drilled into, if any. Page-local UI state,
  /// not part of AppState — it resets whenever the state/year underneath
  /// it changes, so a stale sector never lingers after the user picks a
  /// different state or year.
  Sector? _drilled;

  @override
  void didUpdateWidget(covariant _DonutCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state || oldWidget.year != widget.year) {
      _drilled = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final year = widget.year;
    return Consumer<AppState>(
      builder: (context, app, child) {
        final repo = app.repository;
        final total = repo.totalValue(state: state, year: year);
        final sectors =
            <Sector>[
              for (final s in Sector.values)
                if (repo.sectorValue(state: state, sector: s, year: year) !=
                    null)
                  s,
            ]..sort((a, b) {
              final va = repo.sectorValue(state: state, sector: a, year: year)!;
              final vb = repo.sectorValue(state: state, sector: b, year: year)!;
              return vb.compareTo(va);
            });

        return AppCard(
          radius: 20,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sector distribution',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Palette.ink,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (sectors.isNotEmpty)
                          PieChart(
                            PieChartData(
                              sectionsSpace: 0,
                              centerSpaceRadius: 30,
                              sections: [
                                for (final s in sectors)
                                  PieChartSectionData(
                                    value: repo.sectorValue(
                                      state: state,
                                      sector: s,
                                      year: year,
                                    )!,
                                    color: Palette.sectorColors[s],
                                    // Section radius is the ring width, so
                                    // centre + ring has to stay within the
                                    // box's half-extent (30 + 20 = 50).
                                    radius: 20,
                                    showTitle: false,
                                  ),
                              ],
                            ),
                          ),
                        Text(
                          '$year',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Palette.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      children: [
                        for (final s in sectors) _legendRow(repo, total, s),
                      ],
                    ),
                  ),
                ],
              ),
              if (_drilled != null) ...[
                const SizedBox(height: 14),
                _GrantsHookCard(state: state, sector: _drilled!),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _legendRow(GdpRepository repo, double? total, Sector sector) {
    final value = repo.sectorValue(
      state: widget.state,
      sector: sector,
      year: widget.year,
    );
    final share = total == null || total <= 0 || value == null
        ? null
        : value / total * 100;
    final selected = _drilled == sector;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _drilled = selected ? null : sector),
      child: Container(
        height: 22,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: selected ? Palette.chipPeri : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: Palette.sectorColors[sector],
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                sector.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11.5, color: Palette.body),
              ),
            ),
            Text(
              share == null ? '—' : '${share.toStringAsFixed(0)}%',
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: Palette.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// F6 hook card: "N grants available" for the drilled-down (state,
/// sector) pair, tapping through to the filtered grants browse page.
///
/// The count always comes from a real [GrantRepository.available] call
/// — never a literal — per the feature plan's ban on hardcoded numbers.
class _GrantsHookCard extends StatefulWidget {
  const _GrantsHookCard({required this.state, required this.sector});

  final String state;
  final Sector sector;

  @override
  State<_GrantsHookCard> createState() => _GrantsHookCardState();
}

class _GrantsHookCardState extends State<_GrantsHookCard> {
  late Future<List<Grant>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant _GrantsHookCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state || oldWidget.sector != widget.sector) {
      _load();
    }
  }

  void _load() {
    _future = context.read<AppState>().grants.available(
      state: widget.state,
      sector: widget.sector,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Grant>>(
      future: _future,
      builder: (context, snapshot) {
        final count = snapshot.data?.length;
        return AppCard(
          radius: 16,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) =>
                  BrowsePage(state: widget.state, sector: widget.sector),
            ),
          ),
          child: SizedBox(
            height: 60,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  const IconChip(
                    size: 36,
                    radius: 12,
                    iconSize: 17,
                    background: Palette.chipGreenBg,
                    icon: Icon(
                      Icons.volunteer_activism_rounded,
                      color: Palette.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          count == null
                              ? 'Checking grants…'
                              : '$count grant${count == 1 ? '' : 's'} available',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Palette.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.state} · ${widget.sector.label}',
                          style: const TextStyle(
                            fontSize: 9.5,
                            color: Palette.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: Palette.ghost,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Two computed insight lines: the top sector's
/// share and the second sector's share.
List<String> _insightLines(GdpRepository repo, String state, int year) {
  final total = repo.totalValue(state: state, year: year);
  if (total == null || total <= 0) {
    return ['No data is available for $state in $year yet.'];
  }

  final sectors =
      <Sector>[
        for (final s in Sector.values)
          if (repo.sectorValue(state: state, sector: s, year: year) != null) s,
      ]..sort((a, b) {
        final va = repo.sectorValue(state: state, sector: a, year: year)!;
        final vb = repo.sectorValue(state: state, sector: b, year: year)!;
        return vb.compareTo(va);
      });
  if (sectors.isEmpty) {
    return ['No sector data is available for $state in $year yet.'];
  }

  final top = sectors.first;
  final topShare =
      repo.sectorValue(state: state, sector: top, year: year)! / total * 100;
  final line1 =
      '${top.label} drives ${topShare.toStringAsFixed(1)}% of $state’s output';
  if (sectors.length < 2) return [line1];

  final second = sectors[1];
  final secondShare =
      repo.sectorValue(state: state, sector: second, year: year)! / total * 100;
  final line2 =
      'with ${second.label.toLowerCase()} a distant second at '
      '${secondShare.toStringAsFixed(1)}%.';
  return [line1, line2];
}
