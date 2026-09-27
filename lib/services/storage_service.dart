import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/evidence_record.dart';
import '../models/operator_profile.dart';
import 'colorimetry_service.dart';
import 'crypto_service.dart';
import 'sample_generator.dart';

class StorageService {
  static const String recordsKey = 'spectra_field_records_v1';
  static const String operatorKey = 'spectra_field_operator_profile_v1';

  /// Get stored Operator Profile
  static Future<OperatorProfile> getOperator() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(operatorKey);
    if (jsonStr == null) return OperatorProfile.defaultOperator;
    try {
      final op = OperatorProfile.fromJson(jsonDecode(jsonStr));
      if (op.deviceModel.toUpperCase().contains('E156') || op.deviceModel.contains('SM-E156B')) {
        final upgraded = op.copyWith(deviceModel: 'Samsung Galaxy F15 5G');
        saveOperator(upgraded);
        return upgraded;
      }
      return op;
    } catch (e) {
      return OperatorProfile.defaultOperator;
    }
  }

  /// Save Operator Profile
  static Future<void> saveOperator(OperatorProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(operatorKey, jsonEncode(profile.toJson()));
  }

  /// Load all stored evidence records from persistent storage
  static Future<List<EvidenceRecord>> loadRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final rawJson = prefs.getString(recordsKey);
    if (rawJson == null) {
      return await initializeSeedLedger();
    }

    try {
      final List<dynamic> decoded = jsonDecode(rawJson);
      final records = decoded.map((e) => EvidenceRecord.fromJson(e as Map<String, dynamic>)).toList();
      if (records.isEmpty) {
        return await initializeSeedLedger();
      }
      return records;
    } catch (e) {
      debugPrint('Error decoding records: $e');
      return await initializeSeedLedger();
    }
  }

  /// Save full ledger list
  static Future<void> saveRecords(List<EvidenceRecord> records) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(records.map((r) => r.toJson()).toList());
    await prefs.setString(recordsKey, encoded);
  }

  /// Initialize seed ledger with authentic cryptographic blocks
  static Future<List<EvidenceRecord>> initializeSeedLedger() async {
    final operator = await getOperator();
    final seedRecords = <EvidenceRecord>[];
    String prevHash = CryptoService.genesisHash;

    final initialScenarios = [
      SampleGenerator.scenarios[0], // Marquis Heroin Positive
      SampleGenerator.scenarios[1], // Scott Cocaine Positive
      SampleGenerator.scenarios[4], // Marquis Negative
    ];

    for (int i = 0; i < initialScenarios.length; i++) {
      final sc = initialScenarios[i];
      final scene = SampleGenerator.generateScene(
        kitId: sc.kitId,
        reactionColor: sc.reactionColor,
        lighting: sc.lighting,
      );

      final imgSha256 = CryptoService.hashBase64Image(scene.base64Png);
      final gains = CalibrationGains(
        gainR: sc.lighting == 'warm_tungsten' ? 0.88 : 1.02,
        gainG: 1.0,
        gainB: sc.lighting == 'warm_tungsten' ? 1.25 : 0.98,
        lightingQuality: sc.lighting == 'dim' ? 55 : 98,
        lightingNotes: sc.lighting == 'warm_tungsten'
            ? 'Warm tungsten light corrected via 18% Gray patch'
            : 'Standard diffuse daylight D65',
        colorCast: sc.lighting == 'warm_tungsten' ? 'Warm / Tungsten' : 'Neutral D65',
      );

      final classification = ColorimetryService.classifyColorSample(
        sc.kitId,
        sc.reactionColor,
        gains.lightingQuality,
      );

      final ts = DateTime.now().subtract(Duration(hours: 4 - i * 2));
      final tsIso = ts.toIso8601String();
      final tsFormatted = '${ts.year}-${ts.month.toString().padLeft(2, '0')}-${ts.day.toString().padLeft(2, '0')} ${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}';

      // Temporary record draft to build canonical JSON
      final recordDraft = EvidenceRecord(
        id: 'REC-${ts.millisecondsSinceEpoch.toRadixString(36).toUpperCase()}-$i',
        caseNumber: sc.caseNumber,
        timestampIso: tsIso,
        timestampFormatted: tsFormatted,
        latitude: 37.7749 + i * 0.003,
        longitude: -122.4194 - i * 0.002,
        accuracyMeters: 3.8,
        address: '${850 + i * 15} Bryant St, District ${i + 1}, Metro Field Unit',
        operator: operator,
        kitId: sc.kitId,
        kitName: classification.kitName,
        kitBrand: 'NIK Public Safety Reagent System',
        lotNumber: 'LOT-2026-N${810 + i * 15}',
        expirationDate: '2028-12-31',
        calibration: gains,
        whitePatchColor: const Color(0xFFF2F2F6),
        grayPatchColor: const Color(0xFF808080),
        rawSampleColor: sc.reactionColor,
        calibratedSampleColor: sc.reactionColor,
        category: classification.category,
        label: classification.label,
        substance: classification.matchedOutcome?.substance ?? 'None Detected',
        confidence: classification.confidence,
        deltaE: classification.deltaE,
        sampleLab: classification.sampleLab,
        statutoryDisclaimer: classification.statutoryDisclaimer,
        imageSha256: imgSha256,
        previousRecordHash: prevHash,
        recordHash: '',
        digitalSeal: '',
        imageBase64: scene.base64Png,
      );

      final canonical = recordDraft.toCanonicalJson();
      final recordHash = CryptoService.sha256String(canonical);
      final digitalSeal = CryptoService.generateDigitalSeal(recordHash, operator.badge, tsIso);

      final sealedRecord = EvidenceRecord(
        id: recordDraft.id,
        caseNumber: recordDraft.caseNumber,
        timestampIso: recordDraft.timestampIso,
        timestampFormatted: recordDraft.timestampFormatted,
        latitude: recordDraft.latitude,
        longitude: recordDraft.longitude,
        accuracyMeters: recordDraft.accuracyMeters,
        address: recordDraft.address,
        operator: recordDraft.operator,
        kitId: recordDraft.kitId,
        kitName: recordDraft.kitName,
        kitBrand: recordDraft.kitBrand,
        lotNumber: recordDraft.lotNumber,
        expirationDate: recordDraft.expirationDate,
        calibration: recordDraft.calibration,
        whitePatchColor: recordDraft.whitePatchColor,
        grayPatchColor: recordDraft.grayPatchColor,
        rawSampleColor: recordDraft.rawSampleColor,
        calibratedSampleColor: recordDraft.calibratedSampleColor,
        category: recordDraft.category,
        label: recordDraft.label,
        substance: recordDraft.substance,
        confidence: recordDraft.confidence,
        deltaE: recordDraft.deltaE,
        sampleLab: recordDraft.sampleLab,
        statutoryDisclaimer: recordDraft.statutoryDisclaimer,
        imageSha256: recordDraft.imageSha256,
        previousRecordHash: recordDraft.previousRecordHash,
        recordHash: recordHash,
        digitalSeal: digitalSeal,
        imageBase64: recordDraft.imageBase64,
      );

      prevHash = recordHash;
      seedRecords.add(sealedRecord);
    }

    await saveRecords(seedRecords);
    return seedRecords;
  }

  /// Append a new sealed record to the blockchain ledger
  static Future<EvidenceRecord> appendRecord(EvidenceRecord newRecord) async {
    final records = await loadRecords();
    records.add(newRecord);
    await saveRecords(records);
    return newRecord;
  }

  /// Permanently delete an evidence record by ID
  static Future<void> deleteRecord(String recordId) async {
    final records = await loadRecords();
    records.removeWhere((r) => r.id == recordId);
    await saveRecords(records);
  }

  /// Reset ledger back to initial seed state
  static Future<List<EvidenceRecord>> resetLedger() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(recordsKey);
    return await initializeSeedLedger();
  }
}
