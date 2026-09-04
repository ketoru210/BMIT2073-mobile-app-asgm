import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/csv_export.dart';
import '../data/gdp_repository.dart';
import '../data/metrics.dart';
import '../models/sector.dart';
import '../state/app_state.dart';
import '../ui/palette.dart';
import '../widgets/app_card.dart';
import '../widgets/badge_chip.dart';
import '../widgets/hero_band.dart';
import '../widgets/insight_strip.dart';

/// Mode 4 · Diversity Diagnosis: HHI ranking of every state with data
class DiversityPage extends StatelessWidget {
  const DiversityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, app, child) {
        final entries = hhiRanking(app.repository, app.year);

        return Scaffold(
          backgroundColor: Palette.ground,
          body: ListView(
            padding: EdgeInsets.zero,
            children: [
              HeroBand(
                eyebrow: 'ANALYSIS RESULT · DIVERSITY DIAGNOSIS',
                title: 'Economic concentration',
                subtitle: 'All ${entries.length} states · ${app.year} · by HHI',
                onExport: () => _exportCsv(context, app),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _RankingCard(entries: entries),
                    const SizedBox(height: 12),
                    const _HhiFootnote(),
                    const SizedBox(height: 12),
                    InsightStrip(
                      lines: _insightLines(app.repository, entries, app.year),
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

/// The ranking card: one rank row per state, each with a score track
class _RankingCard extends StatelessWidget {
  const _RankingCard({required this.entries});

  final List<HhiEntry> entries;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      radius: 20,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Who’s over-concentrated?',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Palette.ink,
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'Higher score = economy leans on one sector',
            style: TextStyle(fontSize: 10, color: Palette.faint),
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < entries.length; i++)
            _RankRow(entry: entries[i], rank: i + 1),
        ],
      ),
    );
  }
}

/// One ranked state: rank number, name, badge, HHI, and score track.
class _RankRow extends StatelessWidget {
  const _RankRow({required this.entry, required this.rank});

  final HhiEntry entry;

  /// 1-based position in the ranking, drives the track colour.
  final int rank;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(
              '$rank',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Palette.faint,
              ),
            ),
          ),
          SizedBox(
            width: 118,
            child: Text(
              entry.state,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Palette.ink,
              ),
            ),
          ),
          // Cuts come from HhiBands, which derives them from the sector
          // count; the usual 0.25/0.4 pair assumes many more categories
          // and would tag three states in four as Risk.
          if (entry.hhi > HhiBands.risk)
            const BadgeChip(style: BadgeStyle.risk, label: 'Risk')
          else if (entry.hhi < HhiBands.balanced)
            const BadgeChip(style: BadgeStyle.balanced, label: 'Balanced')
          else
            const SizedBox.shrink(),
          const SizedBox(width: 10),
          Expanded(
            child: _Track(hhi: entry.hhi, rank: rank),
          ),
          const SizedBox(width: 10),
          SizedBox(
            // three decimals: at two, 28 adjacent pairs across the
            // eleven years print the same value while carrying
            // different ranks
            width: 48,
            child: Text(
              entry.hhi.toStringAsFixed(3),
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Palette.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The coloured score track; the fill colour follows the rank
/// (1 orange1, 2 orange2, 3 primaryLight, 4+ greenBar).
class _Track extends StatelessWidget {
  const _Track({required this.hhi, required this.rank});

  final double hhi;
  final int rank;

  @override
  Widget build(BuildContext context) {
    final color = rank == 1
        ? Palette.orange1
        : rank == 2
        ? Palette.orange2
        : rank == 3
        ? Palette.primaryLight
        : Palette.greenBar;
    return Container(
      height: 10,
      decoration: BoxDecoration(
        color: Palette.gridline,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: hhi.clamp(0.0, 1.0),
          child: Container(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        ),
      ),
    );
  }
}

/// The HHI formula footnote.
///
/// The lower bound is read from [HhiBands], not typed in, so it stays
/// true if the sector list ever changes.
class _HhiFootnote extends StatelessWidget {
  const _HhiFootnote();

  @override
  Widget build(BuildContext context) {
    final sectorCount = Sector.values.length;
    final floor = HhiBands.floor.toStringAsFixed(3);
    return Text(
      'HHI = Σ(sector share)² · 1/$sectorCount = $floor (even split) '
      'to 1.000 (one sector)',
      style: const TextStyle(fontSize: 9.5, color: Palette.ghost),
    );
  }
}

/// Two computed insight lines: the most
/// concentrated state with its top sectors, then the most balanced one.
List<String> _insightLines(
  GdpRepository repository,
  List<HhiEntry> entries,
  int year,
) {
  if (entries.isEmpty) return ['No HHI data is available for $year yet.'];

  final top = entries.first.state;
  final bottom = entries.last.state;

  String topSectors(String state) {
    final sectors =
        <Sector>[
          for (final s in Sector.values)
            if (repository.sectorValue(state: state, sector: s, year: year) !=
                null)
              s,
        ]..sort((a, b) {
          final va = repository.sectorValue(
            state: state,
            sector: a,
            year: year,
          )!;
          final vb = repository.sectorValue(
            state: state,
            sector: b,
            year: year,
          )!;
          return vb.compareTo(va);
        });
    if (sectors.length < 2) return 'its leading sector';
    return '${sectors[0].label.toLowerCase()} and '
        '${sectors[1].label.toLowerCase()}';
  }

  final line1 = 'Most concentrated: $top (${topSectors(top)}).';

  // how many sectors the most balanced state has data for
  final n = Sector.values
      .where(
        (s) =>
            repository.sectorValue(state: bottom, sector: s, year: year) !=
            null,
      )
      .length;
  final line2 = n >= Sector.values.length
      ? 'Most balanced: $bottom, across all ${Sector.values.length} sectors.'
      : 'Most balanced: $bottom, across $n sectors.';

  return [line1, line2];
}
