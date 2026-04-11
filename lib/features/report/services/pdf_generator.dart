import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../domain/models.dart';

class PdfGenerator {
  PdfGenerator._();

  static const _disclaimer =
      'This is an educational triage tool, not a diagnostic assessment';

  static PdfColor _confidencePdfColor(ConfidenceLevel level) {
    switch (level) {
      case ConfidenceLevel.high:
        return PdfColors.green;
      case ConfidenceLevel.medium:
        return PdfColors.amber;
      case ConfidenceLevel.low:
        return PdfColors.red;
    }
  }

  static String _confidenceLabel(ConfidenceLevel level) {
    switch (level) {
      case ConfidenceLevel.high:
        return 'High';
      case ConfidenceLevel.medium:
        return 'Medium';
      case ConfidenceLevel.low:
        return 'Low';
    }
  }

  static ConfidenceLevel _worstConfidence(List<Compensation> compensations) =>
      ConfidenceLevel.worstOf(compensations.map((c) => c.confidence));

  static ConfidenceLevel _overallConfidence(List<Finding> findings) =>
      ConfidenceLevel.worstOf(
        findings.map((f) => _worstConfidence(f.compensations)),
      );

  static Future<Uint8List> generate(
    Report report, {
    required String assessmentId,
    required DateTime date,
  }) async {
    final doc = pw.Document(
      theme: pw.ThemeData.withFont(
        base: pw.Font.helvetica(),
        bold: pw.Font.helveticaBold(),
        italic: pw.Font.helveticaOblique(),
        boldItalic: pw.Font.helveticaBoldOblique(),
      ),
    );

    final overall = _overallConfidence(report.findings);
    final formattedDate =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        footer: (context) => pw.Container(
          alignment: pw.Alignment.center,
          margin: const pw.EdgeInsets.only(top: 8),
          child: pw.Text(
            _disclaimer,
            style: pw.TextStyle(
              fontSize: 8,
              fontStyle: pw.FontStyle.italic,
              color: PdfColors.grey600,
            ),
          ),
        ),
        build: (context) => [
          // -- Header --
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'AuraLink Movement Screen',
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(formattedDate, style: const pw.TextStyle(fontSize: 12)),
              ],
            ),
          ),

          // -- Summary --
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            margin: const pw.EdgeInsets.only(bottom: 16),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Summary',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  'We found ${report.findings.length} movement pattern${report.findings.length == 1 ? '' : 's'} worth discussing with a practitioner.',
                  style: const pw.TextStyle(fontSize: 11),
                ),
                pw.SizedBox(height: 4),
                pw.Row(
                  children: [
                    pw.Text(
                      'Overall confidence: ',
                      style: const pw.TextStyle(fontSize: 11),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: pw.BoxDecoration(
                        color: _confidencePdfColor(overall),
                        borderRadius: pw.BorderRadius.circular(10),
                      ),
                      child: pw.Text(
                        _confidenceLabel(overall),
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 4),
                if (overall == ConfidenceLevel.low)
                  pw.Text(
                    'Some findings had lower tracking confidence -- marked below.',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontStyle: pw.FontStyle.italic,
                      color: PdfColors.red,
                    ),
                  )
                else
                  pw.Text(
                    'Tracking quality was high throughout.',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
              ],
            ),
          ),

          // -- Findings --
          pw.Header(
            level: 1,
            child: pw.Text(
              'Your Findings',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
          ),
          ...report.findings.map(_buildFindingSection),

          // -- Practitioner Discussion Points --
          if (report.practitionerPoints.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            pw.Header(
              level: 1,
              child: pw.Text(
                'Practitioner Discussion Points',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: report.practitionerPoints
                  .map(
                    (point) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 4),
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            '  \u2022  ',
                            style: const pw.TextStyle(fontSize: 11),
                          ),
                          pw.Expanded(
                            child: pw.Text(
                              point,
                              style: const pw.TextStyle(fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );

    return doc.save();
  }

  static pw.Widget _buildFindingSection(Finding finding) {
    final confidence = _worstConfidence(finding.compensations);

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Description + confidence badge
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Text(
                  finding.bodyPathDescription,
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: pw.BoxDecoration(
                  color: _confidencePdfColor(confidence),
                  borderRadius: pw.BorderRadius.circular(10),
                ),
                child: pw.Text(
                  _confidenceLabel(confidence),
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
              ),
            ],
          ),

          if (confidence == ConfidenceLevel.low) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              'Tracking was unclear for this finding -- verify with a practitioner',
              style: pw.TextStyle(
                fontSize: 9,
                fontStyle: pw.FontStyle.italic,
                color: PdfColors.red,
              ),
            ),
          ],

          if (finding.upstreamDriver != null) ...[
            pw.SizedBox(height: 6),
            pw.Text(
              'Likely upstream driver: ${finding.upstreamDriver}',
              style: const pw.TextStyle(fontSize: 10),
            ),
          ],

          pw.SizedBox(height: 6),
          pw.Text(
            finding.recommendation,
            style: const pw.TextStyle(fontSize: 10),
          ),

          // Citations
          if (finding.citations.isNotEmpty) ...[
            pw.SizedBox(height: 8),
            pw.Text(
              'Evidence:',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
            ...finding.citations.map(
              (c) => pw.Padding(
                padding: const pw.EdgeInsets.only(top: 3),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      '${c.source}: ${c.finding}',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                    if (c.url.isNotEmpty)
                      pw.UrlLink(
                        destination: c.url,
                        child: pw.Text(
                          c.url,
                          style: const pw.TextStyle(
                            fontSize: 8,
                            color: PdfColors.blue,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
