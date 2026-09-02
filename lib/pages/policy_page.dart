import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/policy_metrics.dart';
import '../models/policy_record.dart';
import '../models/sector.dart';
import '../state/app_state.dart';
import '../ui/palette.dart';
import '../widgets/back_chevron.dart';
import '../widgets/insight_strip.dart';

/// Policy Impact: pick a policy, see the target sector's national trend
/// around its effective year (association, not causation).
class PolicyPage extends StatelessWidget {
  const PolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, app, child) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (Navigator.of(context).canPop())
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    BackChevron(onTap: () => Navigator.of(context).maybePop()),
                    const Text(
                      'Policy catalogue',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Palette.ink,
                      ),
                    ),
                  ],
                ),
              )
            else
              const Text(
                'Policy catalogue',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Palette.ink,
                ),
              ),
            const SizedBox(height: 4),
            const Text(
              'Malaysian industrial policies and the sector they target. '
              'Tap one to see the before/after picture.',
              style: TextStyle(fontSize: 12, color: Palette.muted),
            ),
            const SizedBox(height: 4),
            Text(
              app.catalogue.label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Palette.primary,
              ),
            ),
            const SizedBox(height: 12),
            for (final policy in app.policies) _PolicyCard(policy: policy),
          ],
        );
      },
    );
  }
}

/// One catalogue entry: name, effective year, target sectors, summary.
class _PolicyCard extends StatelessWidget {
  const _PolicyCard({required this.policy});

  final PolicyRecord policy;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => PolicyDetailPage(policy: policy),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      policy.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Palette.ink,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _YearChip(year: policy.effectiveYear),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final s in policy.targetSectors) _SectorChip(sector: s),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                policy.summary,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: Palette.muted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 10),
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 14,
                    color: Palette.primary,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'View impact',
                    style: TextStyle(fontSize: 12, color: Palette.primary),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "since 2023" style pill on each policy card.
class _YearChip extends StatelessWidget {
  const _YearChip({required this.year});

  final int year;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Palette.primary.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'since $year',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Palette.primary,
        ),
      ),
    );
  }
}

/// Small outlined chip for one target sector.
class _SectorChip extends StatelessWidget {
  const _SectorChip({required this.sector});

  final Sector sector;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: Palette.muted.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        sector.label,
        style: const TextStyle(fontSize: 11, color: Palette.muted),
      ),
    );
  }
}

/// Detail for one policy: national YoY trend of its first target sector
/// with the effective year marked, plus the before/after comparison.
class PolicyDetailPage extends StatelessWidget {
  const PolicyDetailPage({super.key, required this.policy});

  final PolicyRecord policy;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, app, child) {
        final repo = app.repository;
        final sector = policy.targetSectors.first;
        final years = repo.years;
        final yoy = nationalYoY(repo, sector);
        final growth = growthAroundPolicy(
          repo,
          sector: sector,
          effectiveYear: policy.effectiveYear,
        );

        final spots = <FlSpot>[
          for (var i = 0; i < years.length; i++)
            if (yoy[i] != null) FlSpot(i.toDouble(), yoy[i]!),
        ];

        return Scaffold(
          backgroundColor: Palette.ground,
          appBar: AppBar(
            backgroundColor: Palette.ground,
            elevation: 0,
            foregroundColor: Palette.ink,
            title: Text(policy.abbreviation),
            actions: [
              IconButton(
                tooltip: 'Save as favourite',
                icon: const Icon(Icons.bookmark_add_outlined),
                onPressed: () async {
                  app.selectPolicy(policy);
                  await app.saveCurrentFavorite();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Saved to favourites')),
                    );
                  }
                },
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        policy.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Palette.ink,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final s in policy.targetSectors)
                            _SectorChip(sector: s),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        policy.summary,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Palette.muted,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SelectableText(
                        policy.sourceUrl,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Palette.primary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'National ${sector.label.toLowerCase()} growth '
                        '(year-on-year %)',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Palette.ink,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 230,
                        child: LineChart(_chartData(spots, years)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              InsightStrip(text: _insight(policy, growth, sector)),
            ],
          ),
        );
      },
    );
  }

  /// Growth line with a zero baseline and the policy year marked.
  LineChartData _chartData(List<FlSpot> spots, List<int> years) {
    final markX = (policy.effectiveYear - years.first).toDouble();
    return LineChartData(
      gridData: const FlGridData(show: true, drawVerticalLine: false),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 28,
            getTitlesWidget: (value, meta) {
              final i = value.toInt();
              // every other year keeps the axis readable
              if (!i.isEven && i != years.length - 1) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '${years[i]}',
                  style: const TextStyle(fontSize: 10, color: Palette.muted),
                ),
              );
            },
          ),
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: false,
          color: Palette.primary,
          barWidth: 2.5,
          dotData: const FlDotData(show: true),
          belowBarData: BarAreaData(show: false),
        ),
      ],
      extraLinesData: ExtraLinesData(
        horizontalLines: [
          HorizontalLine(
            y: 0,
            color: Palette.muted.withValues(alpha: 0.5),
            dashArray: [4, 4],
          ),
        ],
        verticalLines: [
          VerticalLine(
            x: markX,
            color: Palette.ink,
            strokeWidth: 1.5,
            dashArray: [6, 4],
            label: VerticalLineLabel(
              show: true,
              labelResolver: (line) => policy.abbreviation,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Palette.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Before/after comparison, written as one honest sentence.
  String _insight(PolicyRecord p, PolicyGrowth g, Sector sector) {
    final after = g.afterAvg;
    if (after == null) {
      return '${p.abbreviation} took effect in ${p.effectiveYear} and no '
          'post-policy data exists yet, so this chart shows the national '
          '${sector.label.toLowerCase()} trend only.';
    }
    final afterPart =
        '${_signed(after)}%/yr in the ${g.afterYears} '
        'year${g.afterYears == 1 ? '' : 's'} after';
    final before = g.beforeAvg;
    if (before == null) {
      return 'Too little pre-policy data for a fair comparison. National '
          '${sector.label.toLowerCase()} growth averaged $afterPart '
          '${p.abbreviation} took effect (${p.effectiveYear}) — an '
          'association, not a proven causal effect.';
    }
    return 'National ${sector.label.toLowerCase()} growth averaged '
        '${_signed(before)}%/yr in the 3 years before ${p.abbreviation} '
        '(${p.effectiveYear}) vs $afterPart — an association, not a proven '
        'causal effect.';
  }

  String _signed(double v) => '${v >= 0 ? '+' : ''}${v.toStringAsFixed(1)}';
}
