import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/grant_eligibility.dart';
import '../../models/grant.dart';
import '../../state/app_state.dart';
import '../../ui/palette.dart';
import '../../widgets/app_card.dart';
import '../../widgets/back_chevron.dart';

/// Grants · My applications — the signed-in user's own submissions,
/// newest first (the repository already sorts this way).
class MyApplicationsPage extends StatefulWidget {
  const MyApplicationsPage({super.key});

  @override
  State<MyApplicationsPage> createState() => _MyApplicationsPageState();
}

class _MyApplicationsPageState extends State<MyApplicationsPage> {
  late Future<_ApplicationsView> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  /// Applications plus a best-effort id -> grant-name lookup, built from
  /// [GrantRepository.available] since the contract has no single-grant
  /// getter. A grant that has since closed or passed its deadline will
  /// not resolve here, so the row falls back to a short label built
  /// from the application's own grant id.
  Future<_ApplicationsView> _load() async {
    final grants = context.read<AppState>().grants;
    final applications = await grants.myApplications();
    final open = await grants.available();
    final names = {for (final g in open) g.id: g.name};
    return _ApplicationsView(applications, names);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.ground,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BackChevron(onTap: () => Navigator.of(context).pop()),
                const SizedBox(width: 6),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'My applications',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Palette.ink,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Every grant you have applied to, newest first',
                        style: TextStyle(fontSize: 12, color: Palette.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FutureBuilder<_ApplicationsView>(
              future: _future,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 60),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final view = snapshot.data!;
                if (view.applications.isEmpty) {
                  return const _EmptyState();
                }
                return Column(
                  children: [
                    for (final application in view.applications) ...[
                      _ApplicationRow(
                        application: application,
                        grantName: view.nameOf(application.grantId),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Bundles the two async reads [_MyApplicationsPageState._load] needs.
class _ApplicationsView {
  const _ApplicationsView(this.applications, this.grantNames);

  final List<GrantApplication> applications;
  final Map<String, String> grantNames;

  /// The grant's name, or a short stub built from its id when the grant
  /// has since closed and dropped out of the open list.
  String nameOf(String grantId) {
    final known = grantNames[grantId];
    if (known != null) return known;
    final head = grantId.length <= 8 ? grantId : grantId.substring(0, 8);
    return 'Grant #$head';
  }
}

/// One application: project name, its grant, amount, submitted date,
/// and a three-state status chip.
class _ApplicationRow extends StatelessWidget {
  const _ApplicationRow({required this.application, required this.grantName});

  final GrantApplication application;
  final String grantName;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      radius: 16,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  application.projectName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Palette.ink,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _StatusChip(status: application.status),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            grantName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: Palette.muted),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                formatRinggit(application.requestedAmountRm),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Palette.ink,
                ),
              ),
              const Spacer(),
              Text(
                'Submitted ${formatDate(application.submittedAt)}',
                style: const TextStyle(fontSize: 10.5, color: Palette.faint),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The pending / approved / rejected chip, each a distinct Palette pair
/// so the three states never read as two.
class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final ApplicationStatus status;

  @override
  Widget build(BuildContext context) {
    late final Color background;
    late final Color foreground;
    late final String label;
    switch (status) {
      case ApplicationStatus.pending:
        background = Palette.chipCyanBg;
        foreground = Palette.cyanText;
        label = 'Pending';
        break;
      case ApplicationStatus.approved:
        background = Palette.chipGreenBg;
        foreground = Palette.green;
        label = 'Approved';
        break;
      case ApplicationStatus.rejected:
        background = Palette.riskBg;
        foreground = Palette.riskText;
        label = 'Rejected';
        break;
    }
    return Container(
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            color: foreground,
          ),
        ),
      ),
    );
  }
}

/// Shown when the user has never applied to a grant.
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 40),
      child: Text(
        "You haven't applied to any grants yet. Browse open grants to "
        'get started.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 12, color: Palette.muted, height: 1.5),
      ),
    );
  }
}
