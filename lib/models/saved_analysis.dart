import 'analysis_request.dart';
import 'sector.dart';

/// A favourite the user saved: a full snapshot of one analysis request
/// plus when it was saved and an optional label.
class SavedAnalysis {
  const SavedAnalysis({
    required this.id,
    required this.label,
    required this.request,
    required this.savedAt,
  });

  final String id;
  final String label;
  final AnalysisRequest request;
  final DateTime savedAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'savedAt': savedAt.toIso8601String(),
      'request': {
        'mode': request.mode.name,
        'states': request.states,
        'sector': request.sector?.name,
        'yearStart': request.yearStart,
        'yearEnd': request.yearEnd,
        'policyId': request.policyId,
      },
    };
  }

  factory SavedAnalysis.fromJson(Map<String, dynamic> json) {
    final req = json['request'] as Map<String, dynamic>;
    return SavedAnalysis(
      id: json['id'] as String,
      label: json['label'] as String,
      savedAt: DateTime.parse(json['savedAt'] as String),
      request: AnalysisRequest(
        mode: AnalysisMode.values.byName(req['mode'] as String),
        states: (req['states'] as List<dynamic>).cast<String>(),
        sector: req['sector'] == null
            ? null
            : Sector.values.byName(req['sector'] as String),
        yearStart: req['yearStart'] as int,
        yearEnd: req['yearEnd'] as int,
        policyId: req['policyId'] as String?,
      ),
    );
  }
}
