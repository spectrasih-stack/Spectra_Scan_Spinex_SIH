import 'dart:convert';
import 'package:crypto/crypto.dart' as crypto;
import '../models/evidence_record.dart';

class VerificationResult {
  final bool isValid;
  final List<String> errors;
  final String recomputedRecordHash;

  const VerificationResult({
    required this.isValid,
    required this.errors,
    required this.recomputedRecordHash,
  });
}

class LedgerAuditReport {
  final bool isAllValid;
  final int totalRecords;
  final List<RecordAuditItem> results;

  const LedgerAuditReport({
    required this.isAllValid,
    required this.totalRecords,
    required this.results,
  });
}

class RecordAuditItem {
  final String recordId;
  final String caseNumber;
  final bool isValid;
  final List<String> errors;

  const RecordAuditItem({
    required this.recordId,
    required this.caseNumber,
    required this.isValid,
    required this.errors,
  });
}

class CryptoService {
  static const String genesisHash =
      'GENESIS-0000000000000000000000000000000000000000000000000000000000000000';

  /// Calculate SHA-256 hex string of a UTF-8 string
  static String sha256String(String input) {
    final bytes = utf8.encode(input);
    final digest = crypto.sha256.convert(bytes);
    return digest.toString();
  }

  /// Calculate SHA-256 hex string of raw byte data
  static String sha256Bytes(List<int> bytes) {
    final digest = crypto.sha256.convert(bytes);
    return digest.toString();
  }

  /// Hash image data (base64)
  static String hashBase64Image(String base64String) {
    try {
      final clean = base64String.contains(',')
          ? base64String.split(',').last
          : base64String;
      final bytes = base64Decode(clean);
      return sha256Bytes(bytes);
    } catch (e) {
      return sha256String(base64String);
    }
  }

  /// Generate HMAC-style Digital Seal token
  static String generateDigitalSeal(
      String recordHash, String badge, String timestampIso) {
    final payload = '$recordHash:$badge:$timestampIso:SPECTRA-AUTH-LEO-V2';
    final fullHash = sha256String(payload).toUpperCase();
    return 'SEAL-${fullHash.substring(0, 4)}-${fullHash.substring(4, 8)}-${fullHash.substring(8, 12)}';
  }

  /// Verify integrity of a single record against its image and canonical payload
  static VerificationResult verifyRecordIntegrity(
    EvidenceRecord record,
    EvidenceRecord? previousRecord,
  ) {
    final errors = <String>[];

    // 1. Verify Image Hash
    if (record.imageBase64.isNotEmpty) {
      final computedImgHash = hashBase64Image(record.imageBase64);
      if (computedImgHash.toLowerCase() != record.imageSha256.toLowerCase()) {
        errors.add(
          'IMAGE DIGEST MISMATCH: Raw image altered or corrupted. '
          'Recorded: ${record.imageSha256.substring(0, 10)}... vs Recomputed: ${computedImgHash.substring(0, 10)}...',
        );
      }
    }

    // 2. Verify Canonical Payload Hash
    final canonical = record.toCanonicalJson();
    final recomputedRecordHash = sha256String(canonical);
    if (recomputedRecordHash.toLowerCase() != record.recordHash.toLowerCase()) {
      errors.add(
        'DATA TAMPER DETECTED: Metadata payload has been altered! '
        'Recorded: ${record.recordHash.substring(0, 10)}... vs Recomputed: ${recomputedRecordHash.substring(0, 10)}...',
      );
    }

    // 3. Verify Hash Chain Linkage to Previous Block
    if (previousRecord != null) {
      if (record.previousRecordHash.toLowerCase() !=
          previousRecord.recordHash.toLowerCase()) {
        errors.add(
          'HASH CHAIN BROKEN: Linkage to previous record invalid. '
          'Points to ${record.previousRecordHash.substring(0, 8)} but previous record has ${previousRecord.recordHash.substring(0, 8)}',
        );
      }
    }

    return VerificationResult(
      isValid: errors.isEmpty,
      errors: errors,
      recomputedRecordHash: recomputedRecordHash,
    );
  }

  /// Audit entire evidence blockchain
  static LedgerAuditReport verifyEntireLedger(List<EvidenceRecord> records) {
    final auditItems = <RecordAuditItem>[];
    bool isAllValid = true;

    for (int i = 0; i < records.length; i++) {
      final current = records[i];
      final prev = i > 0 ? records[i - 1] : null;
      final verification = verifyRecordIntegrity(current, prev);

      if (!verification.isValid) {
        isAllValid = false;
      }

      auditItems.add(
        RecordAuditItem(
          recordId: current.id,
          caseNumber: current.caseNumber,
          isValid: verification.isValid,
          errors: verification.errors,
        ),
      );
    }

    return LedgerAuditReport(
      isAllValid: isAllValid,
      totalRecords: records.length,
      results: auditItems,
    );
  }
}
