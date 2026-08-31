import 'sector.dart';

/// Roles recognised by the app.
///
/// Drives the admin-grant surface. The server enforces it with RLS; the
/// client only uses it to hide UI, never as the real permission check.
enum UserRole { user, admin }

/// The only three states an application may be in.
///
/// No draft, no under_review — every extra state is an extra screen and a
/// batch of edge cases.
enum ApplicationStatus { pending, approved, rejected }

/// A grant an admin publishes and a user can apply to.
///
/// Eligibility is structural: [state] / [sector] / [maxAmountRm] are
/// nullable, and `null` means "no restriction on this axis". [criteriaNote]
/// carries the one-sentence human explanation of those rules.
class Grant {
  const Grant({
    required this.id,
    required this.name,
    required this.agency,
    required this.state,
    required this.sector,
    required this.maxAmountRm,
    required this.deadline,
    required this.sourceUrl,
    required this.criteriaNote,
    required this.description,
    required this.publishedBy,
    required this.publishedAt,
    required this.isOpen,
  });

  final String id;
  final String name;
  final String agency;

  /// `null` = nationwide, matches any state.
  final String? state;

  /// `null` = any sector.
  final Sector? sector;

  /// `null` = no cap. In actual ringgit, not the RM-million unit the GDP
  /// snapshot uses.
  final int? maxAmountRm;

  final DateTime deadline;
  final String sourceUrl;

  /// One sentence: the real programme name plus the fact that the criteria
  /// are this app's own demo conditions, not the official ones.
  final String criteriaNote;

  final String description;

  /// Id of the admin account that published it.
  final String publishedBy;
  final DateTime publishedAt;
  final bool isOpen;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'agency': agency,
      'state': state,
      'sector': sector?.name,
      'maxAmountRm': maxAmountRm,
      'deadline': deadline.toIso8601String(),
      'sourceUrl': sourceUrl,
      'criteriaNote': criteriaNote,
      'description': description,
      'publishedBy': publishedBy,
      'publishedAt': publishedAt.toIso8601String(),
      'isOpen': isOpen,
    };
  }

  factory Grant.fromJson(Map<String, dynamic> json) {
    return Grant(
      id: json['id'] as String,
      name: json['name'] as String,
      agency: json['agency'] as String,
      state: json['state'] as String?,
      sector: json['sector'] == null
          ? null
          : Sector.values.byName(json['sector'] as String),
      maxAmountRm: json['maxAmountRm'] as int?,
      deadline: DateTime.parse(json['deadline'] as String),
      sourceUrl: json['sourceUrl'] as String,
      criteriaNote: json['criteriaNote'] as String,
      description: json['description'] as String,
      publishedBy: json['publishedBy'] as String,
      publishedAt: DateTime.parse(json['publishedAt'] as String),
      isOpen: json['isOpen'] as bool,
    );
  }
}

/// A user's application to one grant.
class GrantApplication {
  const GrantApplication({
    required this.id,
    required this.grantId,
    required this.userId,
    required this.projectName,
    required this.state,
    required this.sector,
    required this.requestedAmountRm,
    required this.note,
    required this.status,
    required this.submittedAt,
    required this.decidedAt,
  });

  final String id;
  final String grantId;
  final String userId;
  final String projectName;
  final String state;
  final Sector sector;

  /// In actual ringgit, not the RM-million unit.
  final int requestedAmountRm;
  final String note;
  final ApplicationStatus status;
  final DateTime submittedAt;

  /// Set once an admin decides; `null` while [status] is pending.
  final DateTime? decidedAt;

  /// A not-yet-submitted application, as the form builds it.
  ///
  /// [id] is left empty on purpose: the repository assigns it on insert,
  /// mirroring Supabase, where the `id` column has a server-side default.
  /// Status and timestamp are not the form's to choose either.
  factory GrantApplication.draft({
    required String grantId,
    required String userId,
    required String projectName,
    required String state,
    required Sector sector,
    required int requestedAmountRm,
    required String note,
  }) {
    return GrantApplication(
      id: '',
      grantId: grantId,
      userId: userId,
      projectName: projectName,
      state: state,
      sector: sector,
      requestedAmountRm: requestedAmountRm,
      note: note,
      status: ApplicationStatus.pending,
      submittedAt: DateTime.now(),
      decidedAt: null,
    );
  }

  GrantApplication copyWith({
    String? id,
    ApplicationStatus? status,
    DateTime? decidedAt,
  }) {
    return GrantApplication(
      id: id ?? this.id,
      grantId: grantId,
      userId: userId,
      projectName: projectName,
      state: state,
      sector: sector,
      requestedAmountRm: requestedAmountRm,
      note: note,
      status: status ?? this.status,
      submittedAt: submittedAt,
      decidedAt: decidedAt ?? this.decidedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'grantId': grantId,
      'userId': userId,
      'projectName': projectName,
      'state': state,
      'sector': sector.name,
      'requestedAmountRm': requestedAmountRm,
      'note': note,
      'status': status.name,
      'submittedAt': submittedAt.toIso8601String(),
      'decidedAt': decidedAt?.toIso8601String(),
    };
  }

  factory GrantApplication.fromJson(Map<String, dynamic> json) {
    return GrantApplication(
      id: json['id'] as String,
      grantId: json['grantId'] as String,
      userId: json['userId'] as String,
      projectName: json['projectName'] as String,
      state: json['state'] as String,
      sector: Sector.values.byName(json['sector'] as String),
      requestedAmountRm: json['requestedAmountRm'] as int,
      note: json['note'] as String,
      status: ApplicationStatus.values.byName(json['status'] as String),
      submittedAt: DateTime.parse(json['submittedAt'] as String),
      decidedAt: json['decidedAt'] == null
          ? null
          : DateTime.parse(json['decidedAt'] as String),
    );
  }
}
