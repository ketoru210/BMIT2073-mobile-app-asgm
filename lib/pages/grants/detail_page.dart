import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../data/gdp_repository.dart';
import '../../data/grant_eligibility.dart';
import '../../models/grant.dart';
import '../../models/sector.dart';
import '../../state/app_state.dart';
import '../../ui/palette.dart';
import '../../widgets/app_card.dart';
import '../../widgets/back_chevron.dart';
import '../../widgets/dropdown_card.dart';
import '../../widgets/icon_chip.dart';
import 'my_applications_page.dart';

/// Grants · Detail — grant information, the live eligibility verdict,
/// and the apply form.
///
/// [state] / [sector] are the caller's analysis context; they seed the
/// form's own state/sector fields but are otherwise independent of them,
/// since an applicant may apply for a different state or sector than
/// the one they were analysing.
class DetailPage extends StatefulWidget {
  const DetailPage({super.key, required this.grant, this.state, this.sector});

  final Grant grant;
  final String? state;
  final Sector? sector;

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  late bool _formOpen;
  late String _formState;
  late Sector _formSector;
  int? _requestedAmount;
  String? _error;

  /// True while an application is in flight. The repository assigns a
  /// fresh id per insert and has no de-duplication, so a double tap
  /// would file the same application twice without this guard.
  bool _submitting = false;

  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _formOpen = false;
    // The form starts from the caller's analysis context when it has
    // one, so the eligibility checklist shown on load matches what the
    // user was just looking at, rather than an arbitrary default.
    // Without a caller context, seed from the grant's own restriction:
    // a manufacturing-only grant should not open showing a sector that
    // fails its own criteria.
    _formState =
        widget.state ??
        widget.grant.state ??
        GdpRepository.canonicalStates.first;
    _formSector = widget.sector ?? widget.grant.sector ?? Sector.values.first;
    _amountController.addListener(_onAmountChanged);
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
    _nameController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _onAmountChanged() {
    // Re-evaluate eligibility on every keystroke so the Amount check
    // flips live from `unknown` to pass/fail as typing happens.
    setState(() {
      _requestedAmount = int.tryParse(_amountController.text);
    });
  }

  EligibilityResult get _result => GrantEligibility.evaluate(
    grant: widget.grant,
    state: _formState,
    sector: _formSector,
    requestedAmountRm: _requestedAmount,
    asOf: DateTime.now(),
  );

  @override
  Widget build(BuildContext context) {
    final grant = widget.grant;
    final result = _result;

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
                Expanded(
                  child: Text(
                    grant.name,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: Palette.ink,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _InfoCard(grant: grant),
            const SizedBox(height: 12),
            _EligibilityCard(result: result),
            const SizedBox(height: 12),
            _ApplyButton(
              open: _formOpen,
              onTap: () => setState(() => _formOpen = !_formOpen),
            ),
            if (_formOpen) ...[
              const SizedBox(height: 12),
              _ApplyForm(
                submitting: _submitting,
                nameController: _nameController,
                amountController: _amountController,
                noteController: _noteController,
                formState: _formState,
                formSector: _formSector,
                error: _error,
                onStateChanged: (s) => setState(() => _formState = s),
                onSectorChanged: (s) => setState(() => _formSector = s),
                onSubmit: _submit,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final name = _nameController.text.trim();
    final amount = int.tryParse(_amountController.text);

    if (name.isEmpty) {
      setState(() => _error = 'Enter a project name.');
      return;
    }
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Enter a requested amount greater than zero.');
      return;
    }

    final userId = context.read<AppState>().users.userId;
    if (userId == null) {
      setState(() => _error = 'Sign in to submit an application.');
      return;
    }

    final application = GrantApplication.draft(
      grantId: widget.grant.id,
      userId: userId,
      projectName: name,
      state: _formState,
      sector: _formSector,
      requestedAmountRm: amount,
      note: _noteController.text.trim(),
    );

    setState(() {
      _submitting = true;
      _error = null;
    });
    await context.read<AppState>().grants.apply(application);
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Application submitted.')));
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const MyApplicationsPage()),
    );
  }
}

/// Grant information: description, criteria note, source, and deadline.
class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.grant});

  final Grant grant;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      radius: 20,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            grant.agency,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Palette.periText,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            grant.description,
            style: const TextStyle(
              fontSize: 12.5,
              color: Palette.body,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            grant.criteriaNote,
            style: const TextStyle(
              fontSize: 11,
              color: Palette.faint,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Palette.gridline),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.event_outlined, size: 14, color: Palette.ghost),
              const SizedBox(width: 6),
              Text(
                'Deadline ${formatDate(grant.deadline)}',
                style: const TextStyle(fontSize: 11, color: Palette.muted),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.link_rounded, size: 14, color: Palette.ghost),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  grant.sourceUrl,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: Palette.muted),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Eligibility summary plus every check, one row each.
class _EligibilityCard extends StatelessWidget {
  const _EligibilityCard({required this.result});

  final EligibilityResult result;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      radius: 20,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Eligibility',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Palette.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            result.summary,
            style: const TextStyle(fontSize: 11.5, color: Palette.body),
          ),
          const SizedBox(height: 8),
          for (final check in result.checks) _CheckRow(check: check),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// One eligibility row: pass / fail / unknown, each visually distinct.
class _CheckRow extends StatelessWidget {
  const _CheckRow({required this.check});

  final EligibilityCheck check;

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color foreground;
    Color background;
    switch (check.outcome) {
      case CheckOutcome.pass:
        icon = Icons.check_circle_rounded;
        foreground = Palette.green;
        background = Palette.chipGreenBg;
        break;
      case CheckOutcome.fail:
        icon = Icons.cancel_rounded;
        foreground = Palette.riskText;
        background = Palette.riskBg;
        break;
      case CheckOutcome.unknown:
        icon = Icons.help_rounded;
        foreground = Palette.muted;
        background = Palette.gridline;
        break;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconChip(
            size: 22,
            radius: 7,
            iconSize: 14,
            background: background,
            icon: Icon(icon, color: foreground, size: 14),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  check.label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Palette.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  check.detail,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Palette.body,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Apply button — always enabled; ineligibility is surfaced above it,
/// never by disabling this control.
class _ApplyButton extends StatelessWidget {
  const _ApplyButton({required this.open, required this.onTap});

  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: Palette.gradHero,
          borderRadius: BorderRadius.circular(25),
          boxShadow: const [Palette.heroShadow],
        ),
        child: Text(
          open ? 'Hide application form' : 'Apply',
          style: const TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

/// The apply form: fixed demo-disclaimer banner, then project name,
/// state, sector, requested amount and a short note.
class _ApplyForm extends StatelessWidget {
  const _ApplyForm({
    required this.submitting,
    required this.nameController,
    required this.amountController,
    required this.noteController,
    required this.formState,
    required this.formSector,
    required this.error,
    required this.onStateChanged,
    required this.onSectorChanged,
    required this.onSubmit,
  });

  final bool submitting;
  final TextEditingController nameController;
  final TextEditingController amountController;
  final TextEditingController noteController;
  final String formState;
  final Sector formSector;
  final String? error;
  final ValueChanged<String> onStateChanged;
  final ValueChanged<Sector> onSectorChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      radius: 20,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fixed banner — required verbatim by the F6 spec so nobody
          // mistakes this for a real government application channel.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Palette.riskBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'Demo only — not an official application channel.',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Palette.riskText,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const _FieldLabel('Project name'),
          const SizedBox(height: 6),
          _TextField(
            controller: nameController,
            hint: 'e.g. Line automation upgrade',
          ),
          const SizedBox(height: 14),
          const _FieldLabel('State'),
          const SizedBox(height: 6),
          DropdownCard<String>(
            value: formState,
            options: GdpRepository.canonicalStates,
            onChanged: onStateChanged,
          ),
          const SizedBox(height: 14),
          const _FieldLabel('Sector'),
          const SizedBox(height: 6),
          DropdownCard<Sector>(
            value: formSector,
            options: Sector.values,
            labelBuilder: (s) => s.label,
            onChanged: onSectorChanged,
          ),
          const SizedBox(height: 14),
          const _FieldLabel('Requested amount (RM)'),
          const SizedBox(height: 6),
          _TextField(
            controller: amountController,
            hint: 'e.g. 250000',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 14),
          const _FieldLabel('Short note'),
          const SizedBox(height: 6),
          _TextField(
            controller: noteController,
            hint: 'Briefly describe the project',
            maxLines: 3,
          ),
          if (error != null) ...[
            const SizedBox(height: 10),
            Text(
              error!,
              style: const TextStyle(fontSize: 11.5, color: Palette.riskText),
            ),
          ],
          const SizedBox(height: 16),
          _SubmitButton(onTap: onSubmit, submitting: submitting),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.w600,
        color: Palette.muted,
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  const _TextField({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.inputFormatters,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 13.5, color: Palette.ink),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: Palette.ghost),
        filled: true,
        fillColor: Palette.card,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Palette.border, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Palette.border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Palette.primary, width: 1.5),
        ),
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({required this.onTap, required this.submitting});

  final VoidCallback onTap;

  /// Dims the button and drops the tap handler while the insert runs.
  final bool submitting;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: submitting ? null : onTap,
      child: Container(
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: submitting ? Palette.ghost : Palette.primary,
          borderRadius: BorderRadius.circular(23),
        ),
        child: Text(
          submitting ? 'Submitting…' : 'Submit application',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
