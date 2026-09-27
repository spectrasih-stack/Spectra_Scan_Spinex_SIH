import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/evidence_record.dart';
import '../services/crypto_service.dart';
import '../theme/apple_theme.dart';
import 'certificate_screen.dart';

class RecordDetailsScreen extends StatefulWidget {
  final EvidenceRecord record;
  final EvidenceRecord? previousRecord;

  const RecordDetailsScreen({
    super.key,
    required this.record,
    this.previousRecord,
  });

  @override
  State<RecordDetailsScreen> createState() => _RecordDetailsScreenState();
}

class _RecordDetailsScreenState extends State<RecordDetailsScreen> {
  late VerificationResult _verification;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _runVerification();
  }

  void _runVerification() {
    setState(() => _isVerifying = true);
    _verification = CryptoService.verifyRecordIntegrity(
      widget.record,
      widget.previousRecord,
    );
    setState(() => _isVerifying = false);
  }

  void _copyToClipboard(String text, String fieldName) {
    Clipboard.setData(ClipboardData(text: text));
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoTheme(
        data: const CupertinoThemeData(brightness: Brightness.dark),
        child: CupertinoAlertDialog(
          title: const Text('Copied to Clipboard'),
          content: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text('$fieldName successfully copied.'),
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final record = widget.record;
    final isPositive = record.category == 'POSITIVE';
    final isNegative = record.category == 'NEGATIVE';
    final statusColor = isPositive
        ? AppleTheme.systemRed
        : isNegative
            ? AppleTheme.systemGreen
            : AppleTheme.systemOrange;

    final qrPayload = jsonEncode({
      'docId': record.id,
      'caseNumber': record.caseNumber,
      'timestamp': record.timestampIso,
      'badge': record.operator.badge,
      'result': record.category,
      'substance': record.substance,
      'imageSha256': record.imageSha256,
      'recordHash': record.recordHash,
      'seal': record.digitalSeal,
    });

    return Scaffold(
      backgroundColor: AppleTheme.systemBackground,
      appBar: AppBar(
        title: Text('Case ${record.caseNumber}'),
        actions: [
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            onPressed: () {
              Navigator.push(
                context,
                CupertinoPageRoute(builder: (context) => CertificateScreen(record: record)),
              );
            },
            child: const Icon(CupertinoIcons.doc_text_fill, size: 20),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Apple Wallet Digital Pass Header
            Container(
              decoration: BoxDecoration(
                color: AppleTheme.secondarySystemBackground,
                borderRadius: BorderRadius.circular(AppleTheme.radiusCard),
                border: Border.all(color: AppleTheme.hairlineBorder, width: 0.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(90),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Pass Top Ribbon
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: statusColor.withAlpha(25),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                      border: Border(bottom: BorderSide(color: statusColor.withAlpha(50), width: 0.5)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _verification.isValid
                              ? CupertinoIcons.checkmark_seal_fill
                              : CupertinoIcons.exclamationmark_triangle_fill,
                          color: _verification.isValid ? AppleTheme.systemGreen : AppleTheme.systemRed,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _verification.isValid ? 'CRYPTOGRAPHIC CHAIN VERIFIED' : 'TAMPER DETECTED',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: _verification.isValid ? AppleTheme.systemGreen : AppleTheme.systemRed,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              Text(
                                'Seal: ${record.digitalSeal} • SHA-256 HMAC',
                                style: const TextStyle(fontSize: 10, color: AppleTheme.secondaryLabel),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        CupertinoButton(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          color: AppleTheme.tertiarySystemBackground,
                          borderRadius: BorderRadius.circular(10),
                          onPressed: _isVerifying ? null : _runVerification,
                          child: Text(
                            _isVerifying ? 'Verifying...' : 'Re-verify',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppleTheme.systemBlue),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Pass Body
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image Thumbnail
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            width: 110,
                            height: 110,
                            color: Colors.black,
                            child: Image.memory(
                              base64Decode(
                                record.imageBase64.contains(',')
                                    ? record.imageBase64.split(',').last
                                    : record.imageBase64,
                              ),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Pass Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                record.substance,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.4,
                                  color: AppleTheme.label,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                record.label,
                                style: TextStyle(fontSize: 12, color: statusColor, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${record.kitName} (${record.kitBrand})',
                                style: const TextStyle(fontSize: 12, color: AppleTheme.secondaryLabel),
                              ),
                              Text(
                                record.timestampFormatted,
                                style: const TextStyle(fontSize: 11, color: AppleTheme.tertiaryLabel),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Interactive QR Verification Code
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppleTheme.secondarySystemBackground,
                borderRadius: BorderRadius.circular(AppleTheme.radiusCard),
                border: Border.all(color: AppleTheme.hairlineBorder, width: 0.5),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: QrImageView(
                      data: qrPayload,
                      version: QrVersions.auto,
                      size: 96,
                      backgroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Digital Chain Pass',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                            color: AppleTheme.label,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Scan to verify tamper-proof evidentiary status via standard judicial readers.',
                          style: TextStyle(fontSize: 11.5, color: AppleTheme.secondaryLabel),
                        ),
                        const SizedBox(height: 8),
                        CupertinoButton(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          color: AppleTheme.tertiarySystemBackground,
                          borderRadius: BorderRadius.circular(10),
                          onPressed: () => _copyToClipboard(qrPayload, 'QR Payload'),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(CupertinoIcons.doc_on_clipboard, size: 14, color: AppleTheme.systemBlue),
                              SizedBox(width: 6),
                              Text('Copy Data', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppleTheme.systemBlue)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Inset Group: Incident Field Location & Geospatial Fix
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppleTheme.secondarySystemBackground,
                borderRadius: BorderRadius.circular(AppleTheme.radiusCard),
                border: Border.all(color: AppleTheme.hairlineBorder, width: 0.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'INCIDENT FIELD LOCATION',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppleTheme.tertiaryLabel, letterSpacing: 0.5),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppleTheme.systemGreen.withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(CupertinoIcons.checkmark_seal_fill, size: 9, color: AppleTheme.systemGreen),
                            const SizedBox(width: 3),
                            Text(
                              'FIX ±${record.accuracyMeters.toStringAsFixed(1)}M',
                              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppleTheme.systemGreen),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppleTheme.systemBlue.withAlpha(35),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(CupertinoIcons.location_solid, size: 18, color: AppleTheme.systemBlue),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              record.address.isNotEmpty ? record.address : 'Field Operations Sector',
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                                color: AppleTheme.label,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${record.latitude.toStringAsFixed(5)}° N, ${record.longitude.toStringAsFixed(5)}° E • Timestamped Lock',
                              style: const TextStyle(fontSize: 11.5, color: AppleTheme.secondaryLabel),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Inset Group: Colorimetric Findings
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppleTheme.secondarySystemBackground,
                borderRadius: BorderRadius.circular(AppleTheme.radiusCard),
                border: Border.all(color: AppleTheme.hairlineBorder, width: 0.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'COLORIMETRIC LAB FINDINGS',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppleTheme.tertiaryLabel, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildMetricCol('Delta-E (ΔE)', record.deltaE.toStringAsFixed(1), AppleTheme.systemBlue),
                      _buildMetricCol('Lighting Quality', '${record.calibration.lightingQuality}%', AppleTheme.systemGreen),
                      _buildMetricCol('Color Cast', record.calibration.colorCast, AppleTheme.secondaryLabel),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Inset Group: Cryptographic Hashes
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppleTheme.secondarySystemBackground,
                borderRadius: BorderRadius.circular(AppleTheme.radiusCard),
                border: Border.all(color: AppleTheme.hairlineBorder, width: 0.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CRYPTOGRAPHIC CHAIN (SHA-256)',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppleTheme.tertiaryLabel, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 12),
                  _buildHashRow('IMAGE SHA-256', record.imageSha256),
                  const SizedBox(height: 8),
                  _buildHashRow('PREVIOUS BLOCK HASH', record.previousRecordHash),
                  const SizedBox(height: 8),
                  _buildHashRow('BLOCK RECORD HASH', record.recordHash),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // View Official Certificate Button
            CupertinoButton.filled(
              borderRadius: BorderRadius.circular(AppleTheme.radiusMedium),
              onPressed: () {
                Navigator.push(
                  context,
                  CupertinoPageRoute(builder: (context) => CertificateScreen(record: record)),
                );
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.doc_checkmark_fill, size: 18),
                  SizedBox(width: 8),
                  Text('View Court Evidentiary Certificate', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCol(String label, String value, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10.5, color: AppleTheme.tertiaryLabel)),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildHashRow(String title, String hash) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 9.5, color: AppleTheme.tertiaryLabel, fontWeight: FontWeight.w600)),
              const SizedBox(height: 1),
              Text(
                hash,
                style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: AppleTheme.systemTeal),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => _copyToClipboard(hash, title),
          child: const Icon(CupertinoIcons.doc_on_clipboard, size: 14, color: AppleTheme.secondaryLabel),
        ),
      ],
    );
  }
}
