import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/grant_eligibility.dart';
import '../../data/location_service.dart';
import '../../data/state_locator.dart';
import '../../models/grant.dart';
import '../../models/sector.dart';
import '../../state/app_state.dart';
import '../../ui/palette.dart';
import '../../widgets/app_card.dart';
import '../../widgets/back_chevron.dart';
import 'detail_page.dart';
import 'my_applications_page.dart';
import 'reminder_card.dart';

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

  /// The state the device was last found in, or null while the page is
  /// running on the analysis context it was opened with.
  String? _locatedState;
  bool _locating = false;

  /// Loaded on the first "Near me" tap and kept for the rest of the page's
  /// life; the centroid list never changes.
  StateLocator? _locator;

  /// The state every part of this page works from: a location fix wins
  /// over the context the page was opened with, so the reminder card, the
  /// empty state and the apply form all follow the user's position.
  String? get _state => _locatedState ?? widget.state;

  bool get _hasContext => _state != null || widget.sector != null;

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
        ? grants.available(state: _state, sector: widget.sector)
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

  /// Takes a fix, resolves it to a state, and narrows the list to it.
  /// A second tap hands the page back to its original context.
  ///
  /// Every failure is a snackbar and nothing else: a user who cannot be
  /// located still has the list they came in with.
  Future<void> _nearMe() async {
    if (_locatedState != null) {
      setState(() {
        _locatedState = null;
        _filtered = widget.state != null || widget.sector != null;
        _load();
      });
      return;
    }

    setState(() => _locating = true);
    final result = await context.read<AppState>().location.current();
    final locator = _locator ??= await StateLocator.load();
    if (!mounted) return;

    final point = result.point;
    final state = point == null ? null : locator.nearest(point);
    setState(() {
      _locating = false;
      if (state != null) {
        _locatedState = state;
        _filtered = true;
        _load();
      }
    });
    if (state == null) _say(_failureMessage(result.failure));
  }

  /// Why the fix did not happen, in the user's words. A fix that arrived
  /// but landed outside the country is the `null` case.
  String _failureMessage(LocationFailure? failure) {
    switch (failure) {
      case LocationFailure.permissionDenied:
        return 'Location permission denied.';
      case LocationFailure.serviceDisabled:
        return 'Turn on location to use this.';
      case LocationFailure.noFix:
        return 'Could not get a location fix.';
      case null:
        return 'You do not appear to be in Malaysia.';
    }
  }

  void _say(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String get _contextLabel {
    final parts = <String>[
      if (_state != null) _state!,
      if (widget.sector != null) widget.sector!.label,
    ];
    return parts.join(' · ');
  }

  /// A reminder is offered when the list is narrowed to a full state and
  /// sector pair and nothing in it is aimed at exactly that pair.
  ///
  /// Nationwide and any-sector grants still list, but do not count: one
  /// such grant is open to every pair, and would otherwise hide the
  /// reminder everywhere.
  bool _offersReminder(List<Grant> grants) {
    final state = _state;
    final sector = widget.sector;
    if (!_filtered || state == null || sector == null) return false;
    return !grants.any((g) => g.state == state && g.sector == sector);
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
            Row(
              children: [
                if (_hasContext)
                  Expanded(
                    child: _ContextBar(
                      filtered: _filtered,
                      located: _locatedState != null,
                      label: _contextLabel,
                      onToggle: _toggleFilter,
                    ),
                  )
                else
                  const Spacer(),
                const SizedBox(width: 10),
                _NearMeButton(
                  active: _locatedState != null,
                  busy: _locating,
                  onTap: _locating ? null : _nearMe,
                ),
              ],
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
                return Column(
                  children: [
                    if (_offersReminder(grants)) ...[
                      GrantReminderCard(
                        state: _state!,
                        sector: widget.sector!,
                        label: _contextLabel,
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (grants.isEmpty)
                      _EmptyState(
                        filtered: _filtered && _hasContext,
                        label: _contextLabel,
                      )
                    else
                      for (final grant in grants) ...[
                        _GrantRow(
                          grant: grant,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => DetailPage(
                                grant: grant,
                                state: _state,
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
    required this.located,
    required this.label,
    required this.onToggle,
  });

  final bool filtered;

  /// True when [label] describes where the device is rather than where
  /// the user drilled in from; only the icon changes.
  final bool located;
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
                Icon(
                  located ? Icons.my_location : Icons.filter_alt_rounded,
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

/// The control that swaps the analysis context for the device's own
/// state, and swaps it back.
class _NearMeButton extends StatelessWidget {
  const _NearMeButton({
    required this.active,
    required this.busy,
    required this.onTap,
  });

  final bool active;
  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = active ? Colors.white : Palette.periText;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: active ? Palette.primary : Palette.chipPeri,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // the spinner takes the icon's place so the pill never
            // changes width mid-tap
            SizedBox(
              width: 14,
              height: 14,
              child: busy
                  ? CircularProgressIndicator(strokeWidth: 2, color: foreground)
                  : Icon(Icons.near_me_outlined, size: 14, color: foreground),
            ),
            const SizedBox(width: 6),
            Text(
              active ? 'Located' : 'Near me',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: foreground,
              ),
            ),
          ],
        ),
      ),
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
