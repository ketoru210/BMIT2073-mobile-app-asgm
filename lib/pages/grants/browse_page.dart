import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/grant_eligibility.dart';
import '../../models/grant.dart';
import '../../models/sector.dart';
import '../../state/app_state.dart';
import '../../ui/palette.dart';
import '../../widgets/app_card.dart';
import '../../widgets/back_chevron.dart';
import 'detail_page.dart';
import 'my_applications_page.dart';

/// Grants · Browse — the user-facing entry point into F6.
///
/// [state] and [sector] carry the analysis context the caller drilled in
/// from (e.g. the Breakdown page's hook card); either may be null when
/// this page is opened without a filter. Clearing the filter is local
/// page state only — it never mutates [AppState], since the filter here
/// is a view of the grants list, not a change to the user's analysis.
class BrowsePage extends StatefulWidget {
  const BrowsePage({super.key, this.state, this.sector});

  final String? state;
  final Sector? sector;

  @override
  State<BrowsePage> createState() => _BrowsePageState();
}

class _BrowsePageState extends State<BrowsePage> {
  /// Whether the incoming analysis-context filter is still applied.
  /// Starts true whenever a filter was actually supplied.
  late bool _filtered;
  late Future<List<Grant>> _future;

  bool get _hasContext => widget.state != null || widget.sector != null;

  @override
  void initState() {
    super.initState();
    _filtered = _hasContext;
    _load();
  }

  /// Set once in [initState] (and again when the filter is cleared),
  /// not built inline in [build] — matches how the other async-reading
  /// pages in this app load, avoiding a fresh Future (and a refetch) on
  /// every rebuild.
  void _load() {
    final grants = context.read<AppState>().grants;
    _future = _filtered
        ? grants.available(state: widget.state, sector: widget.sector)
        : grants.available();
  }

  /// Two-way, not a one-shot clear: a user who widens the list to every
  /// open grant can put their analysis context back without navigating
  /// away and drilling in again.
  void _toggleFilter() {
    setState(() {
      _filtered = !_filtered;
      _load();
    });
  }

  String get _contextLabel {
    final parts = <String>[
      if (widget.state != null) widget.state!,
      if (widget.sector != null) widget.sector!.label,
    ];
    return parts.join(' · ');
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
                        'Grants',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Palette.ink,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Browse open funding you may qualify for',
                        style: TextStyle(fontSize: 12, color: Palette.muted),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'My applications',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const MyApplicationsPage(),
                    ),
                  ),
                  icon: const Icon(
                    Icons.assignment_outlined,
                    color: Palette.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_hasContext)
              _ContextBar(
                filtered: _filtered,
                label: _contextLabel,
                onToggle: _toggleFilter,
              ),
            const SizedBox(height: 14),
            FutureBuilder<List<Grant>>(
              future: _future,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 60),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final grants = snapshot.data!;
                if (grants.isEmpty) {
                  return _EmptyState(
                    filtered: _filtered && _hasContext,
                    label: _contextLabel,
                  );
                }
                return Column(
                  children: [
                    for (final grant in grants) ...[
                      _GrantRow(
                        grant: grant,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => DetailPage(
                              grant: grant,
                              state: widget.state,
                              sector: widget.sector,
                            ),
                          ),
                        ),
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

/// The pill showing the active analysis-context filter, plus the
/// control that switches between it and every open grant.
class _ContextBar extends StatelessWidget {
  const _ContextBar({
    required this.filtered,
    required this.label,
    required this.onToggle,
  });

  final bool filtered;
  final String label;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Palette.chipPeri,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.filter_alt_rounded,
                  size: 14,
                  color: Palette.periText,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    filtered ? label : 'Showing all open grants',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: Palette.periText,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onToggle,
          child: Text(
            filtered ? 'Clear' : 'Reapply',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Palette.primary,
            ),
          ),
        ),
      ],
    );
  }
}

/// One grant row: name, agency, deadline, and the ringgit ceiling.
class _GrantRow extends StatelessWidget {
  const _GrantRow({required this.grant, required this.onTap});

  final Grant grant;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      radius: 16,
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            grant.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Palette.ink,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            grant.agency,
            style: const TextStyle(fontSize: 11, color: Palette.muted),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.event_outlined, size: 13, color: Palette.ghost),
              const SizedBox(width: 4),
              Text(
                'Closes ${formatDate(grant.deadline)}',
                style: const TextStyle(fontSize: 10.5, color: Palette.faint),
              ),
              const Spacer(),
              Text(
                grant.maxAmountRm == null
                    ? 'No stated ceiling'
                    : 'Up to ${formatRinggit(grant.maxAmountRm!)}',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: Palette.ink,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Explains, in a real sentence, why the list is empty — a narrowed
/// filter reads very differently from there being no grants at all.
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.filtered, required this.label});

  final bool filtered;
  final String label;

  @override
  Widget build(BuildContext context) {
    final message = filtered
        ? 'No open grants match $label right now. Clear the filter to '
              'see every grant currently open.'
        : 'There are no open grants at the moment. Check back once an '
              'admin publishes one.';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 12, color: Palette.muted, height: 1.5),
      ),
    );
  }
}
