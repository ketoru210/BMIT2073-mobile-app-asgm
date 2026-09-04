import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/analysis_request.dart';
import 'analysis_csv.dart';
import 'gdp_repository.dart';

/// Hands the current analysis to the system share sheet as a `.csv` file.
///
/// [AnalysisCsv] already knows how to turn a request into rows and a file
/// name; this class only owns the parts that touch the outside world —
/// the filesystem and the OS share sheet — so that reshaping logic is
/// never duplicated here.
class CsvExport {
  const CsvExport._();

  /// Writes [request]'s CSV into the temp directory and opens the share
  /// sheet for it.
  ///
  /// The file lives in `getTemporaryDirectory()`, not the app's documents
  /// directory: once handed off to whatever app the user picks, this app
  /// has no further use for it, so nothing here should accumulate.
  ///
  /// Never throws — a write failure or a share sheet that can't be shown
  /// collapses to `false` so the caller can show a plain SnackBar instead
  /// of crashing the page.
  static Future<bool> share(GdpRepository repo, AnalysisRequest request) async {
    try {
      final csv = AnalysisCsv.build(repo, request);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${AnalysisCsv.fileName(request)}');
      await file.writeAsString(csv);

      await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
      // The returned status is deliberately ignored. Android reports
      // `unavailable` whenever it cannot tell what the user did with the
      // sheet, which is the common case — treating that as a failure
      // would put an error message on screen right after a share that
      // worked. Only a thrown exception means the export did not happen.
      return true;
    } catch (_) {
      return false;
    }
  }
}
