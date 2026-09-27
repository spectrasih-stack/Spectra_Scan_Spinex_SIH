import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/evidence_record.dart';
import '../services/biometric_gate_service.dart';
import '../theme/apple_theme.dart';

class CertificateScreen extends StatelessWidget {
  final EvidenceRecord record;

  const CertificateScreen({super.key, required this.record});

  String _generateCourtDossierText() {
    final location = record.address.isNotEmpty ? record.address : 'Field Operations Sector';

    return '''
================================================================================
          FORENSIC EVIDENCE DIVISION • JUDICIAL DOSSIER CERTIFICATE
                     NIJ STANDARD 0604.01 COLOR TEST
================================================================================

CASE DOCKET NO.      : ${record.caseNumber}
EVIDENCE RECORD ID   : ${record.id}
VERIFIED DATE / TIME : ${record.timestampFormatted}
TESTING FACILITY     : State Forensic Evidence Division Mobile Screening Unit

--------------------------------------------------------------------------------
1. GEOSPATIAL & INCIDENT LOCATION (GPS VERIFIED)
--------------------------------------------------------------------------------
INCIDENT LOCATION    : $location
GEOSPATIAL FIX       : ${record.latitude.toStringAsFixed(5)}° N, ${record.longitude.toStringAsFixed(5)}° E
SATELLITE ACCURACY   : ±${record.accuracyMeters.toStringAsFixed(1)}m (FusedLocationProvider Hardware Fix)
TIMESTAMP FIX        : ${record.timestampIso}

--------------------------------------------------------------------------------
2. INVESTIGATING OFFICER / OPERATOR PROFILE
--------------------------------------------------------------------------------
FIELD ANALYST        : ${record.operator.name}
OFFICER BADGE ID     : ${record.operator.badge.isNotEmpty ? record.operator.badge : 'BADGE-7104'}
AGENCY / DIVISION    : ${record.operator.agency}
OPERATING TERMINAL   : Samsung Galaxy F15 5G
CREDENTIAL CLEARANCE : Google Account Verified • Native Biometrics Clearance

--------------------------------------------------------------------------------
3. CHEMICAL REAGENT & PROCEDURE
--------------------------------------------------------------------------------
REAGENT KIT          : ${record.kitName} (${record.kitBrand})
LOT NUMBER           : ${record.lotNumber} (Expiration: ${record.expirationDate})
TEST TYPE            : Presumptive Chromogenic Chemical Screening
METHODOLOGY          : Optical CIE-L*a*b* Standard D65 Spectral Colorimetry

--------------------------------------------------------------------------------
4. QUANTITATIVE COLORIMETRIC FINDINGS & OUTCOME
--------------------------------------------------------------------------------
PRESUMPTIVE RESULT   : ${record.category}
INDICATED SUBSTANCE  : ${record.substance}
LABEL CLASSIFICATION : ${record.label}
SPECTRAL CONFIDENCE  : ${record.confidence.toStringAsFixed(1)}% STATISTICAL MATCH
CIE COLOR DISTANCE   : Delta-E (ΔE) = ${record.deltaE.toStringAsFixed(2)}
MEASURED CHROMATICITY: CIE-L*a*b* [L: ${record.sampleLab.L.toStringAsFixed(1)}, a: ${record.sampleLab.a.toStringAsFixed(1)}, b: ${record.sampleLab.b.toStringAsFixed(1)}]

--------------------------------------------------------------------------------
5. CRYPTOGRAPHIC PROOF & CHAIN OF CUSTODY INTEGRITY
--------------------------------------------------------------------------------
RAW IMAGE SHA-256    : ${record.imageSha256}
PAYLOAD BLOCK HASH   : ${record.recordHash}
PREVIOUS BLOCK LINK  : ${record.previousRecordHash}
DIGITAL JUDICIAL SEAL: ${record.digitalSeal} (HMAC-SHA256)

--------------------------------------------------------------------------------
6. STATUTORY DISCLAIMER & JUDICIAL ATTESTATION
--------------------------------------------------------------------------------
The results set forth in this certificate represent a preliminary presumptive
field chemical indication obtained via colorimetric analysis in accordance with
NIJ Standard 0604.01. Confirmatory laboratory testing (GC-MS / HPLC / LC-MS)
is recommended for conclusive evidentiary court presentation.

I hereby affirm under penalty of official misconduct that this presumptive test
was conducted strictly in adherence to standard forensic operating procedure.

FIELD OPERATOR ATTESTATION:
${record.operator.name} (Badge #${record.operator.badge.replaceAll('BADGE-', '')})
${record.operator.agency}
================================================================================
''';
  }

  Future<void> _exportAndShowDossier(BuildContext context) async {
    final ok = await BiometricGateService.requireAuthorization(
      context,
      title: 'Biometric Clearance',
      reason: 'Authenticate with Face ID or biometrics to export certified evidence for case ${record.caseNumber}.',
    );
    if (!ok || !context.mounted) return;

    final dossierText = _generateCourtDossierText();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CourtDossierModalSheet(
        caseNumber: record.caseNumber,
        location: record.address.isNotEmpty ? record.address : 'Field Location',
        dossierText: dossierText,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final qrPayload = jsonEncode({
      'docId': record.id,
      'caseNumber': record.caseNumber,
      'timestamp': record.timestampIso,
      'location': record.address,
      'badge': record.operator.badge,
      'result': record.category,
      'substance': record.substance,
      'imageSha256': record.imageSha256,
      'recordHash': record.recordHash,
      'seal': record.digitalSeal,
    });

    final isPositive = record.category == 'POSITIVE';
    final isNegative = record.category == 'NEGATIVE';
    final resultColor = isPositive
        ? const Color(0xFFB91C1C)
        : isNegative
            ? const Color(0xFF15803D)
            : const Color(0xFFB45309);

    final displayLocation = record.address.isNotEmpty ? record.address : 'Field Operations Sector';

    return Scaffold(
      backgroundColor: AppleTheme.systemBackground,
      appBar: AppBar(
        title: const Text('Official Evidentiary Certificate'),
        actions: [
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            onPressed: () => _exportAndShowDossier(context),
            child: const Icon(CupertinoIcons.share, size: 20),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 40),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF0F172A), width: 1.8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(90),
                blurRadius: 18,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Certificate Title & Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.operator.agency.toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFF334155),
                            fontWeight: FontWeight.bold,
                            fontSize: 10.5,
                            letterSpacing: 0.6,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'FORENSIC DRUG TEST CERTIFICATE',
                          style: TextStyle(
                            color: Color(0xFF0F172A),
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const Text(
                          'Digital Companion Presumptive Chemical Screening & Chain of Custody',
                          style: TextStyle(
                            color: Color(0xFF475569),
                            fontSize: 9.5,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF0F172A), width: 1.2),
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'CASE #${record.caseNumber}',
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontWeight: FontWeight.bold,
                            fontSize: 10.5,
                            fontFamily: 'monospace',
                          ),
                        ),
                        Text(
                          record.digitalSeal.isNotEmpty
                              ? (record.digitalSeal.length > 18 ? '${record.digitalSeal.substring(0, 18)}...' : record.digitalSeal)
                              : 'SEAL VERIFIED',
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 7.5,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(color: Color(0xFF0F172A), thickness: 1.2),
              const SizedBox(height: 10),

              // Responsive Metadata Table (2-Column Key-Value Rows)
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFCBD5E1), width: 1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  children: [
                    _buildMetaRow('Case Docket No.', record.caseNumber, isAlt: false),
                    _buildMetaRow('Test Date / Time', record.timestampFormatted, isAlt: true),
                    _buildMetaRow(
                      'Field Operator',
                      '${record.operator.name} (Badge #${record.operator.badge.replaceAll('BADGE-', '')})',
                      isAlt: false,
                    ),
                    _buildMetaRow('Field Terminal', 'Samsung Galaxy F15 5G (Mobile Unit)', isAlt: true),
                    // Highlighting the Real Location Name
                    _buildMetaRow(
                      'Incident Location',
                      '📍 $displayLocation',
                      isAlt: false,
                      isLocationHighlight: true,
                    ),
                    _buildMetaRow(
                      'Geospatial Fix',
                      '${record.latitude.toStringAsFixed(4)}° N, ${record.longitude.toStringAsFixed(4)}° E (±${record.accuracyMeters.toStringAsFixed(1)}m)',
                      isAlt: true,
                    ),
                    _buildMetaRow(
                      'Reagent Kit',
                      '${record.kitName} (${record.kitBrand})',
                      isAlt: false,
                    ),
                    _buildMetaRow(
                      'Lot / Expiration',
                      '${record.lotNumber} • Exp: ${record.expirationDate}',
                      isAlt: true,
                    ),
                    _buildMetaRow(
                      'Testing Protocol',
                      'NIJ Standard 0604.01 Colorimetric Analysis',
                      isAlt: false,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Classification Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isPositive
                      ? const Color(0xFFFEF2F2)
                      : isNegative
                          ? const Color(0xFFF0FDF4)
                          : const Color(0xFFFEFCE8),
                  border: Border.all(color: resultColor, width: 1.5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'PRESUMPTIVE CLASSIFICATION OUTCOME:',
                          style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: resultColor.withAlpha(25),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            record.category,
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: resultColor),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      record.label,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: resultColor,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Indicated Substance: ${record.substance} | Statistical Match: ${record.confidence.toStringAsFixed(1)}% (CIE ΔE: ${record.deltaE.toStringAsFixed(2)})',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF1E293B)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Photographic Evidence & QR Verification Row (Side-by-Side without overflow)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Photo Evidence Preview
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      width: 125,
                      height: 95,
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                        color: const Color(0xFFF8FAFC),
                      ),
                      child: Image.memory(
                        base64Decode(
                          record.imageBase64.contains(',') ? record.imageBase64.split(',').last : record.imageBase64,
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Verification QR Code & Judicial Seal Block
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 70,
                            height: 70,
                            child: QrImageView(
                              data: qrPayload,
                              version: QrVersions.auto,
                              padding: EdgeInsets.zero,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'JUDICIAL SEAL',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Scan via certified court scanner to verify cryptographic custody.',
                                  style: TextStyle(fontSize: 8.5, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Cryptographic Proof & Chain of Custody Hashes (Full Width)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CRYPTOGRAPHIC AUDIT PROOF & BLOCKCHAIN SEALS',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF94A3B8),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _buildDarkHashRow('Raw Image SHA-256', record.imageSha256),
                    _buildDarkHashRow('Block Payload Hash', record.recordHash),
                    _buildDarkHashRow('Digital Seal (HMAC)', record.digitalSeal),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Statutory Admissibility Notice Box
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  border: Border.all(color: const Color(0xFFB45309), width: 1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'STATUTORY FORENSIC ADMISSIBILITY NOTICE:',
                      style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF78350F)),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'The result set forth in this certificate represents a preliminary presumptive field chemical indication obtained via optical colorimetric analysis per NIJ 0604.01. Confirmatory testing (GC-MS / LC-MS/MS) is required for definitive chemical identification in judicial proceedings.',
                      style: TextStyle(fontSize: 9, color: Color(0xFF78350F), height: 1.3),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Signature Line (Flexible layout that never overflows Galaxy F15)
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Field Analyst Attestation:',
                          style: TextStyle(fontSize: 9, color: Color(0xFF475569)),
                        ),
                        const SizedBox(height: 22),
                        Container(
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            border: Border(top: BorderSide(color: Color(0xFF0F172A), width: 1)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              '${record.operator.name} (Badge #${record.operator.badge.replaceAll('BADGE-', '')})',
                              style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Agency Repository Intake Seal:',
                          style: TextStyle(fontSize: 9, color: Color(0xFF475569)),
                        ),
                        const SizedBox(height: 22),
                        Container(
                          width: double.infinity,
                          alignment: Alignment.centerRight,
                          decoration: const BoxDecoration(
                            border: Border(top: BorderSide(color: Color(0xFF0F172A), width: 1)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              record.digitalSeal,
                              style: const TextStyle(fontSize: 8, fontFamily: 'monospace', fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Primary Action: Export Official Court Dossier
              CupertinoButton.filled(
                borderRadius: BorderRadius.circular(AppleTheme.radiusMedium),
                padding: const EdgeInsets.symmetric(vertical: 12),
                onPressed: () => _exportAndShowDossier(context),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.doc_plaintext, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Export Certified Judicial Dossier',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetaRow(String label, String value, {required bool isAlt, bool isLocationHighlight = false}) {
    return Container(
      color: isAlt ? const Color(0xFFF8FAFC) : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: isLocationHighlight ? const Color(0xFF1D4ED8) : const Color(0xFF475569),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isLocationHighlight ? FontWeight.w800 : FontWeight.w500,
                color: isLocationHighlight ? const Color(0xFF0F172A) : const Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDarkHashRow(String label, String hash) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontSize: 8.5, color: Color(0xFF94A3B8), fontFamily: 'monospace'),
            ),
          ),
          Expanded(
            child: Text(
              hash.isNotEmpty ? hash : '00000000000000000000000000000000',
              style: const TextStyle(fontSize: 8.5, color: Color(0xFF38BDF8), fontFamily: 'monospace'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Apple HIG Modal Preview Sheet for Official Judicial Dossier
class _CourtDossierModalSheet extends StatefulWidget {
  final String caseNumber;
  final String location;
  final String dossierText;

  const _CourtDossierModalSheet({
    required this.caseNumber,
    required this.location,
    required this.dossierText,
  });

  @override
  State<_CourtDossierModalSheet> createState() => _CourtDossierModalSheetState();
}

class _CourtDossierModalSheetState extends State<_CourtDossierModalSheet> {
  bool _copied = false;

  void _copyDossier() {
    Clipboard.setData(ClipboardData(text: widget.dossierText));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppleTheme.systemBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 6),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppleTheme.separator,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'JUDICIAL DOSSIER: #${widget.caseNumber}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppleTheme.label,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '📍 ${widget.location}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppleTheme.secondaryLabel,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Done', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          const Divider(height: 0.5, color: AppleTheme.separator),

          // Scrollable Monospace Dossier
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(14),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppleTheme.secondarySystemBackground,
                  borderRadius: BorderRadius.circular(AppleTheme.radiusMedium),
                  border: Border.all(color: AppleTheme.hairlineBorder, width: 0.5),
                ),
                child: SelectableText(
                  widget.dossierText,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontFamily: 'monospace',
                    height: 1.35,
                    color: AppleTheme.label,
                  ),
                ),
              ),
            ),
          ),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
            decoration: const BoxDecoration(
              color: AppleTheme.secondarySystemBackground,
              border: Border(top: BorderSide(color: AppleTheme.hairlineBorder, width: 0.5)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: CupertinoButton.filled(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    borderRadius: BorderRadius.circular(AppleTheme.radiusMedium),
                    onPressed: _copyDossier,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _copied ? CupertinoIcons.checkmark_alt : CupertinoIcons.doc_on_clipboard,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _copied ? 'Copied to Clipboard!' : 'Copy Full Legal Dossier',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                      ],
                    ),
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
