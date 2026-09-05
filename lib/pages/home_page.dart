import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/gdp_repository.dart';
import '../models/analysis_request.dart';
import '../models/sector.dart';
import '../state/app_state.dart';
import '../ui/palette.dart';
import '../widgets/app_card.dart';
import '../widgets/icon_chip.dart';

/// Home tab: greeting, hero CTA, stat cards and quick analysis shortcuts.
class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required this.onStartAnalysis,
    required this.onProfile,
  });

  /// Switches the shell to the Analyze tab.
  final VoidCallback onStartAnalysis;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, app, child) {
        // SafeArea keeps the greeting clear of the status bar.
        return SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            children: [
              const SizedBox(height: 10),
              _Greeting(
                onProfile: onProfile,
              ),
              const SizedBox(height: 20),
              _HeroCta(
                onTap: onStartAnalysis,
                yearCount: app.repository.years.length,
              ),
              const SizedBox(height: 12),
              _StatRow(yearCount: app.repository.years.length),
              const SizedBox(height: 28),
              const Text(
                'Quick analysis',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Palette.ink,
                ),
              ),
              const SizedBox(height: 12),
              _QuickCard(
                title: 'Compare States',
                subtitle: 'Side-by-side metrics for any two states',
                background: Palette.chipPeri,
                icon: const Icon(
                  Icons.bar_chart_rounded,
                  size: 19,
                  color: Palette.primary,
                ),
                onTap: () {
                  app.selectMode(AnalysisMode.stateComparison);
                  onStartAnalysis();
                },
              ),
              const SizedBox(height: 10),
              _QuickCard(
                title: 'Trend Analysis',
                subtitle: 'Industrial GDP growth over time',
                background: Palette.chipGreenBg,
                icon: const Icon(
                  Icons.trending_up_rounded,
                  size: 19,
                  color: Palette.green,
                ),
                onTap: () {
                  app.selectMode(AnalysisMode.timeTrend);
                  onStartAnalysis();
                },
              ),
              const SizedBox(height: 10),
              _QuickCard(
                title: 'Diversity Diagnosis',
                subtitle: "How balanced is a state's economy",
                background: Palette.chipCyanBg,
                icon: const Icon(
                  Icons.speed_rounded,
                  size: 19,
                  color: Palette.accentLight,
                ),
                onTap: () {
                  app.selectMode(AnalysisMode.diversityDiagnosis);
                  onStartAnalysis();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

/// "Good morning," + "Ready to analyze?" with the avatar on the right.
class _Greeting extends StatelessWidget {
  const _Greeting({
    required this.onProfile,
  });

  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good morning,',
                style: TextStyle(fontSize: 14, color: Palette.muted),
              ),
              SizedBox(height: 2),
              Text(
                'Ready to analyze?',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Palette.ink,
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: onProfile,
          child: const CircleAvatar(
            radius: 20,
            backgroundColor: Palette.chipPeri,
            child: Icon(
              Icons.person_outline_rounded,
              color: Palette.periText,
              size: 22,
            ),
          ),
        ),
      ],
    );
  }
}

/// Gradient "Start Analysis" banner.
class _HeroCta extends StatelessWidget {
  const _HeroCta({required this.onTap, required this.yearCount});

  final VoidCallback onTap;

  /// How many years the loaded snapshot covers.
  final int yearCount;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 116,
        padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
        decoration: BoxDecoration(
          gradient: Palette.gradHero,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [Palette.heroShadow],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Start Analysis',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  // counted from the data, not typed in, so the line
                  // cannot drift from what the app actually loaded
                  '${GdpRepository.canonicalStates.length} states · '
                  '$yearCount years · ${Sector.values.length} sectors',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
            Positioned(
              right: 0,
              top: 6,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The three 1/3-width stat cards: States / Years / Sectors.
///
/// Every figure is counted from the data so the cards stay honest if the
/// snapshot gains a year or the sector list changes.
class _StatRow extends StatelessWidget {
  const _StatRow({required this.yearCount});

  /// How many years the loaded snapshot covers.
  final int yearCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatCard(
          value: '${GdpRepository.canonicalStates.length}',
          label: 'States',
          background: Palette.chipPeri,
          icon: const Icon(
            Icons.grid_view_rounded,
            size: 12,
            color: Palette.primary,
          ),
        ),
        const SizedBox(width: 10),
        _StatCard(
          value: '$yearCount',
          label: 'Years',
          background: Palette.chipGreenBg,
          icon: const Icon(
            Icons.schedule_rounded,
            size: 12,
            color: Palette.green,
          ),
        ),
        const SizedBox(width: 10),
        _StatCard(
          value: '${Sector.values.length}',
          label: 'Sectors',
          background: Palette.chipCyanBg,
          icon: const Icon(
            Icons.pie_chart_outline_rounded,
            size: 12,
            color: Palette.accentLight,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    required this.background,
    required this.icon,
  });

  final String value;
  final String label;
  final Color background;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AppCard(
        radius: 18,
        child: SizedBox(
          height: 92,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconChip(
                  size: 22,
                  radius: 7,
                  iconSize: 12,
                  background: background,
                  icon: icon,
                ),
                const Spacer(),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Palette.ink,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(fontSize: 10, color: Palette.muted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One quick-analysis shortcut card.
class _QuickCard extends StatelessWidget {
  const _QuickCard({
    required this.title,
    required this.subtitle,
    required this.background,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final Color background;
  final Widget icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      radius: 18,
      onTap: onTap,
      child: SizedBox(
        height: 64,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              IconChip(
                size: 40,
                radius: 13,
                iconSize: 19,
                background: background,
                icon: icon,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Palette.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 10,
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
  }
}
