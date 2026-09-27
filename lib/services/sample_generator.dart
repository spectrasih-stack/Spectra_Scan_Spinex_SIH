import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

class SampleScenario {
  final String id;
  final String name;
  final String description;
  final String kitId;
  final String scenarioType; // POSITIVE, NEGATIVE, INCONCLUSIVE
  final String substanceName;
  final String lighting; // 'normal', 'warm_tungsten', 'dim'
  final Color reactionColor;
  final String caseNumber;

  const SampleScenario({
    required this.id,
    required this.name,
    required this.description,
    required this.kitId,
    required this.scenarioType,
    required this.substanceName,
    required this.lighting,
    required this.reactionColor,
    required this.caseNumber,
  });
}

class GeneratedTestScene {
  final String base64Png;
  final Uint8List pngBytes;
  final int width;
  final int height;
  final Offset whitePatchPoint;
  final Offset grayPatchPoint;
  final Offset reactionChamberPoint;

  const GeneratedTestScene({
    required this.base64Png,
    required this.pngBytes,
    required this.width,
    required this.height,
    required this.whitePatchPoint,
    required this.grayPatchPoint,
    required this.reactionChamberPoint,
  });
}

class SampleGenerator {
  static final List<SampleScenario> scenarios = [
    SampleScenario(
      id: 'marquis_heroin_positive',
      name: 'Sample 1: Marquis - Heroin / Opiates Positive',
      description: 'NIK Test A. Evidence collected from traffic stop. Rapid violet-purple shift.',
      kitId: 'marquis',
      scenarioType: 'POSITIVE',
      substanceName: 'Heroin / Morphine',
      lighting: 'normal',
      reactionColor: const Color(0xFF58185F),
      caseNumber: 'CF-2026-84910',
    ),
    SampleScenario(
      id: 'scott_cocaine_positive',
      name: 'Sample 2: Scott Reagent - Cocaine HCl Positive',
      description: 'NIK Test G. Cobalt thiocyanate test on crystalline powder. Cobalt blue precipitate.',
      kitId: 'scott',
      scenarioType: 'POSITIVE',
      substanceName: 'Cocaine Hydrochloride',
      lighting: 'warm_tungsten',
      reactionColor: const Color(0xFF0863A5),
      caseNumber: 'CF-2026-84911',
    ),
    SampleScenario(
      id: 'duquenois_thc_positive',
      name: 'Sample 3: Duquenois-Levine - THC / Cannabinoid Positive',
      description: 'NIK Test E. Screening of concentrated resin. Violet-purple chloroform layer.',
      kitId: 'duquenois',
      scenarioType: 'POSITIVE',
      substanceName: 'Cannabinoids (THC)',
      lighting: 'normal',
      reactionColor: const Color(0xFF4C1055),
      caseNumber: 'CF-2026-84912',
    ),
    SampleScenario(
      id: 'marquis_meth_positive',
      name: 'Sample 4: Marquis - Methamphetamine Positive',
      description: 'NIK Test A. Rapid orange-brown shift on suspected crystal sample.',
      kitId: 'marquis',
      scenarioType: 'POSITIVE',
      substanceName: 'Methamphetamine',
      lighting: 'normal',
      reactionColor: const Color(0xFFB55315),
      caseNumber: 'CF-2026-84913',
    ),
    SampleScenario(
      id: 'marquis_blank_negative',
      name: 'Sample 5: Marquis - Negative / Excipient',
      description: 'NIK Test A on inert cutting agent. Reagent remains pale straw baseline.',
      kitId: 'marquis',
      scenarioType: 'NEGATIVE',
      substanceName: 'Negative / Non-reactive',
      lighting: 'normal',
      reactionColor: const Color(0xFFEAE5C8),
      caseNumber: 'CF-2026-84914',
    ),
    SampleScenario(
      id: 'marquis_dim_inconclusive',
      name: 'Sample 6: Marquis - Inconclusive (Dim / Ambiguous)',
      description: 'Sub-threshold color shift under degraded illumination.',
      kitId: 'marquis',
      scenarioType: 'INCONCLUSIVE',
      substanceName: 'Inconclusive Reaction',
      lighting: 'dim',
      reactionColor: const Color(0xFF696452),
      caseNumber: 'CF-2026-84915',
    ),
  ];

  /// Generate a realistic synthetic PNG test scene with in-frame reference card & test pouch
  static GeneratedTestScene generateScene({
    required String kitId,
    required Color reactionColor,
    String lighting = 'normal',
  }) {
    const width = 640;
    const height = 480;

    final image = img.Image(width: width, height: height);

    // Lighting tint factors
    double tintR = 1.0;
    double tintG = 1.0;
    double tintB = 1.0;

    if (lighting == 'warm_tungsten') {
      tintR = 1.18;
      tintG = 0.98;
      tintB = 0.74;
    } else if (lighting == 'dim') {
      tintR = 0.65;
      tintG = 0.65;
      tintB = 0.65;
    }

    img.Color c(int r, int g, int b, [int a = 255]) {
      final tr = (r * tintR).clamp(0, 255).round();
      final tg = (g * tintG).clamp(0, 255).round();
      final tb = (b * tintB).clamp(0, 255).round();
      return img.ColorRgba8(tr, tg, tb, a);
    }

    // 1. Fill background (tactical police worktable surface)
    final bgDark = c(22, 26, 34);
    final bgLight = c(32, 38, 48);
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final isGrid = (x % 32 == 0) || (y % 32 == 0);
        image.setPixel(x, y, isGrid ? bgLight : bgDark);
      }
    }

    // 2. Draw IN-FRAME FORENSIC REFERENCE CARD (Left Side)
    const cardX = 45;
    const cardY = 110;
    const cardW = 210;
    const cardH = 260;

    // Card background (Matte white forensic cardstock)
    img.fillRect(image,
        x1: cardX,
        y1: cardY,
        x2: cardX + cardW,
        y2: cardY + cardH,
        color: c(242, 242, 246));

    // Card border
    img.drawRect(image,
        x1: cardX,
        y1: cardY,
        x2: cardX + cardW,
        y2: cardY + cardH,
        color: c(160, 165, 175));

    // Standard Color Patches
    const patchSize = 50;

    // White Patch
    const pWhiteX = cardX + 18;
    const pWhiteY = cardY + 50;
    img.fillRect(image,
        x1: pWhiteX,
        y1: pWhiteY,
        x2: pWhiteX + patchSize,
        y2: pWhiteY + patchSize,
        color: c(255, 255, 255));
    img.drawRect(image,
        x1: pWhiteX,
        y1: pWhiteY,
        x2: pWhiteX + patchSize,
        y2: pWhiteY + patchSize,
        color: c(180, 180, 180));

    // 18% Neutral Gray Patch
    const pGrayX = cardX + 80;
    const pGrayY = cardY + 50;
    img.fillRect(image,
        x1: pGrayX,
        y1: pGrayY,
        x2: pGrayX + patchSize,
        y2: pGrayY + patchSize,
        color: c(128, 128, 128));
    img.drawRect(image,
        x1: pGrayX,
        y1: pGrayY,
        x2: pGrayX + patchSize,
        y2: pGrayY + patchSize,
        color: c(90, 90, 90));

    // Deep Black Patch
    const pBlackX = cardX + 142;
    const pBlackY = cardY + 50;
    img.fillRect(image,
        x1: pBlackX,
        y1: pBlackY,
        x2: pBlackX + patchSize,
        y2: pBlackY + patchSize,
        color: c(18, 18, 18));

    // Secondary CMY/RGB strip
    final stripColors = [
      [220, 30, 30],
      [30, 180, 50],
      [30, 80, 220],
      [220, 200, 30],
      [20, 190, 210],
    ];
    for (int i = 0; i < stripColors.length; i++) {
      final sc = stripColors[i];
      img.fillRect(image,
          x1: cardX + 40 + i * 26,
          y1: cardY + 180,
          x2: cardX + 40 + i * 26 + 20,
          y2: cardY + 180 + 20,
          color: c(sc[0], sc[1], sc[2]));
    }

    // 3. Draw TEST REAGENT POUCH / VIAL (Right Side)
    const pouchX = 330;
    const pouchY = 75;
    const pouchW = 250;
    const pouchH = 330;

    // Pouch outer plastic
    img.fillRect(image,
        x1: pouchX,
        y1: pouchY,
        x2: pouchX + pouchW,
        y2: pouchY + pouchH,
        color: c(40, 50, 65, 180));
    img.drawRect(image,
        x1: pouchX,
        y1: pouchY,
        x2: pouchX + pouchW,
        y2: pouchY + pouchH,
        color: c(200, 210, 225));

    // Pouch top crimp
    img.fillRect(image,
        x1: pouchX + 12,
        y1: pouchY + 10,
        x2: pouchX + pouchW - 12,
        y2: pouchY + 38,
        color: c(15, 23, 42));

    // Inner glass ampoule
    const ampouleX = pouchX + 70;
    const ampouleY = pouchY + 100;
    const ampouleW = 110;
    const ampouleH = 190;

    img.fillRect(image,
        x1: ampouleX,
        y1: ampouleY,
        x2: ampouleX + ampouleW,
        y2: ampouleY + ampouleH,
        color: c(60, 75, 95, 160));
    img.drawRect(image,
        x1: ampouleX,
        y1: ampouleY,
        x2: ampouleX + ampouleW,
        y2: ampouleY + ampouleH,
        color: c(220, 230, 245));

    // Liquid Reaction Chamber (Bottom 60% of ampoule)
    const liquidY = ampouleY + 70;
    const liquidH = ampouleH - 70;

    final baseR = (reactionColor.r * 255.0).round();
    final baseG = (reactionColor.g * 255.0).round();
    final baseB = (reactionColor.b * 255.0).round();

    img.fillRect(image,
        x1: ampouleX + 3,
        y1: liquidY,
        x2: ampouleX + ampouleW - 3,
        y2: ampouleY + ampouleH - 3,
        color: c(baseR, baseG, baseB));

    // Liquid meniscus reflection line
    img.drawLine(image,
        x1: ampouleX + 4,
        y1: liquidY,
        x2: ampouleX + ampouleW - 4,
        y2: liquidY,
        color: c(255, 255, 255, 200));

    // Glass specular vertical glare reflection
    img.fillRect(image,
        x1: ampouleX + 12,
        y1: ampouleY + 15,
        x2: ampouleX + 18,
        y2: ampouleY + ampouleH - 25,
        color: c(255, 255, 255, 80));

    // Encode to PNG bytes and Base64 string
    final pngBytes = Uint8List.fromList(img.encodePng(image));
    final base64String = base64Encode(pngBytes);

    return GeneratedTestScene(
      base64Png: base64String,
      pngBytes: pngBytes,
      width: width,
      height: height,
      whitePatchPoint: const Offset(pWhiteX + patchSize / 2, pWhiteY + patchSize / 2),
      grayPatchPoint: const Offset(pGrayX + patchSize / 2, pGrayY + patchSize / 2),
      reactionChamberPoint: Offset(ampouleX + ampouleW / 2, liquidY + liquidH / 2),
    );
  }
}
