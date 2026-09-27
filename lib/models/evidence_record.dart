import 'dart:convert';
import 'package:flutter/material.dart';
import 'operator_profile.dart';
import 'reagent_kit.dart';
import '../services/colorimetry_service.dart';

class EvidenceRecord {
  final String id;
  final String caseNumber;
  final String timestampIso;
  final String timestampFormatted;
  final double latitude;
  final double longitude;
  final double accuracyMeters;
  final String address;
  final OperatorProfile operator;
  final String kitId;
  final String kitName;
  final String kitBrand;
  final String lotNumber;
  final String expirationDate;
  final CalibrationGains calibration;
  final Color whitePatchColor;
  final Color grayPatchColor;
  final Color rawSampleColor;
  final Color calibratedSampleColor;
  final String category; // POSITIVE, NEGATIVE, INCONCLUSIVE
  final String label;
  final String substance;
  final double confidence;
  final double deltaE;
  final LabColor sampleLab;
  final String statutoryDisclaimer;
  final String imageSha256;
  final String previousRecordHash;
  final String recordHash;
  final String digitalSeal;
  final String imageBase64;
  final bool isTamperedSimulation;

  EvidenceRecord({
    required this.id,
    required this.caseNumber,
    required this.timestampIso,
    required this.timestampFormatted,
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    required this.address,
    required this.operator,
    required this.kitId,
    required this.kitName,
    required this.kitBrand,
    required this.lotNumber,
    required this.expirationDate,
    required this.calibration,
    required this.whitePatchColor,
    required this.grayPatchColor,
    required this.rawSampleColor,
    required this.calibratedSampleColor,
    required this.category,
    required this.label,
    required this.substance,
    required this.confidence,
    required this.deltaE,
    required this.sampleLab,
    required this.statutoryDisclaimer,
    required this.imageSha256,
    required this.previousRecordHash,
    required this.recordHash,
    required this.digitalSeal,
    required this.imageBase64,
    this.isTamperedSimulation = false,
  });

  /// Deterministic canonical payload string used for SHA-256 block hashing
  String toCanonicalJson() {
    return jsonEncode({
      'caseNumber': caseNumber,
      'timestampIso': timestampIso,
      'location': {
        'lat': double.parse(latitude.toStringAsFixed(5)),
        'lng': double.parse(longitude.toStringAsFixed(5)),
        'acc': double.parse(accuracyMeters.toStringAsFixed(1)),
      },
      'operator': {
        'badge': operator.badge,
        'agency': operator.agency,
        'name': operator.name,
      },
      'kit': {
        'kitId': kitId,
        'lotNumber': lotNumber,
      },
      'classification': {
        'category': category,
        'label': label,
        'confidence': double.parse(confidence.toStringAsFixed(1)),
        'deltaE': double.parse(deltaE.toStringAsFixed(2)),
      },
      'imageSha256': imageSha256,
      'previousRecordHash': previousRecordHash,
    });
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'caseNumber': caseNumber,
        'timestampIso': timestampIso,
        'timestampFormatted': timestampFormatted,
        'latitude': latitude,
        'longitude': longitude,
        'accuracyMeters': accuracyMeters,
        'address': address,
        'operator': operator.toJson(),
        'kitId': kitId,
        'kitName': kitName,
        'kitBrand': kitBrand,
        'lotNumber': lotNumber,
        'expirationDate': expirationDate,
        'calibration': calibration.toJson(),
        'whitePatchColor': whitePatchColor.toARGB32(),
        'grayPatchColor': grayPatchColor.toARGB32(),
        'rawSampleColor': rawSampleColor.toARGB32(),
        'calibratedSampleColor': calibratedSampleColor.toARGB32(),
        'category': category,
        'label': label,
        'substance': substance,
        'confidence': confidence,
        'deltaE': deltaE,
        'sampleLab': sampleLab.toJson(),
        'statutoryDisclaimer': statutoryDisclaimer,
        'imageSha256': imageSha256,
        'previousRecordHash': previousRecordHash,
        'recordHash': recordHash,
        'digitalSeal': digitalSeal,
        'imageBase64': imageBase64,
        'isTamperedSimulation': isTamperedSimulation,
      };

  factory EvidenceRecord.fromJson(Map<String, dynamic> json) {
    return EvidenceRecord(
      id: json['id'] as String,
      caseNumber: json['caseNumber'] as String,
      timestampIso: json['timestampIso'] as String,
      timestampFormatted: json['timestampFormatted'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      accuracyMeters: (json['accuracyMeters'] as num).toDouble(),
      address: json['address'] as String,
      operator: OperatorProfile.fromJson(json['operator'] as Map<String, dynamic>),
      kitId: json['kitId'] as String,
      kitName: json['kitName'] as String,
      kitBrand: json['kitBrand'] as String,
      lotNumber: json['lotNumber'] as String,
      expirationDate: json['expirationDate'] as String,
      calibration: CalibrationGains.fromJson(json['calibration'] as Map<String, dynamic>),
      whitePatchColor: Color(json['whitePatchColor'] as int),
      grayPatchColor: Color(json['grayPatchColor'] as int),
      rawSampleColor: Color(json['rawSampleColor'] as int),
      calibratedSampleColor: Color(json['calibratedSampleColor'] as int),
      category: json['category'] as String,
      label: json['label'] as String,
      substance: json['substance'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      deltaE: (json['deltaE'] as num).toDouble(),
      sampleLab: LabColor.fromJson(json['sampleLab'] as Map<String, dynamic>),
      statutoryDisclaimer: json['statutoryDisclaimer'] as String,
      imageSha256: json['imageSha256'] as String,
      previousRecordHash: json['previousRecordHash'] as String,
      recordHash: json['recordHash'] as String,
      digitalSeal: json['digitalSeal'] as String,
      imageBase64: json['imageBase64'] as String,
      isTamperedSimulation: json['isTamperedSimulation'] as bool? ?? false,
    );
  }

  EvidenceRecord copyWith({
    String? category,
    String? label,
    bool? isTamperedSimulation,
  }) {
    return EvidenceRecord(
      id: id,
      caseNumber: caseNumber,
      timestampIso: timestampIso,
      timestampFormatted: timestampFormatted,
      latitude: latitude,
      longitude: longitude,
      accuracyMeters: accuracyMeters,
      address: address,
      operator: operator,
      kitId: kitId,
      kitName: kitName,
      kitBrand: kitBrand,
      lotNumber: lotNumber,
      expirationDate: expirationDate,
      calibration: calibration,
      whitePatchColor: whitePatchColor,
      grayPatchColor: grayPatchColor,
      rawSampleColor: rawSampleColor,
      calibratedSampleColor: calibratedSampleColor,
      category: category ?? this.category,
      label: label ?? this.label,
      substance: substance,
      confidence: confidence,
      deltaE: deltaE,
      sampleLab: sampleLab,
      statutoryDisclaimer: statutoryDisclaimer,
      imageSha256: imageSha256,
      previousRecordHash: previousRecordHash,
      recordHash: recordHash,
      digitalSeal: digitalSeal,
      imageBase64: imageBase64,
      isTamperedSimulation: isTamperedSimulation ?? this.isTamperedSimulation,
    );
  }
}
