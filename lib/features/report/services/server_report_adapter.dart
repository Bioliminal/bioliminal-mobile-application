import '../../../domain/models.dart';

/// Converts a [ServerReport] (wire shape from the analysis server) into the
/// legacy [Report] shape the UI renders.
///
/// Minimum render path per the mobile-handover README: always surface the
/// overall narrative; if the quality gate failed, surface the quality issues
/// instead of any findings. `chain_observations` is empty for the bicep-curl
/// demo until the server-side rule YAML ships — findings stay empty when
/// that's the case.
class ServerReportAdapter {
  const ServerReportAdapter._();

  static Report toLegacyReport(ServerReport source) {
    final quality = source.movementSection.qualityReport;

    if (!quality.passed) {
      final points = quality.issues
          .map((i) => '${i.code}: ${i.detail}')
          .toList(growable: false);
      return Report(
        findings: const [],
        practitionerPoints: points.isEmpty
            ? const ['Session quality did not pass.']
            : points,
      );
    }

    return Report(
      findings: const [],
      practitionerPoints: [source.overallNarrative],
    );
  }
}
