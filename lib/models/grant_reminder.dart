import 'grant.dart';
import 'sector.dart';

/// A user's request to be told when a new grant opens for a state and
/// sector that had none aimed at it.
///
/// One-shot: once a matching grant turns up, [fulfilledAt] and [grantId]
/// are set and the reminder is never checked again. Setting the same pair
/// again starts a fresh wait with the new options.
class GrantReminder {
  const GrantReminder({
    required this.id,
    required this.userId,
    required this.state,
    required this.sector,
    required this.includeAllStates,
    required this.includeAllSectors,
    required this.minAmountRm,
    required this.createdAt,
    required this.fulfilledAt,
    required this.grantId,
  });

  final String id;
  final String userId;
  final String state;
  final Sector sector;

  /// Whether a nationwide grant (no state restriction) also counts.
  final bool includeAllStates;

  /// Whether a grant open to every sector also counts.
  final bool includeAllSectors;

  /// Smallest ceiling a grant must offer, in actual ringgit; `null` means
  /// any amount.
  final int? minAmountRm;

  final DateTime createdAt;

  /// `null` while the reminder is still waiting for a matching grant.
  final DateTime? fulfilledAt;

  /// The grant that fulfilled it; `null` whenever [fulfilledAt] is.
  final String? grantId;

  bool get isActive => fulfilledAt == null;

  /// Whether [grant] is a new grant this reminder was waiting for.
  ///
  /// Only grants published once the reminder was set count, so a
  /// nationwide grant that was already listed does not fire it the moment
  /// the user opts into nationwide grants. A grant with no stated ceiling
  /// is treated as meeting any minimum amount. Open and deadline checks are
  /// not repeated here: candidates come from `GrantRepository.available`.
  bool matches(Grant grant) {
    // not-before rather than after: the clock can hand back the same
    // instant for both on a coarse timer
    if (grant.publishedAt.isBefore(createdAt)) return false;

    final stateMatches =
        grant.state == state || (includeAllStates && grant.state == null);
    final sectorMatches =
        grant.sector == sector || (includeAllSectors && grant.sector == null);
    if (!stateMatches || !sectorMatches) return false;

    final minimum = minAmountRm;
    final ceiling = grant.maxAmountRm;
    return minimum == null || ceiling == null || ceiling >= minimum;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'state': state,
      'sector': sector.name,
      'includeAllStates': includeAllStates,
      'includeAllSectors': includeAllSectors,
      'minAmountRm': minAmountRm,
      'createdAt': createdAt.toIso8601String(),
      'fulfilledAt': fulfilledAt?.toIso8601String(),
      'grantId': grantId,
    };
  }

  factory GrantReminder.fromJson(Map<String, dynamic> json) {
    return GrantReminder(
      id: json['id'] as String,
      userId: json['userId'] as String,
      state: json['state'] as String,
      sector: Sector.values.byName(json['sector'] as String),
      includeAllStates: json['includeAllStates'] as bool? ?? false,
      includeAllSectors: json['includeAllSectors'] as bool? ?? false,
      minAmountRm: json['minAmountRm'] as int?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      fulfilledAt: json['fulfilledAt'] == null
          ? null
          : DateTime.parse(json['fulfilledAt'] as String),
      grantId: json['grantId'] as String?,
    );
  }
}
