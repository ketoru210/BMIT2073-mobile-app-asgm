import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/grant_eligibility.dart';
import '../../models/grant_reminder.dart';
import '../../models/sector.dart';
import '../../state/app_state.dart';
import '../../ui/palette.dart';
import '../../widgets/app_card.dart';
import '../../widgets/toggle_switch.dart';

/// What the reminder sheet hands back when the user saves.
typedef _ReminderOptions = ({
  bool includeAllStates,
  bool includeAllSectors,
  int? minAmountRm,
});

/// Grants · Browse card for a state and sector with no grant aimed at them.
///
/// Offers Set reminder, or shows the waiting reminder's options with
/// Cancel. The reminder is read once when the card appears; the repository
/// is the source of truth, so leaving and re-entering the page reloads it.
class GrantReminderCard extends StatefulWidget {
  const GrantReminderCard({
    super.key,
    required this.state,
    required this.sector,
    required this.label,
  });

  final String state;
  final Sector sector;

  /// "State · Sector", as the Browse filter pill shows it.
  final String label;

  @override
  State<GrantReminderCard> createState() => _GrantReminderCardState();
}

class _GrantReminderCardState extends State<GrantReminderCard> {
  GrantReminder? _reminder;
  bool _loading = true;

  /// True while a set or cancel is in flight, so a double tap cannot write
  /// twice.
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final reminders = context.read<AppState>().reminders;
    try {
      final found = await reminders.find(
        state: widget.state,
        sector: widget.sector,
      );
      if (!mounted) return;
      setState(() {
        _reminder = found;
        _loading = false;
      });
    } catch (_) {
      // an unreadable reminder falls back to offering a new one
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _set() async {
    final app = context.read<AppState>();
    final messenger = ScaffoldMessenger.of(context);
    final options = await showModalBottomSheet<_ReminderOptions>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReminderSheet(label: widget.label),
    );
    if (options == null || !mounted) return;

    setState(() => _busy = true);
    try {
      // Asked first, but the reminder is saved either way: refusing the
      // prompt should not silently lose what the user asked for.
      final allowed = await app.notifications.requestPermission();
      final reminder = await app.reminders.create(
        state: widget.state,
        sector: widget.sector,
        includeAllStates: options.includeAllStates,
        includeAllSectors: options.includeAllSectors,
        minAmountRm: options.minAmountRm,
      );
      if (!mounted) return;
      setState(() => _reminder = reminder);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            allowed
                ? "We'll notify you when a grant opens for ${widget.label}."
                : 'Reminder saved. Turn on notifications in Settings to '
                      'get alerted.',
          ),
        ),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Unable to set the reminder. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancel() async {
    final reminder = _reminder;
    if (reminder == null) return;
    final app = context.read<AppState>();
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await app.reminders.cancel(reminder.id);
      if (!mounted) return;
      setState(() => _reminder = null);
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Unable to cancel the reminder. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// One line naming the options the waiting reminder was set with.
  String _describe(GrantReminder reminder) {
    final minimum = reminder.minAmountRm;
    final parts = <String>[
      if (reminder.includeAllStates) 'Nationwide included',
      if (reminder.includeAllSectors) 'Any sector included',
      if (minimum != null) 'At least ${formatRinggit(minimum)}',
    ];
    return parts.isEmpty
        ? 'Only grants aimed at this state and sector.'
        : parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();

    final signedIn = context.read<AppState>().users.userId != null;
    final reminder = _reminder;

    final String title;
    final String subtitle;
    final String? action;
    final VoidCallback? onAction;
    if (!signedIn) {
      title = 'No grants just for ${widget.label} yet';
      subtitle = 'Log in to get notified when one opens.';
      action = null;
      onAction = null;
    } else if (reminder == null) {
      title = 'No grants just for ${widget.label} yet';
      subtitle = 'Set a reminder to hear when one is published.';
      action = 'Set reminder';
      onAction = _set;
    } else {
      title = 'Reminder on for ${widget.label}';
      subtitle = _describe(reminder);
      action = 'Cancel';
      onAction = _cancel;
    }

    return AppCard(
      radius: 16,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Palette.chipPeri,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              reminder == null
                  ? Icons.notifications_none_rounded
                  : Icons.notifications_on_rounded,
              size: 18,
              color: Palette.periText,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Palette.ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Palette.muted,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          if (action != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _busy ? null : onAction,
              child: Text(
                action,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Palette.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Bottom sheet for the reminder's options.
///
/// Owns its amount controller so the controller is disposed with the sheet,
/// not left to whoever opened it.
class _ReminderSheet extends StatefulWidget {
  const _ReminderSheet({required this.label});

  final String label;

  @override
  State<_ReminderSheet> createState() => _ReminderSheetState();
}

class _ReminderSheetState extends State<_ReminderSheet> {
  final _amountController = TextEditingController();
  bool _includeAllStates = false;
  bool _includeAllSectors = false;
  String? _error;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _save() {
    final text = _amountController.text.trim();
    final amount = text.isEmpty ? null : int.tryParse(text);
    if (text.isNotEmpty && (amount == null || amount <= 0)) {
      setState(() => _error = 'Enter a whole number of ringgit.');
      return;
    }
    Navigator.of(context).pop<_ReminderOptions>((
      includeAllStates: _includeAllStates,
      includeAllSectors: _includeAllSectors,
      minAmountRm: amount,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // keeps the amount field above the keyboard
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Palette.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reminder for ${widget.label}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Palette.ink,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              "We'll notify you when a new grant that fits is published.",
              style: TextStyle(fontSize: 11.5, color: Palette.muted),
            ),
            const SizedBox(height: 18),
            _OptionRow(
              label: 'Include nationwide grants',
              value: _includeAllStates,
              onChanged: (value) => setState(() => _includeAllStates = value),
            ),
            const SizedBox(height: 12),
            _OptionRow(
              label: 'Include grants open to any sector',
              value: _includeAllSectors,
              onChanged: (value) => setState(() => _includeAllSectors = value),
            ),
            const SizedBox(height: 18),
            const Text(
              'Minimum amount (RM)',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: Palette.muted,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Any amount',
                hintStyle: const TextStyle(fontSize: 13, color: Palette.faint),
                errorText: _error,
                filled: true,
                fillColor: Palette.ground,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 13,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Palette.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Palette.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Palette.primary,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 22),
            GestureDetector(
              onTap: _save,
              child: Container(
                height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: Palette.gradHero,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: const [Palette.heroShadow],
                ),
                child: const Text(
                  'Save reminder',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A labelled on/off option in the reminder sheet.
class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Palette.ink,
            ),
          ),
        ),
        ToggleSwitch(value: value, onChanged: onChanged),
      ],
    );
  }
}
