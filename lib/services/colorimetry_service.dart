import 'dart:math';
import 'package:flutter/material.dart';
import '../models/reagent_kit.dart';

class CalibrationGains {
  final double gainR;
  final double gainG;
  final double gainB;
  final int lightingQuality;
  final String lightingNotes;
  final String colorCast;

  const CalibrationGains({
    required this.gainR,
    required this.gainG,
    required this.gainB,
    required this.lightingQuality,
    required this.lightingNotes,
    required this.colorCast,
  });

  Map<String, dynamic> toJson() => {
        'gainR': double.parse(gainR.toStringAsFixed(4)),
        'gainG': double.parse(gainG.toStringAsFixed(4)),
        'gainB': double.parse(gainB.toStringAsFixed(4)),
        'lightingQuality': lightingQuality,
        'lightingNotes': lightingNotes,
        'colorCast': colorCast,
      };

  factory CalibrationGains.fromJson(Map<String, dynamic> json) =>
      CalibrationGains(
        gainR: (json['gainR'] as num?)?.toDouble() ?? 1.0,
        gainG: (json['gainG'] as num?)?.toDouble() ?? 1.0,
        gainB: (json['gainB'] as num?)?.toDouble() ?? 1.0,
        lightingQuality: (json['lightingQuality'] as num?)?.toInt() ?? 100,
        lightingNotes: json['lightingNotes'] as String? ?? 'Optimal',
        colorCast: json['colorCast'] as String? ?? 'Neutral D65',
      );
}

class ClassificationResult {
  final String kitId;
  final String kitName;
  final String category; // POSITIVE, NEGATIVE, INCONCLUSIVE
  final String label;
  final ReagentOutcome? matchedOutcome;
  final double deltaE;
  final double confidence;
  final LabColor sampleLab;
  final Color calibratedColor;
  final int lightingQuality;
  final String statutoryDisclaimer;

  const ClassificationResult({
    required this.kitId,
    required this.kitName,
    required this.category,
    required this.label,
    this.matchedOutcome,
    required this.deltaE,
    required this.confidence,
    required this.sampleLab,
    required this.calibratedColor,
    required this.lightingQuality,
    required this.statutoryDisclaimer,
  });

  Map<String, dynamic> toJson() => {
        'kitId': kitId,
        'kitName': kitName,
        'category': category,
        'label': label,
        'substance': matchedOutcome?.substance ?? 'None Detected',
        'confidence': double.parse(confidence.toStringAsFixed(1)),
        'deltaE': double.parse(deltaE.toStringAsFixed(2)),
        'sampleLab': sampleLab.toJson(),
        'calibratedHex': '#${calibratedColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
        'lightingQuality': lightingQuality,
        'statutoryDisclaimer': statutoryDisclaimer,
      };
}

class ColorimetryService {
  // D65 Standard Illuminant reference white point
  static const double refX = 95.047;
  static const double refY = 100.000;
  static const double refZ = 108.883;

  static double _srgbToLinear(int c) {
    final v = c / 255.0;
    return v <= 0.04045 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4).toDouble();
  }

  /// Convert sRGB [0-255] to CIE-XYZ [0-100]
  static List<double> rgbToXyz(int r, int g, int b) {
    final lr = _srgbToLinear(r);
    final lg = _srgbToLinear(g);
    final lb = _srgbToLinear(b);

    final x = (lr * 0.4124564 + lg * 0.3575761 + lb * 0.1804375) * 100.0;
    final y = (lr * 0.2126729 + lg * 0.7151522 + lb * 0.0721750) * 100.0;
    final z = (lr * 0.0193339 + lg * 0.1191920 + lb * 0.9503041) * 100.0;

    return [x, y, z];
  }

  /// Convert CIE-XYZ to CIE-L*a*b*
  static LabColor xyzToLab(double x, double y, double z) {
    final xr = x / refX;
    final yr = y / refY;
    final zr = z / refZ;

    double f(double t) => t > 0.008856 ? cbrt(t) : 7.787 * t + 16.0 / 116.0;

    final fx = f(xr);
    final fy = f(yr);
    final fz = f(zr);

    final l = (116.0 * fy - 16.0);
    final a = (500.0 * (fx - fy));
    final b = (200.0 * (fy - fz));

    return LabColor(
      L: double.parse(l.toStringAsFixed(2)),
      a: double.parse(a.toStringAsFixed(2)),
      b: double.parse(b.toStringAsFixed(2)),
    );
  }

  static double cbrt(double x) {
    if (x == 0.0) return 0.0;
    final res = pow(x.abs(), 1.0 / 3.0).toDouble();
    return x < 0 ? -res : res;
  }

  /// Convert sRGB direct to CIE-L*a*b*
  static LabColor rgbToLab(int r, int g, int b) {
    final xyz = rgbToXyz(r, g, b);
    return xyzToLab(xyz[0], xyz[1], xyz[2]);
  }

  /// Calculate CIE76 Delta-E perceptual color distance
  static double calculateDeltaE(LabColor lab1, LabColor lab2) {
    final dL = lab1.L - lab2.L;
    final da = lab1.a - lab2.a;
    final db = lab1.b - lab2.b;
    return sqrt(dL * dL + da * da + db * db);
  }

  /// Compute Chromatic Adaptation Gains from reference card patches
  static CalibrationGains computeCalibrationGains(Color sampledWhite, Color sampledGray) {
    double gainR = 1.0;
    double gainG = 1.0;
    double gainB = 1.0;

    // Use neutral 18% gray patch (ideal ~ 128)
    final grayR = sampledGray.r * 255.0;
    final grayG = sampledGray.g * 255.0;
    final grayB = sampledGray.b * 255.0;

    if (grayR > 15 && grayG > 15 && grayB > 15) {
      final avg = (grayR + grayG + grayB) / 3.0;
      gainR = avg / grayR;
      gainG = avg / grayG;
      gainB = avg / grayB;
    } else {
      final whiteR = sampledWhite.r * 255.0;
      final whiteG = sampledWhite.g * 255.0;
      final whiteB = sampledWhite.b * 255.0;
      final maxVal = max(whiteR, max(whiteG, whiteB));
      if (maxVal > 20) {
        gainR = maxVal / whiteR;
        gainG = maxVal / whiteG;
        gainB = maxVal / whiteB;
      }
    }

    // Lighting quality score
    int quality = 100;
    String notes = 'Optimal diffuse lighting';

    final avgGray = (grayR + grayG + grayB) / 3.0;
    final avgWhite = (sampledWhite.r * 255.0 + sampledWhite.g * 255.0 + sampledWhite.b * 255.0) / 3.0;

    if (avgGray < 40) {
      quality = 35;
      notes = 'Underexposed: Dim ambient illumination';
    } else if (avgGray < 70) {
      quality = 65;
      notes = 'Sub-optimal: Dim lighting, sensor chromatic noise';
    } else if (avgWhite > 252) {
      quality = 70;
      notes = 'Highlight specular reflection on card';
    }

    String cast = 'Neutral Daylight';
    if (gainB > gainR * 1.1) {
      cast = 'Warm / Tungsten Cast';
    } else if (gainR > gainB * 1.1) {
      cast = 'Cool Skylight / LED Cast';
    }

    return CalibrationGains(
      gainR: gainR,
      gainG: gainG,
      gainB: gainB,
      lightingQuality: quality,
      lightingNotes: notes,
      colorCast: cast,
    );
  }

  /// Apply chromatic calibration gains to raw color
  static Color applyCalibration(Color raw, CalibrationGains gains) {
    final r = ((raw.r * 255.0) * gains.gainR).clamp(0.0, 255.0).round();
    final g = ((raw.g * 255.0) * gains.gainG).clamp(0.0, 255.0).round();
    final b = ((raw.b * 255.0) * gains.gainB).clamp(0.0, 255.0).round();
    return Color.fromARGB(255, r, g, b);
  }

  /// Classify calibrated sample against selected reagent kit
  static ClassificationResult classifyColorSample(
    String kitId,
    Color calibratedColor,
    int lightingQuality,
  ) {
    final kit = ReagentKit.standardKits.firstWhere(
      (k) => k.id == kitId,
      orElse: () => ReagentKit.standardKits.first,
    );

    final r = (calibratedColor.r * 255.0).round();
    final g = (calibratedColor.g * 255.0).round();
    final b = (calibratedColor.b * 255.0).round();
    final sampleLab = rgbToLab(r, g, b);

    ReagentOutcome? bestMatch;
    double minDeltaE = double.infinity;

    for (final outcome in kit.outcomes) {
      final deltaE = calculateDeltaE(sampleLab, outcome.targetLab);
      if (deltaE < minDeltaE) {
        minDeltaE = deltaE;
        bestMatch = outcome;
      }
    }

    // Calculate match confidence percentage
    double confidence = (100.0 - minDeltaE * 2.2).clamp(0.0, 99.4);
    if (lightingQuality < 60) {
      confidence = max(25.0, confidence * (lightingQuality / 100.0));
    }

    String category = 'INCONCLUSIVE';
    String label = 'INCONCLUSIVE (Ambiguous Color Shift)';

    if (bestMatch != null && minDeltaE <= bestMatch.toleranceDeltaE && confidence >= 60.0) {
      category = bestMatch.category;
      label = bestMatch.label;
    } else {
      category = 'INCONCLUSIVE';
      label = 'INCONCLUSIVE (Spectral distance ΔE=${minDeltaE.toStringAsFixed(1)} exceeds threshold)';
    }

    return ClassificationResult(
      kitId: kit.id,
      kitName: kit.name,
      category: category,
      label: label,
      matchedOutcome: bestMatch,
      deltaE: double.parse(minDeltaE.toStringAsFixed(2)),
      confidence: double.parse(confidence.toStringAsFixed(1)),
      sampleLab: sampleLab,
      calibratedColor: calibratedColor,
      lightingQuality: lightingQuality,
      statutoryDisclaimer:
          'PRESUMPTIVE FIELD TEST ONLY: This result is a preliminary chemical indication and cannot replace laboratory confirmatory analysis (GC-MS / HPLC / LC-MS/MS). Not for standalone judicial determination without laboratory confirmation.',
    );
  }
}
