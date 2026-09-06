import '../models/grant.dart';
import '../models/sector.dart';

/// Outcome of one criterion.
///
/// Three values, not a bool: a criterion the app cannot check yet
/// (no amount typed, no state chosen) is honestly different from one
/// the applicant fails.
enum CheckOutcome { pass, fail, unknown }

/// One line of the eligibility breakdown shown on the grant detail page.
class EligibilityCheck {
  const EligibilityCheck({
    required this.label,
    required this.outcome,
    required this.detail,
  });

  /// Short name of the criterion, e.g. `State`.
  final String label;

  final CheckOutcome outcome;

  /// The reason, phrased for the applicant. A failing check always says
  /// what the grant requires AND what the applicant's context is, so the
  /// user never has to guess why they were ruled out.
  final String detail;
}

/// The full verdict for one grant against one applicant context.
class EligibilityResult {
  const EligibilityResult(this.checks);

  final List<EligibilityCheck> checks;

  List<EligibilityCheck> get blockers =>
      checks.where((c) => c.outcome == CheckOutcome.fail).toList();

  List<EligibilityCheck> get unchecked =>
      checks.where((c) => c.outcome == CheckOutcome.unknown).toList();

  /// No failing criterion. Unknown ones do not block: the app tells the
  /// user what it could not verify instead of pretending to know.
  bool get isEligible => blockers.isEmpty;

  /// One sentence for the top of the detail page.
  String get summary {
    if (blockers.isNotEmpty) {
      final n = blockers.length;
      return n == 1
          ? 'One condition is not met.'
          : '$n of ${checks.length} conditions are not met.';
    }
    if (unchecked.isNotEmpty) {
      return 'No blocking conditions. '
          '${unchecked.length} still to confirm in the form.';
    }
    return 'Meets all stated conditions.';
  }
}

/// Matches a grant's structural criteria against the user's analysis
/// context.
///
/// This lives in the data layer, not in a widget, because both the browse
/// list and the detail page must reach the same verdict, and because the
/// rules are testable on their own.
///
/// A criterion the grant leaves `null` is unrestricted and always passes —
/// same convention the repository uses when filtering.
class GrantEligibility {
  const GrantEligibility._();

  static EligibilityResult evaluate({
    required Grant grant,
    String? state,
    Sector? sector,
    int? requestedAmountRm,
    DateTime? asOf,
  }) {
    final now = asOf ?? DateTime.now();
    return EligibilityResult([
      _state(grant, state),
      _sector(grant, sector),
      _amount(grant, requestedAmountRm),
      _deadline(grant, now),
    ]);
  }

  static EligibilityCheck _state(Grant grant, String? state) {
    if (grant.state == null) {
      return const EligibilityCheck(
        label: 'State',
        outcome: CheckOutcome.pass,
        detail: 'Open nationwide.',
      );
    }
    if (state == null) {
      return EligibilityCheck(
        label: 'State',
        outcome: CheckOutcome.unknown,
        detail:
            'Restricted to ${grant.state}. '
            'Pick a state in the form to confirm.',
      );
    }
    if (state == grant.state) {
      return EligibilityCheck(
        label: 'State',
        outcome: CheckOutcome.pass,
        detail: 'Your analysis is on ${grant.state}.',
      );
    }
    return EligibilityCheck(
      label: 'State',
      outcome: CheckOutcome.fail,
      detail:
          'Open to ${grant.state} only; '
          'your analysis is on $state.',
    );
  }

  static EligibilityCheck _sector(Grant grant, Sector? sector) {
    if (grant.sector == null) {
      return const EligibilityCheck(
        label: 'Sector',
        outcome: CheckOutcome.pass,
        detail: 'Any sector may apply.',
      );
    }
    if (sector == null) {
      return EligibilityCheck(
        label: 'Sector',
        outcome: CheckOutcome.unknown,
        detail:
            'Limited to ${grant.sector!.label}. '
            'Pick a sector in the form to confirm.',
      );
    }
    if (sector == grant.sector) {
      return EligibilityCheck(
        label: 'Sector',
        outcome: CheckOutcome.pass,
        detail: 'Your analysis is on ${sector.label}.',
      );
    }
    return EligibilityCheck(
      label: 'Sector',
      outcome: CheckOutcome.fail,
      detail:
          'Limited to ${grant.sector!.label}; '
          'your analysis is on ${sector.label}.',
    );
  }

  static EligibilityCheck _amount(Grant grant, int? requested) {
    final cap = grant.maxAmountRm;
    if (cap == null) {
      return const EligibilityCheck(
        label: 'Amount',
        outcome: CheckOutcome.pass,
        detail: 'No stated ceiling.',
      );
    }
    if (requested == null) {
      return EligibilityCheck(
        label: 'Amount',
        outcome: CheckOutcome.unknown,
        detail:
            'Ceiling is ${formatRinggit(cap)}. '
            'Enter an amount to confirm.',
      );
    }
    if (requested <= cap) {
      return EligibilityCheck(
        label: 'Amount',
        outcome: CheckOutcome.pass,
        detail:
            '${formatRinggit(requested)} is within '
            'the ${formatRinggit(cap)} ceiling.',
      );
    }
    return EligibilityCheck(
      label: 'Amount',
      outcome: CheckOutcome.fail,
      detail:
          '${formatRinggit(requested)} exceeds the '
          '${formatRinggit(cap)} ceiling by '
          '${formatRinggit(requested - cap)}.',
    );
  }

  static EligibilityCheck _deadline(Grant grant, DateTime now) {
    // The repository already hides expired grants from available(), but a
    // grant can expire while its detail page is open, so the page checks
    // again rather than trusting a list it fetched earlier.
    final days = grant.deadline.difference(now).inDays;
    if (days < 0) {
      return EligibilityCheck(
        label: 'Deadline',
        outcome: CheckOutcome.fail,
        detail: 'Closed on ${formatDate(grant.deadline)}.',
      );
    }
    return EligibilityCheck(
      label: 'Deadline',
      outcome: CheckOutcome.pass,
      detail: days == 0
          ? 'Closes today.'
          : 'Open for $days more day${days == 1 ? '' : 's'} '
                '(${formatDate(grant.deadline)}).',
    );
  }
}

/// `250000` -> `RM 250,000`. Grants are in actual ringgit, unlike the GDP
/// snapshot, which is in RM million.
String formatRinggit(int amount) {
  final digits = amount.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return 'RM $buffer';
}

/// `2026-09-30` in the app's one date format.
String formatDate(DateTime d) {
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '${d.year}-$m-$day';
}
